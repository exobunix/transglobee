const mongoose = require('mongoose');

const delayLogSchema = new mongoose.Schema({
    bookingId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Booking',
        required: true
    },
    reason: {
        type: String,
        required: true
    },
    delayMinutes: {
        type: Number,
        required: true
    },
    notes: String
}, { timestamps: true });

module.exports = mongoose.model('DelayLog', delayLogSchema);
