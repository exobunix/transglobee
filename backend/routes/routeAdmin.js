const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminSignupController = require('../controllers/adminSignupController');
const pricingController = require('../controllers/pricingController');
const supervisorController = require('../controllers/supervisorController');
const analyticsController = require('../controllers/analyticsController');
const pricingRuleController = require('../controllers/pricingRuleController');
const notificationController = require('../controllers/notificationController');
const Corporate = require('../models/Corporate');
const { verifyAdminToken, requireSupervisorRole, requireStrictAdmin } = require('../middlewares/authMiddlewareAdmin');
const upload = require('../middlewares/uploadMiddleware');
const vehicleController = require('../controllers/vehicleController'); // add this for vechile management

const subAdminController = require('../controllers/subAdminController');

// Unprotected routes
router.post('/login', adminSignupController.login);
router.post('/register', adminSignupController.signup);
router.post('/auth', adminSignupController.auth);
router.post('/sync', adminController.syncAdminData);

// All admin routes below should be protected
router.use(verifyAdminToken);

// Sub-admin management
router.get('/sub-admins', requireStrictAdmin, subAdminController.getSubAdmins);
router.post('/sub-admins', requireStrictAdmin, subAdminController.createSubAdmin);
router.put('/sub-admins/:id', requireStrictAdmin, subAdminController.updateSubAdmin);
router.delete('/sub-admins/:id', requireStrictAdmin, subAdminController.deleteSubAdmin);
router.get('/sub-admins/importable', requireStrictAdmin, subAdminController.getImportableUsersAndDrivers);

// Admin sync/auth
router.post('/logout', adminSignupController.logout);

// Profile
router.get('/profile', adminSignupController.getProfile);
router.post('/profile/photo', upload.single('photo'), adminSignupController.updateProfilePhoto);
router.post('/profile/change-password', adminSignupController.changePassword);


// Driver management
router.get('/drivers', requireSupervisorRole, adminController.getAllDrivers);
router.post('/drivers/:driverId/approve', requireStrictAdmin, (req, res, next) => {
  req.body.status = 'active';
  return adminController.updateDriverStatus(req, res, next);
});
router.post('/drivers/:driverId/suspend', requireStrictAdmin, (req, res, next) => {
  req.body.status = 'suspended';
  return adminController.updateDriverStatus(req, res, next);
});
router.put('/drivers/:driverId/status', requireStrictAdmin, adminController.updateDriverStatus);
router.put('/drivers/:driverId/password', requireStrictAdmin, adminController.resetDriverPassword);
router.put('/drivers/:driverId/warn', requireStrictAdmin, adminController.warnDriver);
router.delete('/drivers/:driverId', requireStrictAdmin, adminController.deleteDriver);

// User management
router.get('/users', requireStrictAdmin, adminController.getAllUsers);

// ✅ NEW — Admin creates user account
// router.post('/users/create', requireStrictAdmin, adminController.createUser);
router.post('/users/create', requireStrictAdmin, (req, res) => adminController.createUser(req, res));

router.put('/users/:userId', requireStrictAdmin, adminController.updateUserProfile);
router.post('/users/:userId/suspend', requireStrictAdmin, (req, res, next) => {
  req.body.status = 'suspended';
  return adminController.updateUserStatus(req, res, next);
});
router.put('/users/:userId/status', requireStrictAdmin, adminController.updateUserStatus);
router.put('/users/:userId/profile', requireStrictAdmin, adminController.updateUserProfile);
router.put('/users/:userId/fraud', requireStrictAdmin, adminController.blacklistUser);
router.put('/users/:userId/assign-routes', requireStrictAdmin, adminController.assignRoutesToUser);
router.delete('/users/:userId', requireStrictAdmin, adminController.deleteUser);
router.get('/users/:userId/bookings', requireSupervisorRole, adminController.getUserBookings);

