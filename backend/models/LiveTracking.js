const mongoose = require('mongoose');

const liveTrackingSchema = new mongoose.Schema({

    bookingId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'LogisticsBooking',
        required: true
    },

    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        required: true
    },

    latitude: {
        type: Number,
        required: true
    },

    longitude: {
        type: Number,
        required: true
    },

    heading: {
        type: Number,
        default: 0
    },

    speed: {
        type: Number,
        default: 0
    },

    status: {
        type: String,
        enum: ['online', 'offline', 'moving', 'stopped'],
        default: 'online'
    },

    lastUpdated: {
        type: Date,
        default: Date.now
    }

}, { timestamps: true });

module.exports = mongoose.model('LiveTracking', liveTrackingSchema);