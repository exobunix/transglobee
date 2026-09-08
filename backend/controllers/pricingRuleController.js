const PricingRule = require('../models/PricingRule');

const activeFilter = (query = {}) => {
    const filter = {};
    if (query.active !== undefined) filter.isActive = String(query.active) === 'true';
    if (query.city) filter.applicableCities = query.city;
    return filter;
};

exports.createRule = async (req, res) => {
    try {
        const rule = await PricingRule.create(req.body);
        return res.status(201).json({ success: true, message: 'Pricing rule created', rule });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getRules = async (req, res) => {
    try {
        const rules = await PricingRule.find(activeFilter(req.query)).sort({ createdAt: -1 });
        return res.json({ success: true, rules });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.updateRule = async (req, res) => {
    try {
        const rule = await PricingRule.findByIdAndUpdate(req.params.ruleId, req.body, { new: true });
        if (!rule) return res.status(404).json({ success: false, message: 'Pricing rule not found.' });
        return res.json({ success: true, message: 'Pricing rule updated', rule });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.deleteRule = async (req, res) => {
    try {
        const rule = await PricingRule.findByIdAndDelete(req.params.ruleId);
        if (!rule) return res.status(404).json({ success: false, message: 'Pricing rule not found.' });
        return res.json({ success: true, message: 'Pricing rule deleted' });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getActiveSurgeMultiplier = async (city, vehicleType) => {
    const now = new Date();
    const day = now.getDay();
    const rule = await PricingRule.findOne({
        isActive: true,
        $and: [
            { $or: [{ applicableCities: city }, { applicableCities: { $size: 0 } }] },
            { $or: [{ applicableVehicles: vehicleType }, { applicableVehicles: { $size: 0 } }] },
            {
                $or: [
                    { startTime: { $lte: now }, endTime: { $gte: now } },
                    { dayOfWeek: day },
                    { festivalFlag: true },
                ],
            },
        ],
    }).sort({ multiplier: -1 });
    return rule ? rule.multiplier : 1;
};
