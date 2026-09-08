/**
 * Two-way Ratings Controller
 * User rates Driver and Driver rates User after trip completion.
 */
const Review = require('../models/Review');
const Driver = require('../models/Driver');

// ─── POST /api/ratings  ───────────────────────────────────
// Submit a rating (user→driver or driver→user)
exports.submitRating = async (req, res) => {
    try {
        const { bookingId, fromId, toId, onModel, rating, comment } = req.body;

        if (!bookingId || !fromId || !toId || !onModel || !rating) {
            return res.status(400).json({ success: false, message: 'bookingId, fromId, toId, onModel, and rating are required.' });
        }
        if (!['User', 'Driver'].includes(onModel)) {
            return res.status(400).json({ success: false, message: 'onModel must be "User" or "Driver".' });
        }
        if (rating < 1 || rating > 5) {
            return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5.' });
        }

        // Prevent duplicate rating for same booking+from+to
        const existing = await Review.findOne({ bookingId, fromId, toId });
        if (existing) {
            return res.status(409).json({ success: false, message: 'Rating already submitted for this booking.' });
        }

        const review = await Review.create({ bookingId, fromId, toId, onModel, rating, comment });

        // Update driver average rating if rating is for a driver
        if (onModel === 'Driver') {
            const allReviews = await Review.find({ toId, onModel: 'Driver' });
            const avg = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
            await Driver.findByIdAndUpdate(toId, { rating: Math.round(avg * 10) / 10 });
        }

        return res.status(201).json({ success: true, message: 'Rating submitted.', data: review });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/ratings/booking/:bookingId  ────────────────
// Get both ratings for a booking (user→driver and driver→user)
exports.getBookingRatings = async (req, res) => {
    try {
        const reviews = await Review.find({ bookingId: req.params.bookingId });
        return res.status(200).json({ success: true, data: reviews });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/ratings/driver/:driverId  ──────────────────
// Get all reviews for a driver
exports.getDriverRatings = async (req, res) => {
    try {
        const reviews = await Review.find({ toId: req.params.driverId, onModel: 'Driver' })
            .sort({ createdAt: -1 })
            .limit(50);

        const avg = reviews.length
            ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
            : 0;

        return res.status(200).json({
            success: true,
            data: { averageRating: Math.round(avg * 10) / 10, total: reviews.length, reviews },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/ratings/user/:userId  ──────────────────────
// Get all reviews for a user
exports.getUserRatings = async (req, res) => {
    try {
        const reviews = await Review.find({ toId: req.params.userId, onModel: 'User' })
            .sort({ createdAt: -1 })
            .limit(50);

        const avg = reviews.length
            ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
            : 0;

        return res.status(200).json({
            success: true,
            data: { averageRating: Math.round(avg * 10) / 10, total: reviews.length, reviews },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
