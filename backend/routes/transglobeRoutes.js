const express    = require('express');
const router     = express.Router();
const ctrl       = require('../controllers/transglobeController');
const { verifyToken }      = require('../middlewares/authMiddleware');
const { verifyAdminToken, requireStrictAdmin } = require('../middlewares/authMiddlewareAdmin');

// ─── PUBLIC Routes (no login needed) ─────────────────────────────────────────
// GET /api/transglobe/vehicles/:id      → Single vehicle detail
router.get('/vehicles/:id',  ctrl.getVehicleDetail);

// ─── USER Protected Routes (login required) ───────────────────────────────────
// GET /api/transglobe/vehicles          → List all active vehicles (filtered by user routes)
router.get('/vehicles',      verifyToken, ctrl.listVehicles);

// ─── USER Protected Routes (login required) ───────────────────────────────────
// POST /api/transglobe/bookings/create  → Create booking
router.post('/bookings/create',         verifyToken, ctrl.createBooking);

// GET  /api/transglobe/bookings/my      → My bookings
router.get('/bookings/my',              verifyToken, ctrl.getMyBookings);

// GET  /api/transglobe/bookings/:id     → Single booking
router.get('/bookings/:id',             verifyToken, ctrl.getBookingById);

// POST /api/transglobe/bookings/:id/cancel → Cancel booking
router.post('/bookings/:id/cancel',     verifyToken, ctrl.cancelBooking);

// ─── ADMIN Routes ────────────────────────────────────────────────────────────
// GET  /api/transglobe/admin/bookings   → All bookings
router.get('/admin/bookings',           verifyAdminToken, requireStrictAdmin, ctrl.adminGetAllBookings);

// PUT  /api/transglobe/admin/bookings/:id/status → Update status
router.put('/admin/bookings/:id/status', verifyAdminToken, requireStrictAdmin, ctrl.adminUpdateBookingStatus);

// PUT /api/transglobe/admin/bookings/:id/payment → Update payment status
router.put('/admin/bookings/:id/payment', verifyAdminToken, requireStrictAdmin, ctrl.adminUpdatePaymentStatus);

module.exports = router;