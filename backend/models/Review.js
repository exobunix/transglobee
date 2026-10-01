const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    bookingId: { type: mongoose.Schema.Types.Mixed, required: true },
    fromId: { type: mongoose.Schema.Types.Mixed, required: true },
    toId: { type: mongoose.Schema.Types.Mixed, required: true },
    onModel: {
        type: String,
        enum: ['User', 'Driver'],
        default: 'Driver'
    },
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: { type: String, default: '' },
    tags: [{ type: String }]
}, { timestamps: true });

module.exports = mongoose.model('Review', reviewSchema);
