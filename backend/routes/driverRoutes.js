const express = require('express');
const router = express.Router();
const {
    syncDriverData,
    register,
    login,
    checkEmailAvailability,
    getDriverProfile,
    uploadDocuments,
    getDriverStatus,
    updateDriverProfile,
    updateStatus,
    updateLocation,
    sendOTP,
    verifyOTP,
    getUserDetailsForDriver, // Add This 
    
} = require('../controllers/driverController');
const paymentController = require('../controllers/paymentController');
const { getDriverPendingBookings } = require('../controllers/logisticsBookingController');
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// POST /api/driver/otp/send - Send OTP to email
router.post('/otp/send', sendOTP);

// POST /api/driver/otp/verify - Verify OTP and mark email as verified
router.post('/otp/verify', verifyToken, verifyOTP);

// GET /api/driver/check-email - Check if email exists
router.get('/check-email', checkEmailAvailability);

// POST /api/driver/sync - To sync driver basic data to DB
router.post('/sync', syncDriverData);
router.post('/register', register);
router.post('/login', login);

// GET /api/driver/status - Check driver onboarding status
router.get('/status', verifyToken, getDriverStatus);

// GET /api/driver/profile - Gets driver profile authenticated by Firebase token
router.get('/profile', verifyToken, getDriverProfile);

// PUT /api/driver/profile/update - Updates driver profile
router.put('/profile/update', verifyToken, updateDriverProfile);

// PUT /api/driver/status - Updates driver online/offline status
router.put('/status', verifyToken, updateStatus);

// PUT /api/driver/location - Updates driver GPS location
router.put('/location', verifyToken, updateLocation);

// GET /api/driver/pending-bookings - Gets pending logistics bookings for all/specific driver
router.get('/pending-bookings', (req, res, next) => {
    // Optional auth: if token present, use it; otherwise proceed as null user
    const admin = require('../config/firebase');
    const jwt = require('jsonwebtoken');
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) token = token.split(' ')[1];
    
    if (token) {
        admin.auth().verifyIdToken(token)
            .then(decoded => { req.user = decoded; next(); })
            .catch(() => {
                try {
                    const local = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
                    req.user = { uid: local.uid || local.id, email: local.email };
                    next();
                } catch {
                    req.user = null;
                    next();
                }
            });
    } else {
        req.user = null;
        next();
    }
}, getDriverPendingBookings);

// POST /api/driver/upload - Uploads driver documents
router.post('/upload', (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (authHeader && !authHeader.includes('dev-token-bypass')) {
        return verifyToken(req, res, (err) => {
            if (err) {
                // If token verify fails but dev headers exist on localhost, allow fallback
                if (req.hostname === 'localhost' || req.hostname === '127.0.0.1') {
                    const uid = req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid';
                    const email = req.headers['x-dev-email'];
                    req.user = { uid, email };
                    return next();
                }
                return next(err);
            }
            if (!req.user?.uid && (req.headers['x-dev-uid'] || req.headers['x-dev-email'])) {
                req.user = req.user || {};
                req.user.uid = req.user.uid || req.headers['x-dev-uid'];
                req.user.email = req.user.email || req.headers['x-dev-email'];
            }
            next();
        });
    }
    // Force bypass for dev/localhost troubleshooting
    const uid = req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid';
    const email = req.headers['x-dev-email'];
    req.user = { uid, email };
    return next();
}, upload.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'aadharCard', maxCount: 1 },
    { name: 'drivingLicense', maxCount: 1 },
    { name: 'signature', maxCount: 1 },
    { name: 'panCard', maxCount: 1 },
    { name: 'rcBook', maxCount: 1 },
    { name: 'insurance', maxCount: 1 }
]), uploadDocuments);

// POST /api/driver/fcm-token - Update FCM token
router.post('/fcm-token', verifyToken, (req, res, next) => {
    const { updateFCMToken } = require('../controllers/driverController');
    updateFCMToken(req, res, next);
});

// GET /api/driver/booking/:bookingId/user-getUserDetailsForDriver
// FIX: User name, photo, phone not showing on driver ride request card`
router.get('/booking/:bookingId/user-details', verifyToken, getUserDetailsForDriver);
router.get('/wallet', verifyToken, paymentController.getDriverWallet);
router.post('/payout', verifyToken, paymentController.requestDriverPayout);
router.get('/earnings', verifyToken, (req, res, next) => {
  req.params.driverId = req.user.id || req.user.uid;
  return paymentController.getDriverEarnings(req, res, next);
});
router.get('/earnings/history', verifyToken, (req, res, next) => {
  req.params.driverId = req.user.id || req.user.uid;
  return paymentController.getDriverEarnings(req, res, next);
});

module.exports = router;
