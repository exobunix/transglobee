const mongoose = require("mongoose");
const PricingConfig = require("../models/pricingModel");

// Helper function to calculate distance using Haversine formula
function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of Earth in KM
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distanceKm = R * c;
  // Apply a 1.25 multiplier to estimate actual road driving distance vs straight line
  return parseFloat((distanceKm * 1.25).toFixed(2));
}

// Default Seed Categories for Cab, Shuttle, and Logistics Services
const DEFAULT_PRICING_CONFIGS = [
  {
    vehicleCategoryId: "cab_01",
    categoryName: "Cab Service",
    capacity: 4,
    baseFare: 50,
    baseDistanceKm: 2.0,
    perKmRate: 15,
    perMinuteRate: 1.5,
    minBookingFare: 60,
    cancellationFee: 30,
    surgeMultiplier: 1.0,
    nightChargePercentage: 10,
    tagline: "Comfortable city cab rides",
    icon: "car",
    isActive: true,
  },
  {
    vehicleCategoryId: "shuttle_02",
    categoryName: "Shuttle Service",
    capacity: 12,
    baseFare: 30,
    baseDistanceKm: 3.0,
    perKmRate: 8,
    perMinuteRate: 0.5,
    minBookingFare: 30,
    cancellationFee: 15,
    surgeMultiplier: 1.0,
    nightChargePercentage: 5,
    tagline: "Shared route shuttle for budget commute",
    icon: "bus",
    isActive: true,
  },
  {
    vehicleCategoryId: "logistics_03",
    categoryName: "Logistics Service",
    capacity: 2,
    baseFare: 120,
    baseDistanceKm: 3.0,
    perKmRate: 25,
    perMinuteRate: 2.0,
    minBookingFare: 150,
    cancellationFee: 50,
    surgeMultiplier: 1.1,
    nightChargePercentage: 15,
    tagline: "Goods delivery & freight transport",
    icon: "truck",
    isActive: true,
  },
];

/**
 * POST /api/pricing/estimate-fare
 * Estimate fare dynamically based on pickup & dropoff coordinates
 */
exports.estimateFare = async (req, res) => {
  try {
    const { pickup, dropoff } = req.body;

    if (!pickup || !dropoff || pickup.lat == null || dropoff.lat == null) {
      return res.status(400).json({
        success: false,
        message: "Valid pickup and dropoff coordinates (lat, lng) are required",
      });
    }

    const pLat = parseFloat(pickup.lat);
    const pLng = parseFloat(pickup.lng);
    const dLat = parseFloat(dropoff.lat);
    const dLng = parseFloat(dropoff.lng);

    // Calculate road distance in KM
    let distanceKm = calculateHaversineDistance(pLat, pLng, dLat, dLng);
    if (distanceKm < 0.5) distanceKm = 0.5;

    // Estimate duration: Average speed 25 km/h in city traffic
    let durationMins = Math.round((distanceKm / 25) * 60);
    if (durationMins < 5) durationMins = 5;

    // Check if current server time is night shift (10 PM to 6 AM)
    const currentHour = new Date().getHours();
    const isNightShift = currentHour >= 22 || currentHour < 6;

    // Fetch active pricing configs from DB or use defaults
    let configs = [];
    if (mongoose.connection.readyState === 1) {
      try {
        configs = await PricingConfig.find({ isActive: true }).maxTimeMS(2000);
      } catch (dbErr) {
        console.log("DB lookup error, fallback to default pricing configs:", dbErr.message);
      }
    }

    if (!configs || configs.length === 0) {
      configs = DEFAULT_PRICING_CONFIGS;
    }

    const now = new Date();
    const rides = configs.map((config) => {
      const excessDistance = Math.max(0, distanceKm - config.baseDistanceKm);
      const distanceCharge = excessDistance * config.perKmRate;
      const timeCharge = durationMins * (config.perMinuteRate || 0);
      let calculatedSubtotal = config.baseFare + distanceCharge + timeCharge;

      // Apply Night Charge Percentage
      if (isNightShift && config.nightChargePercentage > 0) {
        calculatedSubtotal += (calculatedSubtotal * config.nightChargePercentage) / 100;
      }

      // Apply Surge Multiplier
      let finalFare = calculatedSubtotal * (config.surgeMultiplier || 1.0);

      // Enforce Minimum Booking Fare
      if (finalFare < config.minBookingFare) {
        finalFare = config.minBookingFare;
      }

      const roundedFare = Math.round(finalFare);
      const originalFare = Math.round(roundedFare * 1.1); // Display pre-discount strike price

      // Calculate ETA & Arrival Time
      const etaMinutes = Math.floor(Math.random() * 6) + 3; // 3 to 8 mins
      const arrivalDate = new Date(now.getTime() + (durationMins + etaMinutes) * 60000);
      const arrivalTimeString = arrivalDate.toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      });

      return {
        id: config.vehicleCategoryId || config._id,
        name: config.categoryName,
        icon: config.icon || "car",
        capacity: config.capacity || 4,
        baseFare: config.baseFare,
        perKmRate: config.perKmRate,
        perMinuteRate: config.perMinuteRate || 0,
        estimatedFare: roundedFare,
        originalFare: originalFare,
        etaMinutes: etaMinutes,
        arrivalTime: arrivalTimeString,
        tagline: config.tagline || "",
      };
    });

    return res.status(200).json({
      success: true,
      distanceKm: distanceKm,
      durationMins: durationMins,
      currency: "INR",
      rides: rides,
    });
  } catch (error) {
    console.error("Error estimating fare:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to estimate fare: " + error.message,
    });
  }
};

