const jwt = require('jsonwebtoken');
const PDFDocument = require('pdfkit');
const XLSX = require('xlsx');
const Corporate = require('../models/Corporate');
const LogisticsBooking = require('../models/LogisticsBooking');
const admin = require('../config/firebase');

const parseCsvLine = (line) => {
    const values = [];
    let current = '';
    let quoted = false;

    for (const char of line) {
        if (char === '"') {
            quoted = !quoted;
        } else if (char === ',' && !quoted) {
            values.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }

    values.push(current.trim());
    return values;
};

const parseBulkPayload = (req) => {
    if (Array.isArray(req.body.bookings)) return req.body.bookings;

    if (typeof req.body.bookings === 'string') {
        const parsed = JSON.parse(req.body.bookings);
        if (Array.isArray(parsed)) return parsed;
    }

    if (req.file && /excel|spreadsheet|xlsx/i.test(req.file.mimetype || req.file.originalname || '')) {
        const workbook = XLSX.read(req.file.buffer, { type: 'buffer' });
        return XLSX.utils.sheet_to_json(workbook.Sheets[workbook.SheetNames[0]]);
    }

    const csvText = req.file?.buffer?.toString('utf8') || req.body.csv;
    if (!csvText) return [];

    const lines = csvText.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
    if (lines.length < 2) return [];

    const headers = parseCsvLine(lines[0]).map((header) => header.trim());
    return lines.slice(1).map((line) => {
        const row = parseCsvLine(line);
        return headers.reduce((booking, header, index) => {
            booking[header] = row[index] || '';
            return booking;
        }, {});
    });
};

const toLocation = (address, lat, lng) => ({
    name: address || 'Location',
    address: address || 'Location',
    lat: Number(lat || 0),
    lng: Number(lng || 0),
});

const normalizeBulkBooking = (raw, corporate) => {
    const pickup = raw.pickup || toLocation(raw.pickupAddress || raw.pickup_address, raw.pickupLat, raw.pickupLng);
    const dropoff = raw.dropoff || toLocation(raw.dropoffAddress || raw.dropAddress || raw.dropoff_address || raw.deliveryAddress, raw.dropoffLat || raw.dropLat, raw.dropoffLng || raw.dropLng);
    const itemName = raw.itemName || raw.goodsType || raw.goods_type || 'General Goods';
    const totalPrice = Number(raw.totalPrice || raw.price || raw.estimatedPrice || 0);

    return {
        userId: corporate._id.toString(),
        userName: raw.userName || raw.customerName || corporate.companyName,
        userPhone: raw.userPhone || raw.customerPhone || corporate.contactPhone,
        pickup,
        dropoff,
        distanceKm: Number(raw.distanceKm || 0),
        vehicleType: raw.vehicleType || raw.modeOfTravel || 'Road',
        vehiclePrice: Number(raw.vehiclePrice || totalPrice || 0),
        items: Array.isArray(raw.items) && raw.items.length > 0 ? raw.items : [{
            itemName,
            type: raw.type || 'General',
            length: Number(raw.length || 1),
            height: Number(raw.height || 1),
            width: Number(raw.width || 1),
            unit: raw.unit || 'cm',
        }],
        helperCount: Number(raw.helperCount || 0),
        helperCost: Number(raw.helperCost || 0),
        additionalCharges: Number(raw.additionalCharges || 0),
        discountAmount: Number(raw.discountAmount || 0),
        totalPrice,
        pickupAddress: raw.pickupAddress ? { type: 'pickup', fullAddress: raw.pickupAddress } : null,
        receivedAddress: (raw.dropoffAddress || raw.dropAddress || raw.deliveryAddress) ? { type: 'received', fullAddress: raw.dropoffAddress || raw.dropAddress || raw.deliveryAddress } : null,
        status: 'pending',
    };
};

const createToken = (corporate) => jwt.sign(
    {
        id: corporate._id.toString(),
        email: corporate.email,
        role: corporate.role || 'corporate',
        companyName: corporate.companyName,
    },
    process.env.JWT_SECRET || 'your_secret_key',
    { expiresIn: '7d' }
);

const ensureDemoCorporate = async (email, password) => {
    const demoEmail = process.env.CORPORATE_DEMO_EMAIL || 'demo@transglobe.com';
    const demoPassword = process.env.CORPORATE_DEMO_PASSWORD || 'demo1234';

    if (
        process.env.NODE_ENV === 'production' ||
        email.toLowerCase() !== demoEmail.toLowerCase() ||
        password !== demoPassword
    ) {
        return null;
    }

    let corporate = await Corporate.findOne({ email: demoEmail.toLowerCase() });
    if (corporate) return corporate;

    corporate = await Corporate.create({
        companyName: 'Transglobe Demo Corporate',
        gstin: '22AAAAA0000A1Z5',
        email: demoEmail.toLowerCase(),
        contactPhone: '9999999999',
        address: 'Demo Corporate Address',
        password: demoPassword,
        role: 'corporate',
    });

    return corporate;
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password are required.' });
        }

        let corporate = await Corporate.findOne({ email: email.toLowerCase().trim() });
        if (!corporate) {
            corporate = await ensureDemoCorporate(email.trim(), password);
        }

        if (!corporate) {
            return res.status(401).json({ success: false, message: 'Invalid corporate credentials.' });
        }

        const isMatch = await corporate.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Invalid corporate credentials.' });
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                email: corporate.email,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                status: corporate.status,
                creditLimit: corporate.creditLimit,
                currentBalance: corporate.currentBalance,
                role: corporate.role,
            },
        });
    } catch (error) {
        console.error('Corporate login error:', error);
        return res.status(500).json({ success: false, message: 'Failed to log in corporate account.' });
    }
};

