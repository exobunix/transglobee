const mongoose = require("mongoose");

const locationPointSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ["pickup", "dropoff", "stop"],
        required: true
    },
    title: String,
    address: String,
    latitude: {
        type: Number,
        required: true
    },
    longitude: {
        type: Number,
        required: true
    }
}, { _id: false });

const historySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    mobileNumber: {
        type: String,
    },
    locations: [locationPointSchema],
    rideMode: {
        type: String,
        required: true
    },
    paymentMode: {
        type: String,
        default: "cash"
    },
    distance: {
        type: String,
    },
    fare: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ["pending", "accepted", "on_the_way", "ongoing", "completed", "cancelled", "rejected", "arrived"],
        default: "pending"
    },
    otp: {
        type: String
    },
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Driver"
    },
    driverSnapshot: {
        type: new mongoose.Schema({
            driver_id: mongoose.Schema.Types.ObjectId,
            name: String,
            phone: String,
            vehicle_number: String,
            vehicle_name: String,
            photo: String
        }, { _id: false }),
        default: null
    },
    driverActionAt: {
        type: Date
    },
    rejectedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: "Driver"
    }],
    paymentStatus: {
        type: String,
        enum: ["unpaid", "paid"],
        default: "unpaid"
    },
    vehicleType: {
        type: String
    },
    typeOfGood: {
        type: String
    },
    helperCount: {
        type: Number,
        default: 0
    },
    logisticItems: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'LogisticGood'
    }],
    routeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Route',
        default: null
    },
    discountAmount: {
        type: Number,
        default: 0
    },
    appliedCoupon: {
        type: String,
        default: null
    },
    cancelReason: {
        type: String,
        default: ""
    },
    distanceTravelled: {
        type: Number,
        default: 0
    },
    cancelledMidRide: {
        type: Boolean,
        default: false
    },
    cancellationFare: {
        type: Number,
        default: 0
    }
}, { timestamps: true });


module.exports = mongoose.model("History", historySchema);
