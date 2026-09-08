const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({

    // ─── Basic Details ────────────────────────────────────────
    vehicleType: {
        type: String,
        enum: ['car', 'bus', 'truck'],
        required: true
    },
    vehicleName: {
        type: String,
        required: true
    },
    brand: {
        type: String,
        default: ''
    },
    model: {
        type: String,
        default: ''
    },
    year: {
        type: String,
        default: ''
    },
    numberPlate: {
        type: String,
        required: true,
        unique: true
    },

    // ─── Capacity ─────────────────────────────────────────────
    passengerCapacity: {
        type: Number,
        default: 0
    },
    luggageCapacity: {
        type: Number,
        default: 0
    },
    truckLoadCapacity: {
        type: Number,    // in tonnes — for trucks only
        default: 0
    },

    // ─── Photos ───────────────────────────────────────────────
    photos: [{
        type: String    // array of image URLs
    }],
    vehicleImage: {
        type: String,
        default: ''
    },

    // ─── Documents ────────────────────────────────────────────
    documents: {
        rc: {
            url:      { type: String, default: '' },
            verified: { type: Boolean, default: false }
        },
        insurance: {
            url:      { type: String, default: '' },
            verified: { type: Boolean, default: false }
        },
        permit: {
            url:      { type: String, default: '' },
            verified: { type: Boolean, default: false }
        },
        fitness: {
            url:      { type: String, default: '' },
            verified: { type: Boolean, default: false }
        }
    },

    // ─── Pricing ──────────────────────────────────────────────
    pricing: {
        pricePerKm:           { type: Number, default: 0 },
        driverCharge:         { type: Number, default: 0 },
        tollTax:              { type: Number, default: 0 },
        nightCharges:         { type: Number, default: 0 },
        waitingCharges:       { type: Number, default: 0 },
        parkingCharges:       { type: Number, default: 0 },
        loadingUnloadingCharges: { type: Number, default: 0 },
        extraHourCharges:     { type: Number, default: 0 },
        stateTax:             { type: Number, default: 0 },
        convenienceCharges:   { type: Number, default: 0 },
        fixedPrice:           { type: Number, default: 0 },
        isFixedPrice:         { type: Boolean, default: false }
    },

    // ─── Routes assigned to this vehicle ─────────────────────
    routes: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Route'
    }],

    // ─── Driver assigned ──────────────────────────────────────
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        default: null
    },

    // ─── Status ───────────────────────────────────────────────
    status: {
        type: String,
        enum: ['active', 'inactive', 'maintenance'],
        default: 'active'
    },
    isEnabled: {
        type: Boolean,
        default: true
    },

    // ─── Location ─────────────────────────────────────────────
    currentLocation: {
        lat:         { type: Number, default: 0 },
        lng:         { type: Number, default: 0 },
        lastUpdated: { type: Date, default: Date.now }
    }

}, { timestamps: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);