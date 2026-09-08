const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    fromId: { type: mongoose.Schema.Types.ObjectId, required: true },
    toId: { type: mongoose.Schema.Types.ObjectId, required: true },
    onModel: {
        type: String,
        required: true,
        enum: ['User', 'Driver']
    },
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: String
}, { timestamps: true });

module.exports = mongoose.model('Review', reviewSchema);
