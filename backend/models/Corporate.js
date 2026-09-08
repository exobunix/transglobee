const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const corporateSchema = new mongoose.Schema({
    companyName: {
        type: String,
        required: true,
        unique: true
    },
    gstin: {
        type: String,
        required: true,
        unique: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    contactPhone: {
        type: String,
        required: true
    },
    address: {
        type: String,
        required: true
    },
    creditLimit: {
        type: Number,
        default: 0
    },
    currentBalance: {
        type: Number,
        default: 0
    },
    paymentTermsDays: {
        type: Number,
        default: 30
    },
    accountManagerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Admin'
    },
    status: {
        type: String,
        enum: ['active', 'inactive', 'on_hold'],
        default: 'active'
    },
    role: {
        type: String,
        default: 'corporate'
    },
    password: {
        type: String,
        required: true
    }
}, { timestamps: true });

corporateSchema.pre('save', async function () {
    if (!this.isModified('password')) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

corporateSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Corporate', corporateSchema);
