const mongoose = require('mongoose');

const transglobeBookingSchema = new mongoose.Schema({

    // ─── User who booked ─────────────────────────────────────
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },

    // ─── Vehicle booked ──────────────────────────────────────
    vehicleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Vehicle',
        required: true
    },

    vehicleType: {
        type: String,
        enum: ['car', 'bus', 'truck'],
        required: true
    },

    // ─── Trip Details ─────────────────────────────────────────
    pickupLocation: {
        type: String,
        required: true
    },
    dropLocation: {
        type: String,
        required: true
    },
    travelDate: {
        type: Date,
        required: true
    },
    travelTime: {
        type: String,  // e.g. "08:00 AM"
        required: true
    },
    numberOfPassengers: {
        type: Number,
        default: 1
    },
    purpose: {
        type: String,
        default: ''
    },
    specialInstructions: {
        type: String,
        default: ''
    },

    // ─── Pricing Snapshot ────────────────────────────────────
    estimatedFare: {
        type: Number,
        default: 0
    },
    distance: {
        type: Number,   // in km
        default: 0
    },
    pricingBreakdown: {
        pricePerKm:              { type: Number, default: 0 },
        driverCharge:            { type: Number, default: 0 },
        tollTax:                 { type: Number, default: 0 },
        nightCharges:            { type: Number, default: 0 },
        waitingCharges:          { type: Number, default: 0 },
        parkingCharges:          { type: Number, default: 0 },
        loadingUnloadingCharges: { type: Number, default: 0 },
        convenienceCharges:      { type: Number, default: 0 },
        stateTax:                { type: Number, default: 0 }
    },

    // ─── Booking Status ───────────────────────────────────────
    status: {
        type: String,
        enum: [
            'pending',      // just booked
            'approved',     // admin approved
            'assigned',     // driver assigned
            'in_progress',  // trip started
            'completed',    // trip done
            'cancelled'     // cancelled
        ],
        default: 'pending'
    },

    // ─── Driver assigned by admin ─────────────────────────────
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        default: null
    },

    // ─── Payment ──────────────────────────────────────────────
    paymentStatus: {
        type: String,
        enum: ['unpaid', 'paid'],
        default: 'unpaid'
    },
    paymentMethod: {
        type: String,
        enum: ['cash', 'upi', 'card', 'wallet'],
        default: 'cash'
    },

    // ─── Admin notes ─────────────────────────────────────────
    adminNotes: {
        type: String,
        default: ''
    },

    cancelReason: {
        type: String,
        default: ''
    }

}, { timestamps: true });

module.exports = mongoose.model('TransglobeBooking', transglobeBookingSchema);