// Booking management
router.get('/bookings', requireSupervisorRole, adminController.getAllBookings);
router.put('/bookings/:bookingId', requireSupervisorRole, adminController.updateBookingStatus);
router.put('/bookings/:bookingId/status', requireSupervisorRole, adminController.updateBookingStatus);

// Complaint management
router.get('/complaints', requireSupervisorRole, adminController.getAllComplaints);
router.put('/complaints/:complaintId/status', requireStrictAdmin, adminController.updateComplaintStatus);

// Review management
router.get('/reviews', requireSupervisorRole, adminController.getAllReviews);

// Vehicle management
router.get('/vehicles', requireSupervisorRole, adminController.getAllVehicles);
router.post('/vehicles', requireStrictAdmin, adminController.createVehicle);
router.put('/vehicles/:vehicleId/status', requireStrictAdmin, adminController.updateVehicleStatus);
router.put('/vehicles/:vehicleId', requireStrictAdmin, adminController.updateVehicle);

// Add this new Route in Vechile management after updation
router.post('/vehicles/add',              requireStrictAdmin, vehicleController.addVehicle);
router.get('/vehicles/list',             requireStrictAdmin, vehicleController.getAllVehicles);
router.get('/vehicles/:id',              requireStrictAdmin, vehicleController.getVehicleById);
router.put('/vehicles/:id',              requireStrictAdmin, vehicleController.updateVehicle);
router.delete('/vehicles/:id',           requireStrictAdmin, vehicleController.deleteVehicle);
router.put('/vehicles/:id/toggle',       requireStrictAdmin, vehicleController.toggleVehicle);
router.put('/vehicles/:id/status',       requireStrictAdmin, vehicleController.updateVehicleStatus);
router.post('/vehicles/:id/assign-route',requireStrictAdmin, vehicleController.assignRoute);
router.put('/vehicles/:id/pricing',      requireStrictAdmin, vehicleController.updatePricing);
router.get('/vehicles/:id/bookings',     requireStrictAdmin, vehicleController.getVehicleBookings);


// Service Categories
router.post('/categories', requireStrictAdmin, adminController.createServiceCategory);
router.get('/categories', requireSupervisorRole, adminController.getServiceCategories);

// Route Management
router.post('/routes', requireStrictAdmin, adminController.createRoute);
router.get('/routes', requireSupervisorRole, adminController.getAllRoutes);
router.put('/routes/:id', requireStrictAdmin, adminController.updateRoute);
router.delete('/routes/:id', requireStrictAdmin, adminController.deleteRoute);

// Shift Management
router.post('/shifts', requireStrictAdmin, adminController.createShift);
router.get('/shifts', requireSupervisorRole, adminController.getAllShifts);
router.put('/shifts/:id', requireStrictAdmin, adminController.updateShift);
router.delete('/shifts/:id', requireStrictAdmin, adminController.deleteShift);

// Settlements & Reports
router.get('/reports/transactions', requireSupervisorRole, adminController.getTransactionReports);
router.get('/stats', requireSupervisorRole, adminController.getPlatformStats);

// Wallet Top-Up Requests Management
router.get('/wallet-requests', requireSupervisorRole, adminController.getWalletRequests);
router.put('/wallet-requests/:id/approve', requireStrictAdmin, adminController.approveWalletRequest);
router.put('/wallet-requests/:id/reject', requireStrictAdmin, adminController.rejectWalletRequest);

// CMS & Notifications
router.post('/cms', requireStrictAdmin, adminController.updateCMSContent);
router.get('/cms', requireSupervisorRole, adminController.getCMSContent);
router.delete('/cms/:id', requireStrictAdmin, adminController.deleteCMSContent);
router.post('/upload', requireStrictAdmin, upload.single('file'), adminController.uploadFile);
router.post('/notifications/broadcast', requireStrictAdmin, notificationController.broadcast);

// Delay Logs
router.post('/delays', requireSupervisorRole, adminController.logDelay);

