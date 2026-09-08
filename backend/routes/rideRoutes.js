const express = require("express");
const router = express.Router();
const rideController = require("../controllers/rideController");
const { verifyToken, optionalVerifyToken } = require("../middlewares/authMiddleware");

const trackOrGetRide = async (req, res, next) => {
  try {
    const History = require('../models/History');
    const ride = await History.findById(req.params.rideId);
    if (!ride && !req.user) {
      return res.status(401).json({ success: false, message: "Authentication required." });
    }
    return rideController.getRideById(req, res, next);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

router.get("/driver-bookings", verifyToken, rideController.getDriverBookings);
router.get("/ride-types", rideController.getRideTypes);
router.get("/vehicles", rideController.getRideTypes);
router.get("/my-rides", optionalVerifyToken, rideController.getMyRides);
router.get("/history", optionalVerifyToken, rideController.getMyRides);
router.get("/rides/:rideId", optionalVerifyToken, trackOrGetRide);
router.get("/:rideId", optionalVerifyToken, trackOrGetRide);

// Route for saving user's input/booking
router.post("/ride-request", optionalVerifyToken, rideController.createRideRequest);
router.post("/book", optionalVerifyToken, rideController.createRideRequest);
router.put("/update-fare", optionalVerifyToken, rideController.updateFare);
router.put("/fare", optionalVerifyToken, rideController.updateFare);
router.post("/:rideId/cancel", optionalVerifyToken, async (req, res, next) => {
  try {
    const History = require('../models/History');
    const ride = await History.findById(req.params.rideId);
    if (!ride && !req.user) {
      return res.status(401).json({ success: false, message: "Authentication required to cancel this booking." });
    }
    req.params.rideId = req.params.rideId;
    req.body = { ...(req.body || {}), status: "cancelled" };
    return rideController.updateRideStatus(req, res, next);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
});
router.put("/:rideId/modify", optionalVerifyToken, (req, res, next) => {
  // Existing backend supports fare updates; keep modify for compatibility.
  req.body = {
    ...(req.body || {}),
    rideId: req.params.rideId,
    extraFare: Number(req.body?.extraFare || req.body?.fareDelta || 0),
  };
  return rideController.updateFare(req, res, next);
});
router.get("/:rideId/track", optionalVerifyToken, trackOrGetRide);
router.post("/:rideId/rate", verifyToken, (req, res, next) => {
  req.body = { ...(req.body || {}), bookingId: req.params.rideId };
  return rideController.submitReview(req, res, next);
});

// DRIVER APIs
// fetch full list (optionally filter)
router.get('/rides', verifyToken, rideController.getRideDetails);
// only pending rides (for quick polling)
router.get('/rides/pending', verifyToken, rideController.getPendingRides);
// driver accepts/assigns a ride
router.put('/rides/:rideId/assign', verifyToken, rideController.assignRide);
// driver rejects a ride
router.put('/rides/:rideId/reject', verifyToken, rideController.rejectRide);
// update status or complete
router.put('/rides/:rideId/status', verifyToken, rideController.updateRideStatus);
router.put('/rides/:rideId/complete', verifyToken, rideController.updateRideStatus);
router.put('/rides/:rideId/verify-otp', verifyToken, rideController.verifyRideOtp);
router.post('/review', verifyToken, rideController.submitReview);
router.put('/rides/:rideId/pay', verifyToken, rideController.payRide);

module.exports = router;
