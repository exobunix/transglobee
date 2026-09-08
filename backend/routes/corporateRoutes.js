const express = require('express');
const router = express.Router();
const corporateController = require('../controllers/corporateController');
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.post('/login', corporateController.login);
router.post('/google-sync', corporateController.googleSync);
router.get('/profile', verifyToken, corporateController.getProfile);
router.get('/bookings', verifyToken, corporateController.getBookings);
router.post('/bookings/bulk', verifyToken, upload.single('file'), corporateController.bulkCreateBookings);
router.post('/bulk-bookings', verifyToken, upload.single('file'), corporateController.bulkCreateBookings);
router.get('/bulk-bookings/template', verifyToken, corporateController.downloadBulkTemplate);
router.get('/invoice/:bookingId', verifyToken, corporateController.generateInvoice);
router.get('/credit', verifyToken, corporateController.getCredit);
router.put('/credit', verifyToken, corporateController.updateCredit);
router.put('/:id/credit', verifyToken, corporateController.updateCredit);
router.get('/credit-status', verifyToken, corporateController.getCreditStatus);
router.get('/dashboard', verifyToken, corporateController.dashboard);

module.exports = router;
