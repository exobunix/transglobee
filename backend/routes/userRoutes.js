const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken, optionalVerifyToken } = require('../middlewares/authMiddleware'); //add this 

// Public routes for OTP-based registration

// ⚠️ Keep for existing mobile users but new users created by admin only
router.post('/register-phone', userController.registerPhone);
router.post('/save-name', userController.saveName);
router.post('/location', userController.saveSavedLocation);

// Saved Addresses
router.get('/profile/addresses', verifyToken, userController.getSavedAddresses);
router.post('/profile/addresses', verifyToken, userController.addSavedAddress);
router.put('/profile/addresses/:addressId', verifyToken, userController.updateSavedAddress);
router.delete('/profile/addresses/:addressId', verifyToken, userController.deleteSavedAddress);

// Profile routes (by phone number)
router.get('/profile', verifyToken, userController.getProfile);
router.put('/profile', verifyToken, userController.updateProfile);
router.get('/profile/:mobileNumber', verifyToken, userController.getProfile);
router.put('/profile/:mobileNumber', verifyToken, userController.updateProfile);
router.post('/fcm-token', userController.updateFCMToken);


// GET /api/user/booking/:bookingId/driver-details
// User calls this after driver accepts to see driver info
router.get('/booking/:bookingId/driver-details', optionalVerifyToken, userController.getDriverDetailsForUser);


// REGISTER
router.post('/auth/register', userController.register);  //add this registration Route
router.post('/auth/login', userController.login);

// GET /api/user/cms → Get CMS Content (FAQ, terms, banners)
router.get('/cms', userController.getCMSContent);

module.exports = router;
