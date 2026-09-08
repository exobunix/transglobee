const mongoose = require('mongoose');

const logisticGoodSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true
    },
    itemName: {
        type: String,
        required: true
    },
    type: {
        type: String, // Furniture, Electronics, etc.
        required: true
    },
    length: {
        type: Number,
        required: true
    },
    height: {
        type: Number,
        required: true
    },
    width: {
        type: Number,
        required: true
    },
    image: {
        type: String, // URL to the uploaded image
    }
}, { timestamps: true });

module.exports = mongoose.model('LogisticGood', logisticGoodSchema);
