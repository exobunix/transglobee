const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const { requireSupervisorOrAdmin } = require('../middlewares/rbacMiddleware');
const ctrl = require('../controllers/supervisorApiController');
const authCtrl = require('../controllers/supervisorAuthController');
const adminController = require('../controllers/adminController');

// ─── PUBLIC ROUTES (No Token Required) ───────────────────────────────────────
// Inhe hamesha top par rakhein taaki global middleware inhe affect na kare
router.post('/auth/register', authCtrl.register);
router.post('/auth/login',    authCtrl.login);

// ─── PROTECTED ROUTES (Token Required) ───────────────────────────────────────
// Iske niche ke saare routes verifyToken aur Role check se pass honge
router.use(verifyToken);

router.get ('/auth/me',              authCtrl.getMe);
router.post('/auth/logout',          authCtrl.logout);
router.put ('/auth/change-password', authCtrl.changePassword);

// ─── OPERATIONAL ROUTES (Supervisor/Admin Only) ──────────────────────────────
router.use(requireSupervisorOrAdmin);

router.get('/queue', ctrl.queue);
router.post('/queue/:bookingId/claim', ctrl.claimBooking);
// Admin booking parity for supervisor panel:
// supports ?type=logistics|shuttle|ride and returns unified booking lists
router.get('/bookings', adminController.getAllBookings);
router.put('/bookings/:bookingId/status', adminController.updateBookingStatus);
router.put('/bookings/:bookingId', ctrl.updateBooking);
router.post('/roadmap', ctrl.createRoadmap);
router.get('/roadmap/:roadmapId', ctrl.getRoadmap);
router.post('/roadmap/:roadmapId/segments', ctrl.addSegment);
router.put('/roadmap/:roadmapId/segments/:segId', ctrl.updateSegment);
router.delete('/roadmap/:roadmapId/segments/:segId', ctrl.deleteSegment);
router.post('/roadmap/:roadmapId/approve', ctrl.approveRoadmap);
router.put('/roadmap/:roadmapId/pricing', ctrl.adjustPricing);
router.get('/drivers/available', ctrl.availableDrivers);
router.put('/drivers/:id/status', ctrl.updateDriverStatus);
router.get('/shipments/active', ctrl.activeShipments);



// Dashboard Analytics
router.get('/stats/weekly', ctrl.weeklyStats);
router.get('/drivers/status', ctrl.driverStatusOverview);

// Fleet Management
router.get('/fleet', ctrl.getFleetVehicles);
router.post('/fleet', ctrl.addVehicle);
router.put('/fleet/:id', ctrl.updateVehicle);
router.put('/fleet/:id/status', ctrl.updateVehicleStatus);
router.get('/fleet/:id/location', ctrl.getVehicleLocation);

//Routes for live Tracking 
router.post('/live-tracking/update', ctrl.updateLiveLocation);

router.get('/live-tracking', ctrl.getLiveFleet);

router.get('/live-tracking/shipments/active', ctrl.getActiveShipments);

router.get('/live-tracking/:bookingId', ctrl.getShipmentTracking);

module.exports = router;
