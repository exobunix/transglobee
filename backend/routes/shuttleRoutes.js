const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const ctrl = require('../controllers/shuttleController');

router.get('/routes', verifyToken, ctrl.listRoutes);
router.post('/routes', ctrl.createRoute);
router.get('/routes/:routeId/schedule', verifyToken, ctrl.getSchedule);
router.post('/book', verifyToken, ctrl.bookShuttle);
router.get('/history', verifyToken, ctrl.getHistory);
router.get('/:bookingId', verifyToken, ctrl.getBooking);
router.post('/:bookingId/cancel', verifyToken, ctrl.cancelBooking);
router.get('/:bookingId/track', verifyToken, ctrl.trackShuttle);

module.exports = router;