// ─── Analytics & Reports ─────────────────────────────────
router.get('/analytics/dashboard', requireSupervisorRole, analyticsController.getDashboard);
router.get('/dashboard', requireSupervisorRole, analyticsController.getDashboard);
router.get('/analytics/live', requireSupervisorRole, analyticsController.getDashboard);
router.get('/analytics/revenue', requireSupervisorRole, analyticsController.getRevenueReport);
router.get('/analytics/driver/:driverId/performance', requireSupervisorRole, analyticsController.getDriverPerformance);
router.post('/analytics/delay-log', requireSupervisorRole, analyticsController.logDelay);
router.get('/analytics/delay-logs/:bookingId', requireSupervisorRole, analyticsController.getDelayLogs);

// ─── Pricing Configuration (Admin + Supervisor) ──────────
router.get('/pricing', requireSupervisorRole, pricingController.getAllConfigs);
router.get('/pricing/active', requireSupervisorRole, pricingController.getActiveConfig);
router.post('/pricing', requireStrictAdmin, pricingController.createConfig);
router.put('/pricing/:id', requireStrictAdmin, pricingController.updateConfig);
router.delete('/pricing/:id', requireStrictAdmin, pricingController.deleteConfig);
router.post('/pricing/calculate', requireSupervisorRole, pricingController.calculateFare);

// Dynamic pricing rules
router.post('/pricing-rules', requireStrictAdmin, pricingRuleController.createRule);
router.get('/pricing-rules', requireStrictAdmin, pricingRuleController.getRules);
router.put('/pricing-rules/:ruleId', requireStrictAdmin, pricingRuleController.updateRule);
router.delete('/pricing-rules/:ruleId', requireStrictAdmin, pricingRuleController.deleteRule);

// Corporate account management aliases
router.get('/corporate', requireStrictAdmin, async (req, res) => {
  const filter = req.query.status ? { status: req.query.status } : {};
  const corporates = await Corporate.find(filter).select('-password').sort({ createdAt: -1 });
  res.json({ success: true, corporates });
});
router.get('/corporate/:corpId', requireStrictAdmin, async (req, res) => {
  const corporate = await Corporate.findById(req.params.corpId).select('-password');
  if (!corporate) return res.status(404).json({ success: false, message: 'Corporate account not found.' });
  res.json({ success: true, corporate });
});
router.put('/corporate/:corpId', requireStrictAdmin, async (req, res) => {
  const corporate = await Corporate.findByIdAndUpdate(req.params.corpId, req.body, { new: true }).select('-password');
  if (!corporate) return res.status(404).json({ success: false, message: 'Corporate account not found.' });
  res.json({ success: true, corporate });
});

// ─── Supervisor Panel Routes ─────────────────────────────
// Edit logistics booking goods details
router.patch('/supervisor/bookings/:bookingId/goods', requireSupervisorRole, supervisorController.editGoodsDetails);
// Override pricing charges for a booking
router.patch('/supervisor/bookings/:bookingId/pricing-override', requireSupervisorRole, supervisorController.overridePricing);
// Approve and finalize a booking (sets status to processing)
router.patch('/supervisor/bookings/:bookingId/approve', requireSupervisorRole, supervisorController.approveBooking);
// Get supervisor dashboard stats
router.get('/supervisor/stats', requireSupervisorRole, supervisorController.getSupervisorStats);
// Block/Unblock user
router.patch('/users/:userId/block', requireStrictAdmin, supervisorController.blockUser);
// Block/Unblock driver
router.patch('/drivers/:driverId/block', requireStrictAdmin, supervisorController.blockDriver);
// Toggle driver online/offline
router.patch('/drivers/:driverId/online', requireStrictAdmin, supervisorController.toggleDriverOnline);

// Save multi-segment roadmap for a logistics/shuttle booking
router.patch('/supervisor/bookings/:bookingId/roadmap', requireSupervisorRole, supervisorController.saveRoadmap);
// Approve the roadmap and notify assigned segment drivers
router.patch('/supervisor/bookings/:bookingId/roadmap/approve', requireSupervisorRole, supervisorController.approveRoadmap);

module.exports = router;
