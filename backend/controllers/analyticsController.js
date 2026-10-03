/**
 * Reports & Analytics Controller (Module 16, 20, 23)
 * Provides comprehensive dashboard data for Admin and Supervisor.
 */

const LogisticsBooking = require('../models/LogisticsBooking');
const History = require('../models/History');
const ShuttleBooking = require('../models/ShuttleBooking');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Transaction = require('../models/Transaction');
const Review = require('../models/Review');
const DelayLog = require('../models/DelayLog');

// ─── GET /api/admin/analytics/dashboard ──────────────────
// Full dashboard stats (admin overview)
exports.getDashboard = async (req, res) => {
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    try {
        const now = new Date();
        const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const startOfYear = new Date(now.getFullYear(), 0, 1);

        const [
            totalUsers, newUsersToday, newUsersWeek,
            totalDrivers, activeDrivers, onlineDrivers, pendingDriverApprovals,
            logisticsCount, cabCount, shuttleCount,
            logisticsPending, cabPending, shuttlePending,
            logisticsActive, cabActive, shuttleActive,
            logisticsCompleted, cabCompleted, shuttleCompleted,
            logisticsCancelled, cabCancelled, shuttleCancelled,
            todayLogistics, todayCabs, todayShuttles,
            revenueAll, revenueMonth, revenueWeek, revenueToday,
            avgRatingResult,
        ] = await Promise.all([
            User.countDocuments(),
            User.countDocuments({ createdAt: { $gte: todayStart } }),
            User.countDocuments({ createdAt: { $gte: weekAgo } }),
            Driver.countDocuments(),
            Driver.countDocuments({ status: 'active' }),
            Driver.countDocuments({ isOnline: true }),
            Driver.countDocuments({ status: 'pending' }),
            
            // Counts by category
            LogisticsBooking.countDocuments(),
            History.countDocuments(),
            ShuttleBooking.countDocuments(),

            // Pending
            LogisticsBooking.countDocuments({ status: { $in: ['pending', 'placed', 'pending_for_driver'] } }),
            History.countDocuments({ status: { $in: ['pending', 'placed', 'searching'] } }),
            ShuttleBooking.countDocuments({ status: { $in: ['pending', 'placed'] } }),

            // Active
            LogisticsBooking.countDocuments({ status: { $in: ['confirmed', 'processing', 'in_transit'] } }),
            History.countDocuments({ status: { $in: ['accepted', 'on_the_way', 'arrived', 'ongoing', 'in_progress', 'started'] } }),
            ShuttleBooking.countDocuments({ status: { $in: ['confirmed', 'processing', 'in_transit', 'booked'] } }),

            // Completed
            LogisticsBooking.countDocuments({ status: 'delivered' }),
            History.countDocuments({ status: 'completed' }),
            ShuttleBooking.countDocuments({ status: { $in: ['completed', 'delivered'] } }),

            // Cancelled
            LogisticsBooking.countDocuments({ status: 'cancelled' }),
            History.countDocuments({ status: 'cancelled' }),
            ShuttleBooking.countDocuments({ status: 'cancelled' }),

            // Today
            LogisticsBooking.countDocuments({ createdAt: { $gte: todayStart } }),
            History.countDocuments({ createdAt: { $gte: todayStart } }),
            ShuttleBooking.countDocuments({ createdAt: { $gte: todayStart } }),

            // Revenue
            Transaction.aggregate([{ $match: { status: 'completed' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: monthAgo } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: weekAgo } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: todayStart } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Review.aggregate([{ $group: { _id: '$onModel', avg: { $avg: '$rating' } } }]),
        ]);

        const totalBookings = logisticsCount + cabCount + shuttleCount;
        const totalPending = logisticsPending + cabPending + shuttlePending;
        const totalActive = logisticsActive + cabActive + shuttleActive;
        const totalCompleted = logisticsCompleted + cabCompleted + shuttleCompleted;
        const totalCancelled = logisticsCancelled + cabCancelled + shuttleCancelled;
        const todayBookings = todayLogistics + todayCabs + todayShuttles;

        // Fallback revenue calculation if transactions are not yet recorded
        let allTimeRevenue = revenueAll[0]?.total || 0;
        let todayRevenueVal = revenueToday[0]?.total || 0;
        if (allTimeRevenue === 0) {
            const [cabRev, logRev, shutRev] = await Promise.all([
                History.aggregate([{ $match: { status: 'completed' } }, { $group: { _id: null, sum: { $sum: '$fare' } } }]),
                LogisticsBooking.aggregate([{ $match: { status: 'delivered' } }, { $group: { _id: null, sum: { $sum: '$totalPrice' } } }]),
                ShuttleBooking.aggregate([{ $match: { status: { $in: ['completed', 'delivered'] } } }, { $group: { _id: null, sum: { $sum: '$totalPrice' } } }]),
            ]);
            allTimeRevenue = (cabRev[0]?.sum || 0) + (logRev[0]?.sum || 0) + (shutRev[0]?.sum || 0);
        }

        // Monthly bookings & revenue array for current year (Jan to Dec)
        const monthlyEarnings = new Array(12).fill(0);
        const monthlyBookings = new Array(12).fill(0);

        try {
            const [cabMonthly, logMonthly] = await Promise.all([
                History.aggregate([
                    { $match: { createdAt: { $gte: startOfYear } } },
                    { $group: { _id: { $month: '$createdAt' }, count: { $sum: 1 }, sum: { $sum: '$fare' } } }
                ]),
                LogisticsBooking.aggregate([
                    { $match: { createdAt: { $gte: startOfYear } } },
                    { $group: { _id: { $month: '$createdAt' }, count: { $sum: 1 }, sum: { $sum: '$totalPrice' } } }
                ])
            ]);

            cabMonthly.forEach(item => {
                const m = item._id - 1;
                if (m >= 0 && m < 12) {
                    monthlyBookings[m] += item.count || 0;
                    monthlyEarnings[m] += item.sum || 0;
                }
            });
            logMonthly.forEach(item => {
                const m = item._id - 1;
                if (m >= 0 && m < 12) {
                    monthlyBookings[m] += item.count || 0;
                    monthlyEarnings[m] += item.sum || 0;
                }
            });
        } catch (err) {
            console.error('Error calculating monthly trends:', err);
        }

        // Top modes of transport
        const modeStats = [
            { mode: 'Cab', count: cabCount },
            { mode: 'Logistics', count: logisticsCount },
            { mode: 'Shuttle', count: shuttleCount },
        ];

        // Fetch Recent Bookings from all 3 collections
        const [recentCabs, recentLogistics, recentShuttles] = await Promise.all([
            History.find().sort({ createdAt: -1 }).limit(5).lean(),
            LogisticsBooking.find().sort({ createdAt: -1 }).limit(5).lean(),
            ShuttleBooking.find().sort({ createdAt: -1 }).limit(5).lean(),
        ]);

        const formatBooking = (b, type) => ({
            id: b._id.toString(),
            _id: b._id.toString(),
            userName: b.userName || b.name || 'User',
            userPhone: b.userPhone || b.phone || '',
            pickupAddress: b.pickupLocation || b.pickup?.address || b.pickup?.name || 'Pickup',
            dropAddress: b.dropLocation || b.dropoff?.address || b.dropoff?.name || 'Dropoff',
            fare: b.fare || b.totalPrice || b.vehiclePrice || 0,
            status: b.status,
            type: type,
            bookingCategory: type,
            createdAt: b.createdAt || new Date(),
        });

        const recentBookings = [
            ...recentCabs.map(b => formatBooking(b, 'cab')),
            ...recentLogistics.map(b => formatBooking(b, 'logistics')),
            ...recentShuttles.map(b => formatBooking(b, 'shuttle')),
        ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 10);

        const avgDriverRating = avgRatingResult.find(r => r._id === 'Driver')?.avg || 4.8;
        const avgUserRating = avgRatingResult.find(r => r._id === 'User')?.avg || 4.9;

        const responseData = {
            success: true,
            totalUsers,
            activeDrivers,
            todayBookings,
            todayRevenue: todayRevenueVal,
            pendingDriverApprovals,
            activeRides: totalActive,
            recentBookings,
            monthlyEarnings,
            monthlyBookings,
            data: {
                users: { total: totalUsers, today: newUsersToday, week: newUsersWeek },
                drivers: { total: totalDrivers, active: activeDrivers, online: onlineDrivers, pending: pendingDriverApprovals },
                bookings: {
                    total: totalBookings,
                    pending: totalPending,
                    active: totalActive,
                    completed: totalCompleted,
                    cancelled: totalCancelled,
                    today: todayBookings,
                    cab: cabCount,
                    logistics: logisticsCount,
                    shuttle: shuttleCount
                },
                revenue: {
                    allTime: allTimeRevenue,
                    monthly: revenueMonth[0]?.total || allTimeRevenue,
                    weekly: revenueWeek[0]?.total || 0,
                    today: todayRevenueVal,
                },
                ratings: { drivers: Math.round(avgDriverRating * 10) / 10, users: Math.round(avgUserRating * 10) / 10 },
                trends: { modes: modeStats, monthlyEarnings, monthlyBookings },
                recentBookings
            },
        };

        return res.status(200).json(responseData);
    } catch (error) {
        console.error('[ANALYTICS] Dashboard error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/analytics/driver/:driverId/performance ─
// Driver performance report
exports.getDriverPerformance = async (req, res) => {
    try {
        const { driverId } = req.params;
        const mongoose = require('mongoose');
        const id = new mongoose.Types.ObjectId(driverId);

        const [driver, completedTrips, cancelledTrips, ratings, earnings] = await Promise.all([
            Driver.findById(driverId).select('name email mobileNumber walletBalance isOnline status'),
            LogisticsBooking.countDocuments({ driverId: id, status: 'delivered' }),
            LogisticsBooking.countDocuments({ driverId: id, status: 'cancelled' }),
            Review.find({ toId: id, onModel: 'Driver' }),
            Transaction.aggregate([
                { $match: { driverId: id, status: 'completed' } },
                { $group: { _id: null, total: { $sum: '$driverEarnings' } } },
            ]),
        ]);

        if (!driver) return res.status(404).json({ success: false, message: 'Driver not found.' });

        const avgRating = ratings.length
            ? ratings.reduce((s, r) => s + r.rating, 0) / ratings.length
            : 0;

        return res.status(200).json({
            success: true,
            data: {
                driver,
                performance: {
                    completedTrips,
                    cancelledTrips,
                    totalTrips: completedTrips + cancelledTrips,
                    completionRate: completedTrips + cancelledTrips > 0
                        ? Math.round((completedTrips / (completedTrips + cancelledTrips)) * 100)
                        : 100,
                    averageRating: Math.round(avgRating * 10) / 10,
                    totalEarnings: earnings[0]?.total || 0,
                },
            },
        });
    } catch (error) {
        console.error('Error fetching driver performance:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/analytics/revenue/breakdown ────────────
exports.getRevenueBreakdown = async (req, res) => {
    try {
        const { startDate, endDate, groupBy = 'day' } = req.query;
        const match = { status: 'completed' };
        if (startDate || endDate) {
            match.createdAt = {};
            if (startDate) match.createdAt.$gte = new Date(startDate);
            if (endDate) match.createdAt.$lte = new Date(endDate);
        }

        const dateFormats = { day: '%Y-%m-%d', week: '%Y-W%V', month: '%Y-%m' };
        const format = dateFormats[groupBy] || '%Y-%m-%d';

        const breakdown = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: { $dateToString: { format, date: '$createdAt' } },
                    grossRevenue: { $sum: '$amount' },
                    driverPayout: { $sum: '$driverEarnings' },
                    adminCommission: { $sum: '$adminCommission' },
                    transactions: { $sum: 1 },
                },
            },
            { $sort: { '_id': 1 } },
        ]);

        return res.status(200).json({ success: true, groupBy, data: breakdown });
    } catch (error) {
        console.error('Error fetching revenue breakdown:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getRevenueReport = exports.getRevenueBreakdown;

exports.logDelay = async (req, res) => {
    try {
        const { bookingId, reason, delayMinutes, notes } = req.body;
        const delay = new DelayLog({
            bookingId,
            reason,
            delayMinutes,
            notes
        });
        await delay.save();
        res.status(201).json({ success: true, message: 'Delay logged successfully', delay });
    } catch (error) {
        console.error('Error logging delay:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

exports.getDelayLogs = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const delays = await DelayLog.find({ bookingId }).sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: delays });
    } catch (error) {
        console.error('Error fetching delay logs:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};
