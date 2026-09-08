const AdminSignup = require('../models/adminSignup');
const User = require('../models/User');
const Driver = require('../models/Driver');

// Get all sub-admins
exports.getSubAdmins = async (req, res) => {
    try {
        const subAdmins = await AdminSignup.find().select('-password -token').sort({ createdAt: -1 });
        res.status(200).json({ success: true, subAdmins });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Create a new sub-admin
exports.createSubAdmin = async (req, res) => {
    try {
        const { name, email, password, role, allowedModules } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ success: false, message: 'Name, email, and password are required.' });
        }

        const existing = await AdminSignup.findOne({ email: email.toLowerCase().trim() });
        if (existing) {
            return res.status(400).json({ success: false, message: 'An admin account with this email already exists.' });
        }

        const newSubAdmin = new AdminSignup({
            name,
            email: email.toLowerCase().trim(),
            password,
            role: role || 'admin',
            allowedModules: allowedModules || [],
            isSubAdmin: true,
            plainPassword: password
        });

        await newSubAdmin.save();

        res.status(201).json({
            success: true,
            message: 'Sub-admin created successfully.',
            admin: {
                id: newSubAdmin._id,
                name: newSubAdmin.name,
                email: newSubAdmin.email,
                role: newSubAdmin.role,
                allowedModules: newSubAdmin.allowedModules,
                plainPassword: newSubAdmin.plainPassword
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update sub-admin details/permissions
exports.updateSubAdmin = async (req, res) => {
    try {
        const { name, email, role, allowedModules, password } = req.body;
        const subAdmin = await AdminSignup.findById(req.params.id);

        if (!subAdmin) {
            return res.status(404).json({ success: false, message: 'Sub-admin not found.' });
        }

        if (name) subAdmin.name = name;
        if (email) subAdmin.email = email.toLowerCase().trim();
        if (role) subAdmin.role = role;
        if (allowedModules) subAdmin.allowedModules = allowedModules;
        if (password) {
            subAdmin.password = password;
            subAdmin.plainPassword = password;
        }

        await subAdmin.save();

        res.status(200).json({
            success: true,
            message: 'Sub-admin updated successfully.',
            admin: {
                id: subAdmin._id,
                name: subAdmin.name,
                email: subAdmin.email,
                role: subAdmin.role,
                allowedModules: subAdmin.allowedModules,
                plainPassword: subAdmin.plainPassword
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Delete sub-admin
exports.deleteSubAdmin = async (req, res) => {
    try {
        const subAdmin = await AdminSignup.findById(req.params.id);
        if (!subAdmin) {
            return res.status(404).json({ success: false, message: 'Sub-admin not found.' });
        }

        await AdminSignup.findByIdAndDelete(req.params.id);
        res.status(200).json({ success: true, message: 'Sub-admin access revoked successfully.' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get importable users & drivers list
exports.getImportableUsersAndDrivers = async (req, res) => {
    try {
        const [users, drivers] = await Promise.all([
            User.find({}, 'name email mobileNumber').sort({ name: 1 }).lean(),
            Driver.find({}, 'name email mobileNumber').sort({ name: 1 }).lean()
        ]);

        res.status(200).json({
            success: true,
            users: users.filter(u => u.email), // Filter users with email addresses
            drivers: drivers.filter(d => d.email) // Filter drivers with email addresses
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
