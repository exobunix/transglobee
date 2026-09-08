const mongoose = require("mongoose");

const RideTypeSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    description: {
        type: String
    },
    icon: {
        type: String
    },
    baseFare: {
        type: Number,
        required: true
    },
    pricePerKm: {
        type: Number,
        required: true
    },
    waitingTime: {
        type: String
    },
    status: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

module.exports = mongoose.model("RideType", RideTypeSchema);
