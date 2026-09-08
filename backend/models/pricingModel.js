const mongoose = require("mongoose");

const pricingConfigSchema = new mongoose.Schema(
  {
    vehicleCategoryId: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    categoryName: {
      type: String,
      required: true,
      trim: true,
    },
    capacity: {
      type: Number,
      default: 4,
    },
    baseFare: {
      type: Number,
      required: true,
      default: 50,
    },
    baseDistanceKm: {
      type: Number,
      required: true,
      default: 2.0,
    },
    perKmRate: {
      type: Number,
      required: true,
      default: 15,
    },
    perMinuteRate: {
      type: Number,
      default: 1.5,
    },
    minBookingFare: {
      type: Number,
      default: 60,
    },
    cancellationFee: {
      type: Number,
      default: 30,
    },
    surgeMultiplier: {
      type: Number,
      default: 1.0,
    },
    nightChargePercentage: {
      type: Number,
      default: 10, // 10% extra between 10 PM - 6 AM
    },
    tagline: {
      type: String,
      default: "Popular choice for daily rides",
    },
    icon: {
      type: String,
      default: "car",
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("PricingConfig", pricingConfigSchema);
