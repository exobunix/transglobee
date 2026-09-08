const mongoose = require('mongoose');

// ─── Pricing Configuration Model ─────────────────────────
// Stores city-wise, mode-wise pricing rules for dynamic fare calculation
const pricingConfigSchema = new mongoose.Schema({

    // Identifier
    name: { type: String, required: true, unique: true }, // e.g. "Default", "Mumbai", "Delhi"
    city: { type: String, default: 'All' },
    isActive: { type: Boolean, default: true },

    // ─── Base Fare Components ────────────────────────────
    baseFare: { type: Number, default: 0 },           // Fixed base charge
    perKmCharge: { type: Number, default: 0 },        // Per km rate
    perMinuteCharge: { type: Number, default: 0 },    // Per minute rate (waiting/travel)
    minimumFare: { type: Number, default: 0 },        // Minimum fare floor

    // ─── Wait & Extra Charges ────────────────────────────
    waitingChargePerMin: { type: Number, default: 0 },
    freeWaitingMinutes: { type: Number, default: 5 },

    // ─── Time-based Surcharges ───────────────────────────
    nightChargeMultiplier: { type: Number, default: 1.0 },  // e.g. 1.25 = 25% night surcharge
    nightStartHour: { type: Number, default: 22 },           // 10 PM
    nightEndHour: { type: Number, default: 6 },              // 6 AM
    peakHourMultiplier: { type: Number, default: 1.0 },      // Surge pricing multiplier
    peakHours: [{
        start: { type: String }, // "08:00"
        end: { type: String },   // "10:00"
    }],

    // ─── Additional Charges ──────────────────────────────
    tollCharges: { type: Number, default: 0 },
    platformFeePercent: { type: Number, default: 0 },   // % of total fare
    gstPercent: { type: Number, default: 18 },           // GST %

    // ─── Logistics-specific Pricing ─────────────────────
    logistics: {
        baseFare: { type: Number, default: 0 },
        perKmCharge: { type: Number, default: 0 },
        helperCostPerPerson: { type: Number, default: 0 },

        // Weight-based (₹ per kg)
        weightTiers: [{
            minKg: { type: Number },
            maxKg: { type: Number },
            ratePerKg: { type: Number },
        }],

        // Volume-based (₹ per cubic cm)
        volumeRatePerCubicCm: { type: Number, default: 0 },

        // Transport mode surcharge (multiplier on base)
        modeMultipliers: {
            Road: { type: Number, default: 1.0 },
            Train: { type: Number, default: 0.8 },
            Flight: { type: Number, default: 2.0 },
            'Sea Cargo': { type: Number, default: 0.7 },
        },

        // Handling charges
        fragileHandlingCharge: { type: Number, default: 0 },
        bulkyItemSurcharge: { type: Number, default: 0 },
    },

    // ─── Commission ──────────────────────────────────────
    driverCommissionPercent: { type: Number, default: 80 },  // 80% to driver
    platformCommissionPercent: { type: Number, default: 20 }, // 20% to platform

}, { timestamps: true });

module.exports = mongoose.model('PricingConfig', pricingConfigSchema);
