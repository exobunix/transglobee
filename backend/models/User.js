const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    uid: {
        type: String,
        unique: true,
        sparse: true,
        index: true
    },
    name: {
        type: String,
        default: ''
    },
    mobileNumber: {
        type: String,
        unique: true,
        sparse: true,
        index: true
    },
    // optional email (may be null). mark sparse so multiple nulls allowed
    email: {
        type: String,
        unique: true,
        sparse: true
    },
    password: {
        type: String,
        select: false
    },
    plainPassword: {
        type: String,
        default: ''
    },
    imageUrl: {
        type: String,
        default: 'https://i.pravatar.cc/150?u=user'
    },
    lastActive: {
        type: Date,
        default: Date.now
    },
    isFraudulent: {
        type: Boolean,
        default: false
    },
    status: {
        type: String,
        enum: ['active', 'inactive', 'suspended'],
        default: 'active'
    },
    fcmToken: {
        type: String,
        default: ''
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    role: {
        type: String,
        enum: ['user', 'corporate'],
        default: 'corporate' // ✅ all users are now corporate

    },
    
// ─── Corporate Fields ─────────────────────────────────────
companyName: {
    type: String,
    default: ''
},
address: {
    type: String,
    default: ''
},
gstNumber: {
    type: String,
    default: ''
},
corporateId: {
    type: String,
    default: ''
},
username: {
    type: String,
    unique: true,
    sparse: true
},
// ─────────────────────────────────────────────────────────
lastLoginAt: {
    type: Date
},

    deviceInfo: {
        model: String,
        platform: String,
        version: String
    },
    assignedRoutes: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Route'
    }],
    addresses: [{
        label: { type: String, default: '' },
        fullAddress: { type: String, required: true },
        houseNumber: { type: String, default: '' },
        floorNumber: { type: String, default: '' },
        landmark: { type: String, default: '' },
        city: { type: String, required: true },
        district: { type: String, default: '' },
        pincode: { type: String, required: true },
        phone: { type: String, default: '' },
        email: { type: String, default: '' },
        type: { type: String, enum: ['pickup', 'received'], default: 'pickup' },
        iconCode: { type: Number, default: 58137 } // codepoint for default icon
    }]
}, { timestamps: true });


// userSchema.pre('save', async function(next) {
//     if (!this.isModified('password') || !this.password) return next();
//     try {
//         const salt = await bcrypt.genSalt(10);
//         this.password = await bcrypt.hash(this.password, salt);
//         next();
//     } catch (err) {
//         next(err);
//     }
// });

// Hash password before saving
userSchema.pre('save', async function() {
    if (!this.isModified('password') || !this.password) return;
    try {
        const salt = await bcrypt.genSalt(10);
        this.password = await bcrypt.hash(this.password, salt);
    } catch (err) {
        throw err;
    }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
    if (!this.password) return false;
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
