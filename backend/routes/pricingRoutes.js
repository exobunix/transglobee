const express = require("express");
const router = express.Router();
const pricingController = require("../controllers/pricingController");

// Public User App endpoint to calculate estimated fares
router.post("/estimate-fare", pricingController.estimateFare);

// Admin Panel endpoints to get & update pricing configurations
router.get("/configs", pricingController.getPricingConfigs);
router.put("/config/:id", pricingController.updatePricingConfig);
router.post("/seed", pricingController.seedInitialPricing);

module.exports = router;
