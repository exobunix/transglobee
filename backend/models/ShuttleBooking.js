const mongoose = require('mongoose');

// ─── Sub-schemas (matching LogisticsBooking) ─────────────
const locationSchema = new mongoose.Schema({
    name:    { type: String },
    address: { type: String },
    lat:     { type: Number },
    lng:     { type: Number },
}, { _id: false });

const shuttleBookingSchema = new mongoose.Schema({
    userId: { type: String, required: true, index: true },
    userName: { type: String, default: "" },
    userPhone: { type: String, default: "" },
    routeId: { type: mongoose.Schema.Types.ObjectId, ref: 'ShuttleRoute', required: true },
    departureTime: { type: String, required: true },
    date: { type: String, required: true },
    seatCount: { type: Number, required: true, min: 1 },
    paymentMethod: { type: String, enum: ['upi', 'card', 'wallet', 'cash'], default: 'upi' },
    totalPrice: { type: Number, default: 0 },
    
    // Status (expanded to match LogisticsBooking workflow)
    status: {
        type: String,
        enum: ['pending', 'claimed', 'pending_for_driver', 'processing', 'confirmed', 'in_transit', 'delivered', 'cancelled', 'completed', 'booked'],
        default: 'pending',
    },
    claimedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Admin',
        default: null,
    },
    claimedAt: {
        type: Date,
        default: null,
    },
    roadmapStatus: {
        type: String,
        enum: ['draft', 'approved', 'accepted', 'rejected'],
        default: 'draft',
    },
    vehicleType: { type: String, default: 'Shuttle' },

    pickup: { type: locationSchema, required: true },
    dropoff: { type: locationSchema, required: true },

    // Assigned Driver
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        default: null,
    },
    driverSnapshot: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
    },

    // Multi-Segment Roadmap (Supervisor/Admin Controlled)
    segments: [{
        start:           { type: locationSchema },
        end:             { type: locationSchema },
        mode:            { type: String, enum: ['Road', 'Train', 'Flight', 'Sea Cargo'], default: 'Road' },
        distanceKm:      { type: Number, default: 0 },
        driverId:        { type: mongoose.Schema.Types.ObjectId, ref: 'Driver', default: null },
        transportName:   { type: String },
        transportNumber: { type: String },
        estimatedTime:   { type: String },
        estimatedDate:   { type: String },
        status: { 
            type: String, 
            enum: ['pending', 'processing', 'completed'], 
            default: 'pending' 
        },
        price:           { type: Number, default: 0 },
        otp:             { type: String, default: () => Math.floor(1000 + Math.random() * 9000).toString() }
    }],

    currentLocation: {
        lat: Number,
        lng: Number,
        updatedAt: Date,
    },

    // Track drivers who rejected this booking
    rejectedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
    }],
    
    otp: {
        type: String,
        default: null,
    },
}, { timestamps: true });

module.exports = mongoose.model('ShuttleBooking', shuttleBookingSchema);
