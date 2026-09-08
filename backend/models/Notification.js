const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    userId: { type: String, index: true },
    role: { type: String, default: 'user' },
    title: { type: String, required: true },
    body: { type: String, default: '' },
    type: { type: String, default: 'general' },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    isRead: { type: Boolean, default: false },
    readAt: Date,
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
