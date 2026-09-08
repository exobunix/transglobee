const mongoose = require('mongoose');

const cmsSchema = new mongoose.Schema({
    key: {
        type: String,
        required: true,
        unique: true
    },
    value: {
        type: mongoose.Schema.Types.Mixed,
        required: true
    },
    type: {
        type: String, // 'faq', 'terms', 'banner', 'notification'
        required: true
    }
}, { timestamps: true });

module.exports = mongoose.model('CMS', cmsSchema);
