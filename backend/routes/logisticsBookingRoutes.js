const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const {
    createBooking,
    getUserBookings,
    getAllBookings,
    getBookingById,
    getLogisticsHistory,
    trackLogisticsBooking,
    estimateLogistics,
    cancelLogisticsBooking,
    acceptRoadmap,
    approveRoadmap,
    getGoodsTypes,
    updateStatus,
    assignDriver,
    updateRailwayStation,
    updateBilling,
    updateRoadmap,
    assignSegmentDriver,
} = require('../controllers/logisticsBookingController');

// ... (other routes)

// 📥 Driver Interaction Flows
// POST   /api/send-order-to-drivers        → Dispatcher sends order
router.post('/send-order-to-drivers', verifyToken, (req, res, next) => {
    // This is basically a wrapper or a specific endpoint for the new flow
    const { assignDriver } = require('../controllers/logisticsBookingController');
    return assignDriver(req, res);
});

// GET    /api/driver/pending-bookings  → optional auth: returns pending_for_driver
// If token valid, filters out bookings rejected by this driver.
// If no/invalid token, returns ALL pending_for_driver bookings.
router.get('/driver/pending-bookings', async (req, res) => {
    const { getDriverPendingBookings } = require('../controllers/logisticsBookingController');
    const admin = require('../config/firebase');
    const jwt = require('jsonwebtoken');
    
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) token = token.split(' ')[1];
    
    if (token) {
        try {
            const decoded = await admin.auth().verifyIdToken(token);
            req.user = decoded;
        } catch {
            try {
                const local = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
                req.user = { uid: local.uid || local.id, email: local.email };
            } catch {
                // Token invalid — proceed without user context
                req.user = null;
            }
        }
    } else {
        req.user = null;
    }
    
    return getDriverPendingBookings(req, res);
});

// PATCH  /api/booking/:id/accept           → Driver accepts
router.patch('/booking/:id/accept', (req, res, next) => {
    const { acceptBooking } = require('../controllers/logisticsBookingController');
    const { verifyToken } = require('../middlewares/authMiddleware');
    return verifyToken(req, res, () => acceptBooking(req, res));
});

// PATCH  /api/booking/:id/reject           → Driver rejects
router.patch('/booking/:id/reject', (req, res, next) => {
    const { rejectBooking } = require('../controllers/logisticsBookingController');
    const { verifyToken } = require('../middlewares/authMiddleware');
    return verifyToken(req, res, () => rejectBooking(req, res));
});

// PATCH  /api/logistics-bookings/:id/railway-station → update railway station
router.patch('/logistics-bookings/:id/railway-station', updateRailwayStation);

// ─── PRD Compatibility Endpoints (/api/logistics/*) ─────────────────────────
router.post('/logistics/estimate', estimateLogistics);
router.post('/logistics/book', verifyToken, createBooking);
router.get('/logistics/history', verifyToken, getLogisticsHistory);
router.get('/history', verifyToken, getLogisticsHistory); // Alias for user_app compatibility
router.get('/logistics/goods-types', getGoodsTypes);
router.get('/logistics/:id/track', verifyToken, trackLogisticsBooking);
router.post('/logistics/:id/cancel', cancelLogisticsBooking);
router.post('/logistics/:id/accept-roadmap', verifyToken, approveRoadmap);
router.post('/logistics-bookings/:id/roadmap/approve', verifyToken, approveRoadmap);
router.post('/logistics-booking/:id/roadmap/approve', verifyToken, approveRoadmap);
router.get('/logistics/:id', getBookingById);

// POST   /api/logistics-bookings          → create a new booking
router.post('/logistics-bookings', createBooking);

// POST   /api/bookings/create            → user_app calls this
router.post('/create', verifyToken, createBooking);

// GET    /api/logistics-bookings           → get all bookings (Admin)
router.get('/logistics-bookings', getAllBookings);

// GET    /api/logistics-bookings/user/:userId → get all bookings for a user
router.get('/logistics-bookings/user/:userId', getUserBookings);

// GET    /api/logistics-bookings/:id       → get single booking
router.get('/logistics-bookings/:id', getBookingById);

// PATCH  /api/logistics-bookings/:id/status → update status
router.patch('/logistics-bookings/:id/status', updateStatus);

// POST   /api/logistics-bookings/:id/assign → assign a driver manually
router.post('/logistics-bookings/:id/assign', assignDriver);

// PATCH  /api/logistics-bookings/:id/billing → admin edits billing
router.patch('/logistics-bookings/:id/billing', updateBilling);
router.patch('/logistics-booking/:id/billing', updateBilling);

// 🗺️ Roadmap & Multi-segment Journey
router.patch('/logistics-bookings/:id/roadmap', updateRoadmap);
router.patch('/logistics-booking/:id/roadmap', updateRoadmap);
router.post('/logistics-bookings/:id/segment/:segmentId/assign', assignSegmentDriver);

module.exports = router;
