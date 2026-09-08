const crypto = require('crypto');
const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');
const LogisticsBooking = require('../models/LogisticsBooking');
const User = require('../models/User');
const Driver = require('../models/Driver');

const isObjectId = (value) => mongoose.Types.ObjectId.isValid(String(value || ''));

const getRazorpay = () => {
    const Razorpay = require('razorpay');
    return new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
};

const findUser = async (id) => {
    if (!id) return null;
    const query = [{ uid: id }, { mobileNumber: id }, { email: id }];
    if (isObjectId(id)) query.push({ _id: id });
    return User.findOne({ $or: query });
};

const findDriver = async (id) => {
    if (!id) return null;
    const query = [{ uid: id }, { firebaseId: id }, { email: id }, { mobileNumber: id }];
    if (isObjectId(id)) query.push({ _id: id });
    return Driver.findOne({ $or: query });
};

const getActor = async ({ userId, driverId, req }) => {
    const tokenUser = req.user || {};
    const resolvedUserId = userId || (tokenUser.role !== 'driver' ? tokenUser.uid || tokenUser.id : null);
    const resolvedDriverId = driverId || (tokenUser.role === 'driver' ? tokenUser.uid || tokenUser.id : null);

    if (resolvedDriverId) {
        const driver = await findDriver(resolvedDriverId);
        if (driver) return { entity: driver, entityType: 'driver', driverId: driver._id };
    }

    if (resolvedUserId) {
        const user = await findUser(resolvedUserId);
        if (user) return { entity: user, entityType: 'user', userId: user._id };
    }

    return { entity: null, entityType: null };
};

const calculateSplit = (amount) => {
    const driverCommission = Number(process.env.DRIVER_COMMISSION_RATE || 0.8);
    const driverEarnings = Math.round(Number(amount || 0) * driverCommission);
    return {
        driverEarnings,
        adminCommission: Number(amount || 0) - driverEarnings,
    };
};

