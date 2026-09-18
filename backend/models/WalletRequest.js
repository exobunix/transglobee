const mongoose = require('mongoose');

const walletRequestSchema = new mongoose.Schema({
    userType: {
        type: String,
        enum: ['user', 'driver'],
        required: true,
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
    },
    userName: {
        type: String,
        default: 'Unknown',
    },
    userPhone: {
        type: String,
        default: '',
    },
    userEmail: {
        type: String,
        default: '',
    },
    amount: {
        type: Number,
        required: true,
        min: 1,
    },
    paymentMethod: {
        type: String,
        default: 'upi',
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending',
    },
    transactionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Transaction',
    },
    adminNote: {
        type: String,
        default: '',
    },
    actionBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Admin',
    },
    actionAt: {
        type: Date,
    },
}, { timestamps: true });

module.exports = mongoose.model('WalletRequest', walletRequestSchema);
