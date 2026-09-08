/**
 * Reports & Analytics Controller (Module 16, 20, 23)
 * Provides comprehensive dashboard data for Admin and Supervisor.
 */

const LogisticsBooking = require('../models/LogisticsBooking');
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
        const todayStart = new Date(now.setHours(0, 0, 0, 0));
        const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        const [
            totalUsers, newUsersToday, newUsersWeek,
            totalDrivers, activeDrivers, onlineDrivers, pendingDriverApprovals,
            totalBookings, pendingBookings, activeBookings, completedBookings, cancelledBookings,
            todayBookings, weekBookings,
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
            LogisticsBooking.countDocuments(),
            LogisticsBooking.countDocuments({ status: 'pending' }),
            LogisticsBooking.countDocuments({ status: { $in: ['confirmed', 'processing', 'in_transit'] } }),
            LogisticsBooking.countDocuments({ status: 'delivered' }),
            LogisticsBooking.countDocuments({ status: 'cancelled' }),
            LogisticsBooking.countDocuments({ createdAt: { $gte: todayStart } }),
            LogisticsBooking.countDocuments({ createdAt: { $gte: weekAgo } }),
            Transaction.aggregate([{ $match: { status: 'completed' } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: monthAgo } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: weekAgo } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Transaction.aggregate([{ $match: { status: 'completed', createdAt: { $gte: todayStart } } }, { $group: { _id: null, total: { $sum: '$amount' } } }]),
            Review.aggregate([{ $group: { _id: '$onModel', avg: { $avg: '$rating' } } }]),
        ]);

        // Daily bookings trend (last 7 days)
        const dailyTrend = await LogisticsBooking.aggregate([
            { $match: { createdAt: { $gte: weekAgo } } },
            {
                $group: {
                    _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
                    count: { $sum: 1 },
                    revenue: { $sum: '$totalPrice' },
                },
            },
            { $sort: { '_id': 1 } },
        ]);

        // Top modes of transport
        const modeStats = await LogisticsBooking.aggregate([
            { $group: { _id: '$vehicleType', count: { $sum: 1 } } },
            { $sort: { count: -1 } },
            { $limit: 5 },
        ]);

        const avgDriverRating = avgRatingResult.find(r => r._id === 'Driver')?.avg || 0;
        const avgUserRating = avgRatingResult.find(r => r._id === 'User')?.avg || 0;

        const responseData = {
            success: true, // for middleware/compatibility
            totalUsers,
            activeDrivers,
            todayBookings,
            todayRevenue: revenueToday[0]?.total || 0,
            pendingDriverApprovals,
            activeRides: activeBookings,
            // Original nested structure preserved in 'data' for other consumers
            data: {
                users: { total: totalUsers, today: newUsersToday, week: newUsersWeek },
                drivers: { total: totalDrivers, active: activeDrivers, online: onlineDrivers, pending: pendingDriverApprovals },
                bookings: {
                    total: totalBookings, pending: pendingBookings, active: activeBookings,
                    completed: completedBookings, cancelled: cancelledBookings,
                    today: todayBookings, week: weekBookings,
                },
                revenue: {
                    allTime: revenueAll[0]?.total || 0,
                    monthly: revenueMonth[0]?.total || 0,
                    weekly: revenueWeek[0]?.total || 0,
                    today: revenueToday[0]?.total || 0,
                },
                ratings: { drivers: Math.round(avgDriverRating * 10) / 10, users: Math.round(avgUserRating * 10) / 10 },
                trends: { daily: dailyTrend, modes: modeStats },
            },
        };

        console.log('[ANALYTICS] Dashboard Data Sent:', JSON.stringify(responseData));

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
                completedTrips,
                cancelledTrips,
                totalTrips: completedTrips + cancelledTrips,
                completionRate: completedTrips + cancelledTrips > 0
                    ? Math.round((completedTrips / (completedTrips + cancelledTrips)) * 100)
                    : 0,
                averageRating: Math.round(avgRating * 10) / 10,
                totalRatings: ratings.length,
                totalEarnings: earnings[0]?.total || 0,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/analytics/revenue ────────────────────
// Revenue breakdown report
exports.getRevenueReport = async (req, res) => {
    try {
        const { from, to } = req.query;
        const match = { status: 'completed' };
        if (from || to) {
            match.createdAt = {};
            if (from) match.createdAt.$gte = new Date(from);
            if (to) match.createdAt.$lte = new Date(to);
        }

        const [byDay, byMode, totals] = await Promise.all([
            LogisticsBooking.aggregate([
                { $match: { status: 'delivered', ...(match.createdAt && { createdAt: match.createdAt }) } },
                { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, revenue: { $sum: '$totalPrice' }, count: { $sum: 1 } } },
                { $sort: { '_id': 1 } },
            ]),
            LogisticsBooking.aggregate([
                { $match: { status: 'delivered' } },
                { $group: { _id: '$vehicleType', revenue: { $sum: '$totalPrice' }, count: { $sum: 1 } } },
                { $sort: { revenue: -1 } },
            ]),
            Transaction.aggregate([
                { $match: match },
                { $group: { _id: null, gross: { $sum: '$amount' }, commission: { $sum: '$adminCommission' }, driverPayout: { $sum: '$driverEarnings' } } },
            ]),
        ]);

        return res.status(200).json({
            success: true,
            data: { byDay, byMode, totals: totals[0] || { gross: 0, commission: 0, driverPayout: 0 } },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/admin/analytics/delay-log ─────────────────
// Supervisor logs a delay on a booking segment
exports.logDelay = async (req, res) => {
    try {
        const { bookingId, segmentId, reason, delayMinutes } = req.body;
        if (!bookingId || !reason) {
            return res.status(400).json({ success: false, message: 'bookingId and reason required.' });
        }

        const log = await DelayLog.create({
            bookingId,
            segmentId: segmentId || null,
            reason,
            delayMinutes: delayMinutes || 0,
            loggedBy: req.user?.adminId || req.user?.uid,
        });

        // Notify user about delay
        const booking = await LogisticsBooking.findById(bookingId);
        if (booking) {
            const { notifyUser } = require('../utils/notificationService');
            notifyUser(booking.userId, {
                title: 'Shipment Delay Alert',
                body: `Your shipment has been delayed by ${delayMinutes || 'some'} minutes. Reason: ${reason}`,
                data: { bookingId: bookingId.toString(), type: 'DELAY_ALERT' },
            });
            if (req.io) {
                req.io.to(booking.userId.toString()).emit('shipment_delayed', {
                    bookingId: bookingId.toString(),
                    reason,
                    delayMinutes,
                });
            }
        }

        return res.status(201).json({ success: true, message: 'Delay logged.', data: log });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/analytics/delay-logs/:bookingId ──────
exports.getDelayLogs = async (req, res) => {
    try {
        const logs = await DelayLog.find({ bookingId: req.params.bookingId }).sort({ createdAt: -1 });
        return res.status(200).json({ success: true, data: logs });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
