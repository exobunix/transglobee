const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
    name: { type: String, required: true },
    source: String,
    destination: String,
    startLocation: String,
    endLocation: String,
    startLat: Number,
    startLng: Number,
    endLat: Number,
    endLng: Number,
    stops: [{
        name: String,
        coordinates: { lat: Number, lng: Number },
        estimatedTimeFromStart: Number // in minutes
    }],
    distance: Number, // in Km
    estimatedDuration: Number, // in minutes
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Route', routeSchema);