// Google Sign-In sync for corporate panel
exports.googleSync = async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'No token provided.' });
        }
        const idToken = authHeader.split(' ')[1];
        const decoded = await admin.auth().verifyIdToken(idToken);
        const { email, name, uid } = decoded;

        if (!email) return res.status(400).json({ success: false, message: 'Email not found in Google account.' });

        let corporate = await Corporate.findOne({ email: email.toLowerCase() });
        if (!corporate) {
            return res.status(404).json({
                success: false,
                message: 'No corporate account found for this Google email. Please contact admin.',
            });
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                email: corporate.email,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                status: corporate.status,
                role: corporate.role,
            },
        });
    } catch (error) {
        console.error('Corporate Google sync error:', error);
        return res.status(401).json({ success: false, message: 'Invalid or expired Google token.' });
    }
};

exports.getProfile = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id).select('-password');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        return res.status(200).json({ success: true, corporate });
    } catch (error) {
        console.error('Corporate profile error:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch corporate profile.' });
    }
};

exports.getBookings = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id).select('companyName email');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        const bookings = await LogisticsBooking.find({
            $or: [
                { userId: corporate._id.toString() },
                { userName: corporate.companyName },
            ],
        }).sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            data: bookings,
        });
    } catch (error) {
        console.error('Corporate bookings error:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch corporate bookings.' });
    }
};

exports.bulkCreateBookings = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id);
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        const requestedBookings = parseBulkPayload(req);
        if (!requestedBookings.length) {
            return res.status(400).json({ success: false, message: 'Upload CSV or send bookings array.' });
        }

        if (requestedBookings.length > 500) {
            return res.status(400).json({ success: false, message: 'Maximum 500 bookings are allowed per bulk upload.' });
        }

        const normalizedBookings = requestedBookings.map((booking) => normalizeBulkBooking(booking, corporate));
        const totalAmount = normalizedBookings.reduce((sum, booking) => sum + Number(booking.totalPrice || 0), 0);
        const availableCredit = Number(corporate.creditLimit || 0) - Number(corporate.currentBalance || 0);

        if (corporate.creditLimit > 0 && totalAmount > availableCredit) {
            return res.status(402).json({
                success: false,
                message: 'Corporate credit limit exceeded.',
                data: { totalAmount, availableCredit, creditLimit: corporate.creditLimit, currentBalance: corporate.currentBalance },
            });
        }

        const bookings = await LogisticsBooking.insertMany(normalizedBookings, { ordered: false });
        corporate.currentBalance = Number(corporate.currentBalance || 0) + totalAmount;
        await corporate.save();

        return res.status(201).json({
            success: true,
            message: `${bookings.length} bookings created successfully.`,
            data: bookings,
            billing: {
                totalAmount,
                creditLimit: corporate.creditLimit,
                currentBalance: corporate.currentBalance,
            },
        });
    } catch (error) {
        console.error('Corporate bulk booking error:', error);
        return res.status(500).json({ success: false, message: 'Failed to create bulk bookings.', error: error.message });
    }
};