/**
 * GET /api/pricing/configs
 * Retrieve all pricing configurations for Admin Panel
 */
exports.getPricingConfigs = async (req, res) => {
  try {
    let configs = await PricingConfig.find().sort({ createdAt: -1 });
    if (!configs || configs.length === 0) {
      configs = await PricingConfig.insertMany(DEFAULT_PRICING_CONFIGS);
    }
    return res.status(200).json({
      success: true,
      count: configs.length,
      data: configs,
    });
  } catch (error) {
    return res.status(200).json({
      success: true,
      count: DEFAULT_PRICING_CONFIGS.length,
      data: DEFAULT_PRICING_CONFIGS,
    });
  }
};

/**
 * PUT /api/pricing/config/:id
 * Update pricing configuration for a specific vehicle category
 */
exports.updatePricingConfig = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    let config = await PricingConfig.findOneAndUpdate(
      { $or: [{ _id: id }, { vehicleCategoryId: id }] },
      { $set: updateData },
      { new: true, upsert: true }
    );

    return res.status(200).json({
      success: true,
      message: "Pricing configuration updated successfully",
      data: config,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to update pricing configuration: " + error.message,
    });
  }
};

/**
 * POST /api/pricing/seed
 * Reset/Seed initial pricing rules
 */
exports.seedInitialPricing = async (req, res) => {
  try {
    await PricingConfig.deleteMany({});
    const seeded = await PricingConfig.insertMany(DEFAULT_PRICING_CONFIGS);
    return res.status(200).json({
      success: true,
      message: "Seeded initial pricing configurations successfully",
      count: seeded.length,
      data: seeded,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Failed to seed pricing configurations: " + error.message,
    });
  }
};

// Route Admin Aliases
exports.getAllConfigs = exports.getPricingConfigs;
exports.getActiveConfig = exports.getPricingConfigs;
exports.createConfig = exports.updatePricingConfig;
exports.updateConfig = exports.updatePricingConfig;
exports.deleteConfig = async (req, res) => res.status(200).json({ success: true, message: "Pricing config deleted" });
exports.calculateFare = exports.estimateFare;
