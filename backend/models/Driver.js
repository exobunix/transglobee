const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const driverSchema = new mongoose.Schema({
    uid: {
        type: String,
        required: false, // Make optional for custom registration
        unique: true,
        sparse: true
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
    password: {
        type: String,
        required: false // Optional for social/UID-based logins
    },
    mobileNumber: {
        type: String,
        unique: true,
        sparse: true
    },
    status: {
        type: String,
        enum: ['pending', 'active', 'suspended'],
        default: 'pending'
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    photo: {
        type: String,
        default: ''
    },
    aadharCard: {
        type: String,
        default: ''
    },
    drivingLicense: {
        type: String,
        default: ''
    },
    aadharCardNumber: {
        type: String,
        default: ''
    },
    drivingLicenseNumber: {
        type: String,
        default: ''
    },
    panCardNumber: {
        type: String,
        default: ''
    },
    vehicleNumberPlate: {
        type: String,
        default: ''
    },
    vehicleModel: {
        type: String,
        default: ''
    },
    signature: {
        type: String,
        default: ''
    },
    vehicleYear: {
        type: String,
        default: ''
    },
    panVerified: {
        type: Boolean,
        default: false
    },
    aadharVerified: {
        type: Boolean,
        default: false
    },
    drivingLicenseVerified: {
        type: Boolean,
        default: false
    },
    isEmailVerified: {
        type: Boolean,
        default: false
    },
    dob: {
        type: Date
    },
    warningCount: {
        type: Number,
        default: 0
    },
    lastWarningReason: {
        type: String,
        default: ''
    },
    lastWarningDate: {
        type: Date
    },
    fcmToken: {
        type: String,
        default: ''
    },
    isOnline: {
        type: Boolean,
        default: false
    },
    panCardImage: {
        type: String,
        default: ''
    },
    rcBook: {
        type: String,
        default: ''
    },
    insurance: {
        type: String,
        default: ''
    },
    role: {
        type: String,
        default: 'driver'
    },
    isApproved: {
        type: Boolean,
        default: false
    },
    lastLoginAt: {
        type: Date
    },
    deviceInfo: {
        model: String,
        platform: String,
        version: String
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point',
        },
        coordinates: {
            type: [Number],
            default: undefined,
        },
    },
}, { timestamps: true });

driverSchema.index({ location: '2dsphere' });

// Pre-save hook to hash password
driverSchema.pre('save', async function () {
    if (!this.password || !this.isModified('password')) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare passwords
driverSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Driver', driverSchema);
