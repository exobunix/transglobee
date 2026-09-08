const mongoose = require('mongoose');

const stopSchema = new mongoose.Schema({
    name: { type: String, required: true },
    lat: Number,
    lng: Number,
    order: Number,
}, { _id: false });

const departureSchema = new mongoose.Schema({
    departureTime: { type: String, required: true },
    totalSeats: { type: Number, default: 20 },
    price: { type: Number, default: 0 },
}, { _id: false });

const shuttleRouteSchema = new mongoose.Schema({
    routeName: { type: String, required: true },
    city: { type: String, default: 'Delhi' },
    origin: String,
    destination: String,
    stops: { type: [stopSchema], default: [] },
    departures: { type: [departureSchema], default: [] },
    totalDistanceKm: { type: Number, default: 0 },
    estimatedDurationMin: { type: Number, default: 0 },
    basePrice: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('ShuttleRoute', shuttleRouteSchema);
