const mongoose = require('mongoose');

const paymentGatewayConfigSchema = new mongoose.Schema({
    gateway: {
        type: String,
        enum: ['razorpay', 'stripe', 'cashfree'],
        default: 'razorpay'
    },
    keyId: {
        type: String,
        default: ''
    },
    keySecret: {
        type: String,
        default: ''
    },
    webhookSecret: {
        type: String,
        default: ''
    },
    isEnabled: {
        type: Boolean,
        default: false
    },
    currency: {
        type: String,
        default: 'INR'
    },
    testMode: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model('PaymentGatewayConfig', paymentGatewayConfigSchema);