exports.getCredit = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id).select('companyName creditLimit currentBalance status');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        return res.status(200).json({
            success: true,
            data: {
                creditLimit: corporate.creditLimit,
                currentBalance: corporate.currentBalance,
                availableCredit: Number(corporate.creditLimit || 0) - Number(corporate.currentBalance || 0),
                status: corporate.status,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateCredit = async (req, res) => {
    try {
        const corporateId = req.params.id || req.user.id;
        const { creditLimit, currentBalance, status } = req.body;

        if (!['admin', 'superadmin'].includes(String(req.user.role || '').toLowerCase()) && corporateId !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Admin access required to update another corporate account.' });
        }

        const update = {};
        if (creditLimit !== undefined) update.creditLimit = Number(creditLimit);
        if (currentBalance !== undefined) update.currentBalance = Number(currentBalance);
        if (status !== undefined) update.status = status;

        const corporate = await Corporate.findByIdAndUpdate(corporateId, update, { new: true }).select('-password');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        return res.status(200).json({ success: true, data: corporate });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.downloadBulkTemplate = async (_req, res) => {
    const headers = [
        'pickupAddress', 'pickupLat', 'pickupLng', 'pickupContact', 'pickupPhone',
        'dropAddress', 'dropLat', 'dropLng', 'dropContact', 'dropPhone',
        'goodsType', 'weight', 'length', 'width', 'height', 'quantity',
        'vehicleType', 'pickupDate', 'pickupTimeWindow', 'deliveryUrgency',
        'costCenter', 'poNumber', 'department',
    ];
    const example = [
        'Noida Sector 62', '28.627', '77.371', 'Amit', '9999999999',
        'Connaught Place', '28.633', '77.220', 'Priya', '8888888888',
        'Electronics', '45', '40', '30', '20', '2',
        'Road', '2026-05-10', '10:00-12:00', 'express',
        'DEL-NCR', 'PO-1001', 'Operations',
    ];
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=transglobe_bulk_booking_template.csv');
    return res.send(`${headers.join(',')}\n${example.join(',')}\n`);
};

exports.generateInvoice = async (req, res) => {
    try {
        const booking = await LogisticsBooking.findById(req.params.bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });

        const doc = new PDFDocument({ margin: 50 });
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename=invoice_${booking._id}.pdf`);
        doc.pipe(res);

        const subtotal = Number(booking.vehiclePrice || booking.totalPrice || 0) + Number(booking.helperCost || 0) + Number(booking.additionalCharges || 0);
        const gst = Math.round(subtotal * 0.18);
        const total = subtotal + gst - Number(booking.discountAmount || 0);

        doc.fontSize(20).text('TRANSGLOBES LOGISTICS', { align: 'center' });
        doc.fontSize(10).text(`GSTIN: ${process.env.COMPANY_GST || 'GSTIN-PENDING'}`, { align: 'center' });
        doc.moveDown();
        doc.fontSize(14).text('TAX INVOICE', { underline: true });
        doc.fontSize(10)
            .text(`Invoice No: TG-INV-${booking._id.toString().slice(-8).toUpperCase()}`)
            .text(`Date: ${new Date().toLocaleDateString('en-IN')}`)
            .text(`Booking ID: ${booking._id}`)
            .moveDown()
            .text(`Bill To: ${booking.userName || 'Customer'}`)
            .text(`Phone: ${booking.userPhone || 'N/A'}`)
            .moveDown()
            .text(`Pickup: ${booking.pickup?.address || booking.pickupAddress?.fullAddress || 'N/A'}`)
            .text(`Drop: ${booking.dropoff?.address || booking.receivedAddress?.fullAddress || 'N/A'}`)
            .text(`Goods: ${(booking.items || []).map((item) => item.itemName).join(', ') || 'General Goods'}`)
            .moveDown()
            .text(`Subtotal: INR ${subtotal}`)
            .text(`GST 18%: INR ${gst}`)
            .text(`Discount: INR ${booking.discountAmount || 0}`)
            .fontSize(12).text(`Total: INR ${total}`, { underline: true });
        doc.end();
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getCreditStatus = async (req, res) => {
    try {
        const corporate = await Corporate.findById(req.user.id);
        if (!corporate) return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        const creditLimit = Number(corporate.creditLimit || 0);
        const usedCredit = Number(corporate.currentBalance || 0);
        const usagePercent = creditLimit ? Math.round((usedCredit / creditLimit) * 100) : 0;
        const nextDue = new Date(Date.now() + Number(corporate.paymentTermsDays || 30) * 24 * 60 * 60 * 1000);
        return res.json({
            success: true,
            creditLimit,
            usedCredit,
            availableCredit: creditLimit - usedCredit,
            usagePercent,
            paymentTermsDays: corporate.paymentTermsDays || 30,
            nextDueDate: nextDue.toISOString().split('T')[0],
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.dashboard = async (req, res) => {
    try {
        const corporate = await Corporate.findById(req.user.id);
        if (!corporate) return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        const bookings = await LogisticsBooking.find({ userId: corporate._id.toString() });
        const now = new Date();
        const today = now.toISOString().split('T')[0];
        const activeShipments = bookings.filter((b) => ['pending', 'claimed', 'processing', 'confirmed', 'in_transit'].includes(b.status)).length;
        const inTransit = bookings.filter((b) => b.status === 'in_transit').length;
        const deliveredToday = bookings.filter((b) => b.status === 'delivered' && b.updatedAt?.toISOString().startsWith(today)).length;
        const pendingPickups = bookings.filter((b) => ['pending', 'claimed'].includes(b.status)).length;
        const totalSpendThisMonth = bookings
            .filter((b) => b.createdAt && b.createdAt.getMonth() === now.getMonth() && b.createdAt.getFullYear() === now.getFullYear())
            .reduce((sum, b) => sum + Number(b.totalPrice || 0), 0);
        const delivered = bookings.filter((b) => b.status === 'delivered').length;
        return res.json({
            success: true,
            activeShipments,
            inTransit,
            deliveredToday,
            pendingPickups,
            totalSpendThisMonth,
            avgCostPerShipment: bookings.length ? Math.round(totalSpendThisMonth / bookings.length) : 0,
            onTimeDeliveryRate: bookings.length ? Math.round((delivered / bookings.length) * 1000) / 10 : 0,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
