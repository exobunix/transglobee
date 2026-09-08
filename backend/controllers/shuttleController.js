const ShuttleRoute = require('../models/ShuttleRoute');
const ShuttleBooking = require('../models/ShuttleBooking');

const getUserId = (req) => req.user?.uid || req.user?.id || req.body.userId || req.query.userId;

exports.listRoutes = async (req, res) => {
    try {
        const { city, origin } = req.query;
        const filter = { isActive: true };
        if (city) filter.city = new RegExp(city, 'i');
        if (origin) filter.$or = [
            { origin: new RegExp(origin, 'i') },
            { 'stops.name': new RegExp(origin, 'i') },
        ];

        const routes = await ShuttleRoute.find(filter).sort({ routeName: 1 });
        return res.json({ success: true, routes });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getSchedule = async (req, res) => {
    try {
        const { routeId } = req.params;
        const { date } = req.query;
        const route = await ShuttleRoute.findById(routeId);
        if (!route) return res.status(404).json({ success: false, message: 'Shuttle route not found.' });

        const booked = await ShuttleBooking.aggregate([
            { $match: { routeId: route._id, date, status: 'booked' } },
            { $group: { _id: '$departureTime', seats: { $sum: '$seatCount' } } },
        ]);
        const bookedMap = new Map(booked.map((item) => [item._id, item.seats]));

        const departures = route.departures.map((departure) => ({
            departureTime: departure.departureTime,
            availableSeats: Math.max(Number(departure.totalSeats || 0) - Number(bookedMap.get(departure.departureTime) || 0), 0),
            totalSeats: departure.totalSeats,
            price: departure.price || route.basePrice,
        }));

        return res.json({ success: true, routeId, date, departures });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.bookShuttle = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { routeId, departureTime, date, seatCount = 1, paymentMethod = 'upi' } = req.body;
        if (!userId || !routeId || !departureTime || !date) {
            return res.status(400).json({ success: false, message: 'routeId, departureTime, date, and authenticated user are required.' });
        }

        const User = require('../models/User');
        const user = await User.findById(userId);

        const route = await ShuttleRoute.findById(routeId);
        if (!route) return res.status(404).json({ success: false, message: 'Shuttle route not found.' });

        const departure = route.departures.find((item) => item.departureTime === departureTime);
        if (!departure) return res.status(400).json({ success: false, message: 'Departure time is not available for this route.' });

        const bookedSeats = await ShuttleBooking.aggregate([
            { $match: { routeId: route._id, date, departureTime, status: { $in: ['booked', 'confirmed', 'processing', 'pending'] } } },
            { $group: { _id: null, seats: { $sum: '$seatCount' } } },
        ]);
        const availableSeats = Number(departure.totalSeats || 0) - Number(bookedSeats[0]?.seats || 0);
        if (availableSeats < Number(seatCount)) {
            return res.status(400).json({ success: false, message: 'Not enough seats available.', availableSeats });
        }

        const price = Number(departure.price || route.basePrice || 0);
        const booking = await ShuttleBooking.create({
            userId,
            userName: user ? user.name : 'Shuttle Passenger',
            userPhone: user ? (user.mobileNumber || user.phone) : '',
            routeId,
            departureTime,
            date,
            seatCount,
            paymentMethod,
            totalPrice: price * Number(seatCount),
            status: 'pending',
            roadmapStatus: 'draft',
            pickup: {
                name: route.origin || 'Origin',
                address: route.origin || 'Origin',
                lat: route.stops?.[0]?.lat || 0,
                lng: route.stops?.[0]?.lng || 0
            },
            dropoff: {
                name: route.destination || 'Destination',
                address: route.destination || 'Destination',
                lat: route.stops?.[route.stops.length - 1]?.lat || 0,
                lng: route.stops?.[route.stops.length - 1]?.lng || 0
            },
            vehicleType: 'Shuttle'
        });

        if (req.io) {
            const socketData = {
                id: booking._id.toString(),
                userId: userId,
                routeId: routeId.toString(),
                routeName: route.routeName || 'Shuttle Route',
                type: 'SHUTTLE',
                status: 'pending',
                departureTime: departureTime,
                date: date,
                pickup: booking.pickup,
                dropoff: booking.dropoff,
                userName: booking.userName,
                userPhone: booking.userPhone,
                message: "New shuttle booking requested"
            };
            req.io.emit("supervisor_new_booking", socketData);
            req.io.emit("admin_new_booking", socketData);
        }

        return res.status(201).json({ success: true, message: 'Shuttle booked successfully.', booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getHistory = async (req, res) => {
    try {
        const bookings = await ShuttleBooking.find({ userId: getUserId(req) }).populate('routeId').sort({ createdAt: -1 });
        return res.json({ success: true, bookings });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getBooking = async (req, res) => {
    try {
        const booking = await ShuttleBooking.findById(req.params.bookingId).populate('routeId');
        if (!booking) return res.status(404).json({ success: false, message: 'Shuttle booking not found.' });
        return res.json({ success: true, booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.cancelBooking = async (req, res) => {
    try {
        const booking = await ShuttleBooking.findByIdAndUpdate(req.params.bookingId, { status: 'cancelled' }, { new: true });
        if (!booking) return res.status(404).json({ success: false, message: 'Shuttle booking not found.' });
        return res.json({ success: true, message: 'Shuttle booking cancelled.', booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.trackShuttle = async (req, res) => {
    try {
        const booking = await ShuttleBooking.findById(req.params.bookingId).populate('routeId');
        if (!booking) return res.status(404).json({ success: false, message: 'Shuttle booking not found.' });
        const route = booking.routeId;
        const nextStop = route?.stops?.[0]?.name || route?.destination || 'Next stop';
        return res.json({
            success: true,
            currentLocation: booking.currentLocation || { lat: route?.stops?.[0]?.lat || 0, lng: route?.stops?.[0]?.lng || 0 },
            nextStop,
            etaMinutes: 12,
            driverName: 'Assigned Driver',
            vehicleNumber: 'Pending Assignment',
        });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.createRoute = async (req, res) => {
    try {
        const route = await ShuttleRoute.create(req.body);
        return res.status(201).json({ success: true, route });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};
