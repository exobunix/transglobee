const mongoose = require('mongoose');

const pricingRuleSchema = new mongoose.Schema({
    ruleName: { type: String, required: true },
    multiplier: { type: Number, required: true, min: 1, max: 3 },
    startTime: Date,
    endTime: Date,
    dayOfWeek: [{ type: Number, min: 0, max: 6 }],
    festivalFlag: { type: Boolean, default: false },
    applicableVehicles: [{ type: String }],
    applicableCities: [{ type: String }],
    isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('PricingRule', pricingRuleSchema);
