const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Driver' },
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    amount: { type: Number, required: true },
    type: {
        type: String,
        enum: ['payment', 'commission', 'withdrawal', 'refund', 'incentive'],
        required: true
    },
    method: {
        type: String,
        enum: ['wallet', 'card', 'upi', 'cash'],
        default: 'wallet'
    },
    status: {
        type: String,
        enum: ['pending', 'completed', 'failed', 'refunded'],
        default: 'pending'
    },
    adminCommission: Number,
    driverEarnings: Number,
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    }
}, { timestamps: true });

module.exports = mongoose.model('Transaction', transactionSchema);
