const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'resolved', 'ignored'],
        default: 'pending'
    },
    severity: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'low'
    }
}, { timestamps: true });

module.exports = mongoose.model('Complaint', complaintSchema);