exports.createOrder = async (req, res) => {
    try {
        const { bookingId, amount, currency = 'INR', bookingType = 'logistics', method = 'upi' } = req.body;

        if (!bookingId || !amount || Number(amount) <= 0) {
            return res.status(400).json({ success: false, message: 'bookingId and a positive amount are required.' });
        }

        if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
            return res.status(503).json({
                success: false,
                message: 'Payment gateway not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.',
            });
        }

        const razorpay = getRazorpay();
        const order = await razorpay.orders.create({
            amount: Math.round(Number(amount) * 100),
            currency,
            receipt: `tg_${String(bookingId).slice(-20)}_${Date.now()}`,
            notes: { bookingId, bookingType },
        });

        await Transaction.create({
            bookingId: isObjectId(bookingId) ? bookingId : undefined,
            amount: Number(amount),
            type: 'payment',
            method,
            status: 'pending',
            metadata: {
                gateway: 'razorpay',
                razorpayOrderId: order.id,
                bookingId,
                bookingType,
            },
        });

        return res.status(200).json({
            success: true,
            data: {
                orderId: order.id,
                amount: order.amount,
                currency: order.currency,
                keyId: process.env.RAZORPAY_KEY_ID,
            },
        });
    } catch (error) {
        console.error('[PAYMENT] Create order error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.initiatePayment = exports.createOrder;

exports.verifyPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature,
            bookingId,
            driverId,
        } = req.body;

        if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
            return res.status(400).json({ success: false, message: 'Razorpay order id, payment id, and signature are required.' });
        }

        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
            .update(`${razorpay_order_id}|${razorpay_payment_id}`)
            .digest('hex');

        if (expectedSignature !== razorpay_signature) {
            return res.status(400).json({ success: false, message: 'Payment signature verification failed.' });
        }

        const transaction = await Transaction.findOne({
            $or: [
                { 'metadata.razorpayOrderId': razorpay_order_id },
                { 'metadata.razorpay_order_id': razorpay_order_id },
            ],
        });
        const booking = bookingId && isObjectId(bookingId) ? await LogisticsBooking.findById(bookingId) : null;
        const totalAmount = booking?.totalPrice || transaction?.amount || 0;
        const split = calculateSplit(totalAmount);

        await Transaction.findOneAndUpdate(
            transaction ? { _id: transaction._id } : { 'metadata.razorpayOrderId': razorpay_order_id },
            {
                bookingId: booking?._id,
                amount: totalAmount,
                type: 'payment',
                method: transaction?.method || 'upi',
                status: 'completed',
                ...split,
                metadata: {
                    ...(transaction?.metadata || {}),
                    razorpay_order_id,
                    razorpay_payment_id,
                    verifiedAt: new Date(),
                },
            },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        if (driverId) {
            const driver = await findDriver(driverId);
            if (driver) {
                driver.walletBalance = Number(driver.walletBalance || 0) + split.driverEarnings;
                await driver.save();
            }
        }

        if (booking) {
            booking.status = 'confirmed';
            await booking.save();
        }

        return res.status(200).json({
            success: true,
            message: 'Payment verified and recorded.',
            data: split,
        });
    } catch (error) {
        console.error('[PAYMENT] Verify error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.gatewayCallback = async (req, res) => {
    try {
        const signature = req.headers['x-razorpay-signature'];
        const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

        if (webhookSecret && signature) {
            const expected = crypto
                .createHmac('sha256', webhookSecret)
                .update(JSON.stringify(req.body))
                .digest('hex');
            if (expected !== signature) {
                return res.status(400).json({ success: false, message: 'Invalid webhook signature.' });
            }
        }

        const event = req.body?.event;
        const payment = req.body?.payload?.payment?.entity;
        const orderId = payment?.order_id;

        if (!orderId) {
            return res.status(200).json({ success: true, message: 'Webhook ignored: no order id.' });
        }

        const status = event === 'payment.failed' ? 'failed' : 'completed';
        await Transaction.findOneAndUpdate(
            { 'metadata.razorpayOrderId': orderId },
            {
                status,
                metadata: {
                    gateway: 'razorpay',
                    razorpayOrderId: orderId,
                    razorpayPaymentId: payment?.id,
                    webhookEvent: event,
                    webhookAt: new Date(),
                },
            },
            { new: true }
        );

        return res.status(200).json({ success: true, message: 'Webhook processed.' });
    } catch (error) {
        console.error('[PAYMENT] Webhook error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.refundPayment = async (req, res) => {
    try {
        const { bookingId, transactionId, amount, reason = 'customer_refund' } = req.body;

        if (!bookingId && !transactionId) {
            return res.status(400).json({ success: false, message: 'bookingId or transactionId is required.' });
        }

        if (transactionId && !isObjectId(transactionId)) {
            return res.status(400).json({ success: false, message: 'Invalid transactionId.' });
        }

        if (!transactionId && !isObjectId(bookingId)) {
            return res.status(400).json({ success: false, message: 'Invalid bookingId.' });
        }

        const query = transactionId
            ? { _id: transactionId }
            : { bookingId, status: 'completed' };

        const transaction = await Transaction.findOne(query).sort({ createdAt: -1 });
        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Completed transaction not found.' });
        }

        const refundAmount = Number(amount || transaction.amount || 0);
        if (refundAmount <= 0 || refundAmount > transaction.amount) {
            return res.status(400).json({ success: false, message: 'Invalid refund amount.' });
        }

        let gatewayRefund = null;
        const paymentId = transaction.metadata?.razorpay_payment_id || transaction.metadata?.razorpayPaymentId;
        if (paymentId && process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
            const razorpay = getRazorpay();
            gatewayRefund = await razorpay.payments.refund(paymentId, {
                amount: Math.round(refundAmount * 100),
                notes: { bookingId: String(bookingId || transaction.bookingId || ''), reason },
            });
        }

        transaction.status = refundAmount === transaction.amount ? 'refunded' : transaction.status;
        transaction.metadata = {
            ...(transaction.metadata || {}),
            refundAmount,
            refundReason: reason,
            gatewayRefundId: gatewayRefund?.id,
            refundedAt: new Date(),
        };
        await transaction.save();

        if (transaction.bookingId) {
            await LogisticsBooking.findByIdAndUpdate(transaction.bookingId, { status: 'cancelled' });
        }

        await Transaction.create({
            userId: transaction.userId,
            driverId: transaction.driverId,
            bookingId: transaction.bookingId,
            amount: refundAmount,
            type: 'refund',
            method: transaction.method,
            status: 'completed',
            metadata: { sourceTransactionId: transaction._id, reason, gatewayRefund },
        });

        return res.status(200).json({
            success: true,
            message: gatewayRefund ? 'Refund initiated with gateway.' : 'Refund recorded. Gateway refund was skipped because payment id/keys are unavailable.',
            data: { refundAmount, gatewayRefund },
        });
    } catch (error) {
        console.error('[PAYMENT] Refund error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.walletAdd = async (req, res) => {
    try {
        const { userId, driverId, amount, method = 'upi' } = req.body;
        if (!amount || Number(amount) <= 0) {
            return res.status(400).json({ success: false, message: 'Invalid amount.' });
        }

        const actor = await getActor({ userId, driverId, req });
        if (!actor.entity) {
            return res.status(404).json({ success: false, message: 'User/Driver not found.' });
        }

        actor.entity.walletBalance = Number(actor.entity.walletBalance || 0) + Number(amount);
        await actor.entity.save();

        await Transaction.create({
            userId: actor.userId,
            driverId: actor.driverId,
            amount: Number(amount),
            type: 'payment',
            method,
            status: 'completed',
            metadata: { walletOperation: 'credit' },
        });

        return res.status(200).json({
            success: true,
            message: `Amount added to ${actor.entityType} wallet.`,
            newBalance: actor.entity.walletBalance,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.walletDeduct = async (req, res) => {
    try {
        const { userId, driverId, amount, bookingId } = req.body;
        if (!amount || Number(amount) <= 0) {
            return res.status(400).json({ success: false, message: 'Invalid amount.' });
        }

        const actor = await getActor({ userId, driverId, req });
        if (!actor.entity) {
            return res.status(404).json({ success: false, message: 'User/Driver not found.' });
        }

        if (Number(actor.entity.walletBalance || 0) < Number(amount)) {
            return res.status(400).json({ success: false, message: 'Insufficient wallet balance.' });
        }

        actor.entity.walletBalance = Number(actor.entity.walletBalance || 0) - Number(amount);
        await actor.entity.save();

        await Transaction.create({
            userId: actor.userId,
            driverId: actor.driverId,
            bookingId: bookingId && isObjectId(bookingId) ? bookingId : undefined,
            amount: Number(amount),
            type: 'payment',
            method: 'wallet',
            status: 'completed',
            metadata: { walletOperation: 'debit', bookingId },
        });

        return res.status(200).json({
            success: true,
            message: 'Amount deducted from wallet.',
            newBalance: actor.entity.walletBalance,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getWalletBalance = async (req, res) => {
    try {
        const actor = await getActor({
            userId: req.query.userId,
            driverId: req.query.driverId,
            req,
        });

        if (!actor.entity) {
            return res.status(404).json({ success: false, message: 'User/Driver not found.' });
        }

        return res.status(200).json({
            success: true,
            balance: Number(actor.entity.walletBalance || 0),
            entityType: actor.entityType,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getWalletHistory = async (req, res) => {
    try {
        const actor = await getActor({
            userId: req.query.userId,
            driverId: req.query.driverId,
            req,
        });

        if (!actor.entity) {
            return res.status(404).json({ success: false, message: 'User/Driver not found.' });
        }

        const filter = actor.entityType === 'driver'
            ? { driverId: actor.entity._id }
            : { userId: actor.entity._id };

        const page = Math.max(Number(req.query.page || 1), 1);
        const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 100);
        const [transactions, total] = await Promise.all([
            Transaction.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
            Transaction.countDocuments(filter),
        ]);

        return res.status(200).json({ success: true, data: transactions, pagination: { page, limit, total } });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getDriverEarnings = async (req, res) => {
    try {
        const { driverId } = req.params;
        const driver = await findDriver(driverId);
        if (!driver) return res.status(404).json({ success: false, message: 'Driver not found.' });

        const History = require('../models/History');
        const now = new Date();
        const todayStart = new Date(now);
        todayStart.setHours(0, 0, 0, 0);
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        const completedStatuses = ['completed', 'delivered'];

        const getRideEarning = (ride) =>
            Number(ride.actualFare ?? ride.fare ?? ride.totalPrice ?? 0);

        const rideFilter = (since) => {
            const filter = {
                driverId: driver._id,
                status: { $in: completedStatuses },
            };
            if (since) filter.updatedAt = { $gte: since };
            return filter;
        };

        const [
            todayCabs,
            todayLogistics,
            weekCabs,
            weekLogistics,
            monthCabs,
            monthLogistics,
            allCabs,
            allLogistics,
            recentCabs,
            recentLogistics,
        ] = await Promise.all([
            History.find(rideFilter(todayStart)).lean(),
            LogisticsBooking.find(rideFilter(todayStart)).lean(),
            History.find(rideFilter(weekAgo)).lean(),
            LogisticsBooking.find(rideFilter(weekAgo)).lean(),
            History.find(rideFilter(monthAgo)).lean(),
            LogisticsBooking.find(rideFilter(monthAgo)).lean(),
            History.find(rideFilter(null)).lean(),
            LogisticsBooking.find(rideFilter(null)).lean(),
            History.find(rideFilter(null))
                .sort({ updatedAt: -1 })
                .limit(15)
                .populate('userId', 'name')
                .lean(),
            LogisticsBooking.find(rideFilter(null))
                .sort({ updatedAt: -1 })
                .limit(15)
                .lean(),
        ]);

        const sumRides = (cabs, logistics) =>
            [...cabs, ...logistics].reduce((acc, ride) => acc + getRideEarning(ride), 0);

        const todayEarnings = sumRides(todayCabs, todayLogistics);
        const weeklyEarnings = sumRides(weekCabs, weekLogistics);
        const monthlyEarnings = sumRides(monthCabs, monthLogistics);
        const totalEarnings = sumRides(allCabs, allLogistics);

        const weekRides = [...weekCabs, ...weekLogistics];
        const weeklyCompletedRides = weekRides.length;

        const dayLabels = ['Su', 'M', 'T', 'W', 'Th', 'F', 'Sa'];
        const dailyBreakdown = [];
        for (let i = 6; i >= 0; i -= 1) {
            const dayStart = new Date(now);
            dayStart.setDate(dayStart.getDate() - i);
            dayStart.setHours(0, 0, 0, 0);
            const dayEnd = new Date(dayStart);
            dayEnd.setHours(23, 59, 59, 999);

            const dayEarnings = weekRides
                .filter((ride) => {
                    const rideTime = new Date(ride.updatedAt || ride.createdAt);
                    return rideTime >= dayStart && rideTime <= dayEnd;
                })
                .reduce((acc, ride) => acc + getRideEarning(ride), 0);

            dailyBreakdown.push({
                label: dayLabels[dayStart.getDay()],
                earnings: dayEarnings,
            });
        }

        const mapTrip = (ride, type) => ({
            bookingId: ride._id?.toString(),
            userName: ride.userId?.name || ride.userName || 'Customer',
            amount: getRideEarning(ride),
            tripDistance: Number.parseFloat(ride.distance) || ride.distanceKm || 0,
            vehicleType: ride.rideMode || ride.vehicleType || type,
            date: ride.updatedAt || ride.createdAt,
            status: ride.status,
        });

        const records = [
            ...recentCabs.map((ride) => mapTrip(ride, 'CAB')),
            ...recentLogistics.map((ride) => mapTrip(ride, 'LOGISTICS')),
        ]
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .slice(0, 10);

        const bonusTarget = 15;
        const bonusAmount = 1000;

        return res.status(200).json({
            success: true,
            data: {
                walletBalance: Number(driver.walletBalance || 0),
                todayEarnings,
                weeklyEarnings,
                monthlyEarnings,
                totalEarnings,
                dailyBreakdown,
                weeklyCompletedRides,
                bonusTarget,
                bonusAmount,
                records,
                page: Math.max(Number(req.query.page || 1), 1),
                limit: Math.min(Math.max(Number(req.query.limit || 20), 1), 100),
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getDriverWallet = async (req, res) => {
    try {
        const driver = await findDriver(req.user?.id || req.user?.uid || req.query.driverId);
        if (!driver) return res.status(404).json({ success: false, message: 'Driver not found.' });

        const now = new Date();
        const todayStart = new Date(now);
        todayStart.setHours(0, 0, 0, 0);
        const weekStart = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const [today, week, payouts] = await Promise.all([
            Transaction.aggregate([{ $match: { driverId: driver._id, status: 'completed', createdAt: { $gte: todayStart } } }, { $group: { _id: null, total: { $sum: '$driverEarnings' } } }]),
            Transaction.aggregate([{ $match: { driverId: driver._id, status: 'completed', createdAt: { $gte: weekStart } } }, { $group: { _id: null, total: { $sum: '$driverEarnings' } } }]),
            Transaction.find({ driverId: driver._id, type: 'withdrawal' }).sort({ createdAt: -1 }).limit(10),
        ]);

        return res.json({
            success: true,
            walletBalance: Number(driver.walletBalance || 0),
            pendingPayout: Number(driver.walletBalance || 0),
            todayEarnings: today[0]?.total || 0,
            weekEarnings: week[0]?.total || 0,
            payoutHistory: payouts,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.requestDriverPayout = async (req, res) => {
    try {
        const driver = await findDriver(req.user?.id || req.user?.uid || req.body.driverId);
        if (!driver) return res.status(404).json({ success: false, message: 'Driver not found.' });

        const payoutAmount = Number(req.body.amount || driver.walletBalance || 0);
        if (payoutAmount < 100) {
            return res.status(400).json({ success: false, message: 'Minimum payout amount is INR 100.' });
        }
        if (Number(driver.walletBalance || 0) < payoutAmount) {
            return res.status(400).json({ success: false, message: 'Insufficient driver wallet balance.' });
        }

        driver.walletBalance = Number(driver.walletBalance || 0) - payoutAmount;
        await driver.save();
        const payout = await Transaction.create({
            driverId: driver._id,
            amount: payoutAmount,
            type: 'withdrawal',
            method: 'upi',
            status: 'pending',
            metadata: {
                requestedAt: new Date(),
                note: 'Manual payout request. Settle via RazorpayX/bank transfer.',
            },
        });

        return res.status(201).json({
            success: true,
            message: 'Payout initiated',
            amount: payoutAmount,
            estimatedSettlement: 'T+1 business day',
            payout,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getInvoice = async (req, res) => {
    try {
        const { bookingId } = req.params;
        if (!isObjectId(bookingId)) {
            return res.status(400).json({ success: false, message: 'Invalid booking id.' });
        }

        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });

        const gstRate = Number(process.env.GST_RATE || 0.18);
        const subtotal = Number(booking.vehiclePrice || 0) + Number(booking.helperCost || 0) + Number(booking.additionalCharges || 0);
        const discount = Number(booking.discountAmount || 0);
        const taxableAmount = Math.max(subtotal - discount, 0);
        const cgst = Math.round(taxableAmount * (gstRate / 2));
        const sgst = Math.round(taxableAmount * (gstRate / 2));
        const totalWithTax = taxableAmount + cgst + sgst;

        const invoice = {
            invoiceNumber: `TG-${bookingId.toString().slice(-8).toUpperCase()}`,
            invoiceDate: new Date().toISOString().split('T')[0],
            companyName: 'Transglobe Logistics Pvt. Ltd.',
            companyGST: process.env.COMPANY_GST || 'GSTIN-PENDING',
            companyAddress: process.env.COMPANY_ADDRESS || 'New Delhi, India',
            customer: {
                name: booking.userName,
                phone: booking.userPhone,
                address: booking.pickupAddress?.fullAddress || booking.pickup?.address,
            },
            delivery: {
                address: booking.receivedAddress?.fullAddress || booking.dropoff?.address,
            },
            items: [
                { description: `${booking.vehicleType} transport charge`, amount: Number(booking.vehiclePrice || 0) },
                { description: `Helper cost (${booking.helperCount || 0} helpers)`, amount: Number(booking.helperCost || 0) },
                { description: 'Additional charges', amount: Number(booking.additionalCharges || 0) },
            ].filter((item) => item.amount > 0),
            discount,
            taxableAmount,
            cgst,
            sgst,
            totalWithTax,
            status: booking.status,
            paymentMethod: 'Wallet / UPI / Corporate Billing',
        };

        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
