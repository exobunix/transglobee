const mongoose = require("mongoose");

const locationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    mobileNumber: {
        type: String,
        required: true
    },
    title: String,
    address: String,
    latitude: Number,
    longitude: Number,
    type: String // pickup, dropoff, current_location, home, office
}, { timestamps: true });

module.exports = mongoose.model("Location", locationSchema);
