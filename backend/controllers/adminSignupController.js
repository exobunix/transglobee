const AdminSignup = require('../models/adminSignup');
const jwt = require('jsonwebtoken');
const imagekit = require('../config/imagekit');
const bcrypt = require('bcryptjs');

// Signup Controller
exports.signup = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Check for existing admin
        let existingAdmin = await AdminSignup.findOne({ email });

        if (existingAdmin) {
            return res.status(400).json({ message: 'Admin with this Email already exists.' });
        }

        const newAdmin = new AdminSignup({
            name,
            email,
            password
        });

        await newAdmin.save();

        res.status(201).json({
            message: 'Admin account created successfully.',
            admin: {
                id: newAdmin._id,
                name: newAdmin.name,
                email: newAdmin.email
            }
        });
    } catch (error) {
        console.error('Signup error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Login Controller
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const admin = await AdminSignup.findOne({ email });
        if (!admin) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const isMatch = await admin.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        // Generate Token
        const token = jwt.sign(
            { id: admin._id, email: admin.email, role: admin.role },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '1d' }
        );

        // Save token in MongoDB as requested
        admin.token = token;
        await admin.save();

        res.status(200).json({
            message: 'Login successful.',
            token, // Returning to client for storage in Preferences
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                role: admin.role,
                allowedModules: admin.allowedModules || [],
                isSubAdmin: admin.isSubAdmin || false
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Auth / Profile Controller
exports.auth = async (req, res) => {
    try {
        // The middleware would have placed the decoded user in req.user
        // But the user specifically asked for "auth" here and "token save in mongodb"
        // Let's verify the current token in req.body or headers matches one in DB

        let token = req.headers.authorization;
        if (token && token.startsWith('Bearer ')) {
            token = token.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ message: 'No token provided.' });
        }

        // Find admin with this token in DB
        const admin = await AdminSignup.findOne({ token });
        if (!admin) {
            return res.status(401).json({ message: 'Unauthorized: Invalid token or session expired.' });
        }

        res.status(200).json({
            message: 'Authenication valid.',
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                role: admin.role,
                allowedModules: admin.allowedModules || [],
                isSubAdmin: admin.isSubAdmin || false
            }
        });
    } catch (error) {
        console.error('Auth error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Logout Controller - Clear token from DB
exports.logout = async (req, res) => {
    try {
        let token = req.headers.authorization;
        if (token && token.startsWith('Bearer ')) {
            token = token.split(' ')[1];
        }

        if (token) {
            // Find and clear the specific token from the database
            const admin = await AdminSignup.findOne({ token });
            if (admin) {
                admin.token = null;
                await admin.save();
            }
        }

        res.status(200).json({ message: 'Logged out and session cleared.' });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
// Get Profile Controller
exports.getProfile = async (req, res) => {
    try {
        const admin = await AdminSignup.findById(req.user.id).select('-password -token');
        if (!admin) {
            return res.status(404).json({ message: 'Admin not found.' });
        }
        res.status(200).json({ admin });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update Profile Photo
exports.updateProfilePhoto = async (req, res) => {
    try {
        const adminId = req.user.id;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }

        const admin = await AdminSignup.findById(adminId);
        if (!admin) {
            return res.status(404).json({ message: 'Admin not found.' });
        }

        // Upload to ImageKit
        imagekit.upload({
            file: file.buffer,
            fileName: `admin_${adminId}_${Date.now()}`,
            folder: '/TRANSGLOBE/admin_profiles'
        }, async (error, result) => {
            if (error) {
                console.error('ImageKit upload error:', error);
                return res.status(500).json({ message: 'Upload failed.', error: error.message });
            }

            admin.profilePhoto = result.url;
            await admin.save();

            res.status(200).json({
                message: 'Profile photo updated successfully.',
                profilePhoto: result.url
            });
        });
    } catch (error) {
        console.error('Update photo error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Change Password Controller
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const adminId = req.user.id;

        const admin = await AdminSignup.findById(adminId);
        if (!admin) {
            return res.status(404).json({ message: 'Admin not found.' });
        }

        // Verify current password
        const isMatch = await admin.comparePassword(currentPassword);
        if (!isMatch) {
            return res.status(400).json({ message: 'Current password is incorrect.' });
        }

        // Set and save (pre-save hook will hash it)
        admin.password = newPassword;
        await admin.save();

        res.status(200).json({ message: 'Password updated successfully.' });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
