const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSignupSchema = new mongoose.Schema({
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
        required: true
    },
    token: {
        type: String, // Saving token in MongoDB as requested
        default: null
    },
    role: {
        type: String,
        enum: ['superadmin', 'admin', 'moderator', 'supervisor'],
        default: 'admin'
    },
    profilePhoto: {
        type: String,
        default: ''
    },
    allowedModules: {
        type: [String],
        default: []
    },
    isSubAdmin: {
        type: Boolean,
        default: false
    },
    plainPassword: {
        type: String,
        default: ''
    }
}, { timestamps: true });

// Pre-save hook to hash password
adminSignupSchema.pre('save', async function () {
    if (!this.isModified('password')) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare passwords
adminSignupSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('AdminSignup', adminSignupSchema);
