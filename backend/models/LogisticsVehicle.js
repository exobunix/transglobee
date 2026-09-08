const mongoose = require('mongoose');

const logisticsVehicleSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    capacity: {
        type: String,
        required: true
    },
    basePrice: {
        type: Number,
        required: true
    },
    pricePerKm: {
        type: Number,
        required: true,
        default: 10
    },
    pricePerPiece: {
        type: Number,
        default: 50
    },
    imageUrl: {
        type: String,
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model('LogisticsVehicle', logisticsVehicleSchema);
