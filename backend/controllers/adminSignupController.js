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
        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required.' });
        }

        const cleanEmail = email.trim();
        const admin = await AdminSignup.findOne({ 
            email: { $regex: new RegExp(`^${cleanEmail.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')}$`, 'i') } 
        });

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

// Get Profile Controller (Excludes permanent admin, returns working admin: admin@transglobe.com)
exports.getProfile = async (req, res) => {
    try {
        let admin = null;
        if (req.user?.adminId) {
            admin = await AdminSignup.findById(req.user.adminId).select('-password -token');
        }
        if (!admin && req.user?.id) {
            admin = await AdminSignup.findById(req.user.id).select('-password -token');
        }
        // Always prioritize the active working admin, never display permanent admin in profile screen
        if (!admin || admin.isPermanentAdmin) {
            admin = await AdminSignup.findOne({ email: 'admin@transglobe.com' }).select('-password -token');
        }
        if (!admin) {
            admin = await AdminSignup.findOne({ isPermanentAdmin: { $ne: true } }).select('-password -token');
        }
        if (!admin) {
            return res.status(404).json({ success: false, message: 'Admin not found.' });
        }
        res.status(200).json({ 
            success: true, 
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                contactNumber: admin.contactNumber || '9876543210',
                profilePhoto: admin.profilePhoto || '',
                plainPassword: admin.plainPassword || 'Transglobe@9967',
                role: admin.role,
            }
        });
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update Profile Photo
exports.updateProfilePhoto = async (req, res) => {
    try {
        const adminId = req.user?.id;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ message: 'No file uploaded.' });
        }

        let admin = adminId ? await AdminSignup.findById(adminId) : null;
        if (!admin || admin.isPermanentAdmin) {
            admin = await AdminSignup.findOne({ email: 'admin@transglobe.com' });
        }
        if (!admin) {
            admin = await AdminSignup.findOne({ isPermanentAdmin: { $ne: true } });
        }
        if (!admin) {
            return res.status(404).json({ message: 'Admin not found.' });
        }

        // Upload to ImageKit
        imagekit.upload({
            file: file.buffer,
            fileName: `admin_${admin._id}_${Date.now()}`,
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

// Change Password Controller - Directly sets new password in MongoDB database
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword, password } = req.body;
        const passToSet = newPassword || password;

        if (!passToSet || passToSet.toString().trim().length < 4) {
            return res.status(400).json({ success: false, message: 'Password must be at least 4 characters long.' });
        }

        let admin = null;
        if (req.user?.adminId) {
            admin = await AdminSignup.findById(req.user.adminId);
        }
        if (!admin && req.user?.id) {
            admin = await AdminSignup.findById(req.user.id);
        }
        if (!admin || admin.isPermanentAdmin) {
            admin = await AdminSignup.findOne({ email: 'admin@transglobe.com' });
        }
        if (!admin) {
            admin = await AdminSignup.findOne({ isPermanentAdmin: { $ne: true } });
        }

        if (!admin) {
            return res.status(404).json({ success: false, message: 'Admin not found.' });
        }

        // Set new password (pre-save hook will hash it and update plainPassword)
        admin.password = passToSet.toString().trim();
        admin.plainPassword = passToSet.toString().trim();
        await admin.save();

        res.status(200).json({ success: true, message: 'Password updated successfully in database.' });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Update Profile details (name, email, contactNumber, photo/image, password)
exports.updateProfile = async (req, res) => {
    try {
        const { name, email, contactNumber, photo, image, password } = req.body;
        let admin = null;
        if (req.user?.adminId) {
            admin = await AdminSignup.findById(req.user.adminId);
        }
        if (!admin && req.user?.id) {
            admin = await AdminSignup.findById(req.user.id);
        }
        if (!admin || admin.isPermanentAdmin) {
            admin = await AdminSignup.findOne({ email: 'admin@transglobe.com' });
        }
        if (!admin) {
            admin = await AdminSignup.findOne({ isPermanentAdmin: { $ne: true } });
        }

        if (!admin) {
            return res.status(404).json({ success: false, message: 'Admin not found.' });
        }

        if (name && name.toString().trim().length > 0) admin.name = name.toString().trim();
        if (email && email.toString().trim().length > 0) admin.email = email.toString().trim();
        if (contactNumber) admin.contactNumber = contactNumber.toString().trim();
        const photoUrl = photo || image;
        if (photoUrl) admin.profilePhoto = photoUrl;
        if (password && password.toString().trim().length > 0) {
            admin.password = password.toString().trim();
            admin.plainPassword = password.toString().trim();
        }

        await admin.save();

        return res.status(200).json({
            success: true,
            message: 'Profile updated successfully in database.',
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                contactNumber: admin.contactNumber,
                profilePhoto: admin.profilePhoto,
                plainPassword: admin.plainPassword || '',
            }
        });
    } catch (error) {
        console.error('Update profile error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
