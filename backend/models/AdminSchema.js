const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
    password: {
        type: String,
        required: true,
    },
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    role: {
        type: String,
        enum: ['superadmin', 'admin', 'moderator', 'supervisor'],
        default: 'admin'
    },
    status: {
        type: String,
        enum: ['active', 'inactive'],
        default: 'active'
    }
}, { timestamps: true });

module.exports = mongoose.model('Admin', adminSchema);
