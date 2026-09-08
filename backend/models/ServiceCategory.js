const mongoose = require('mongoose');

const serviceCategorySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    type: {
        type: String,
        enum: ['cab', 'truck', 'bus'],
        required: true
    },
    baseFare: {
        type: Number,
        required: true
    },
    perKmCharge: {
        type: Number,
        required: true
    },
    perMinCharge: {
        type: Number,
        default: 0
    },
    commissionRate: {
        type: Number, // Percentage
        default: 10
    },
    capacity: {
        type: Number,
        required: true
    },
    description: String,
    isActive: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model('ServiceCategory', serviceCategorySchema);
