const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/create-order', verifyToken, paymentController.createOrder);
router.post('/initiate', verifyToken, paymentController.initiatePayment);
router.post('/verify', verifyToken, paymentController.verifyPayment);
router.post('/callback', paymentController.gatewayCallback);
router.post('/webhook', paymentController.gatewayCallback);
router.post('/refund', verifyToken, paymentController.refundPayment);

router.post('/wallet/add', verifyToken, paymentController.walletAdd);
router.post('/wallet/topup', verifyToken, paymentController.walletAdd);
router.post('/topup', verifyToken, paymentController.walletAdd); // Alias for /api/wallet/topup
router.post('/wallet/deduct', verifyToken, paymentController.walletDeduct);
router.post('/deduct', verifyToken, paymentController.walletDeduct); // Alias
router.get('/wallet/balance', verifyToken, paymentController.getWalletBalance);
router.get('/balance', verifyToken, paymentController.getWalletBalance); // Alias for /api/wallet/balance
router.get('/wallet/history', verifyToken, paymentController.getWalletHistory);
router.get('/history', verifyToken, paymentController.getWalletHistory); // Alias for /api/wallet/history

router.get('/driver/earnings/:driverId', verifyToken, paymentController.getDriverEarnings);
router.get('/invoice/:bookingId', verifyToken, paymentController.getInvoice);

module.exports = router;
