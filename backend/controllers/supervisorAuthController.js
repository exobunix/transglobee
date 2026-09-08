const AdminSignup = require('../models/adminSignup');
const jwt = require('jsonwebtoken');
const sessionBlacklist = require('../utils/sessionBlacklist');

// ─── POST /api/supervisor/auth/register ──────────────────────────────────────
// Create a new supervisor account (only superadmin should call this)
// ─────────────────────────────────────────────────────────────────────────────
exports.register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Validate required fields
        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Name, email and password are required.'
            });
        }

        // Check if email already exists
        const existing = await AdminSignup.findOne({ email: email.toLowerCase().trim() });
        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Email already registered.'
            });
        }

        // Create supervisor with role = 'supervisor'
        const supervisor = await AdminSignup.create({
            name,
            email: email.toLowerCase().trim(),
            password,
            role: 'supervisor'
        });

        return res.status(201).json({
            success: true,
            message: 'Supervisor registered successfully.',
            data: {
                id:    supervisor._id,
                name:  supervisor.name,
                email: supervisor.email,
                role:  supervisor.role
            }
        });

    } catch (error) {
        console.error('[Supervisor Register] Error:', error.message);
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                message: 'Email already exists.'
            });
        }
        return res.status(500).json({
            success: false,
            message: 'Server error.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// ─── POST /api/supervisor/auth/login ─────────────────────────────────────────
// Supervisor login with email + password → returns JWT token
// ─────────────────────────────────────────────────────────────────────────────
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required.'
            });
        }

        // Find supervisor by email with role = supervisor
        const supervisor = await AdminSignup.findOne({
            email: email.toLowerCase().trim(),
            role: 'supervisor'
        });

        if (!supervisor) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials.'
            });
        }

        // Check if account is active
        if (supervisor.status === 'inactive') {
            return res.status(403).json({
                success: false,
                message: 'Your account is inactive. Contact admin.'
            });
        }

        // Compare password
        const isMatch = await supervisor.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials.'
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            {
                id:    supervisor._id.toString(),
                uid:   supervisor._id.toString(),
                email: supervisor.email,
                role:  'supervisor',
                name:  supervisor.name
            },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        // Save token in DB (as per existing pattern in adminSignup model)
        supervisor.token = token;
        await supervisor.save();

        return res.status(200).json({
            success: true,
            message: 'Login successful.',
            token,
            supervisor: {
                id:           supervisor._id,
                name:         supervisor.name,
                email:        supervisor.email,
                role:         supervisor.role,
                profilePhoto: supervisor.profilePhoto || ''
            }
        });

    } catch (error) {
        console.error('[Supervisor Login] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// ─── GET /api/supervisor/auth/me ─────────────────────────────────────────────
// Get logged in supervisor's own profile
// ─────────────────────────────────────────────────────────────────────────────
exports.getMe = async (req, res) => {
    try {
        const uid = req.user?.uid || req.user?.id;

        const supervisor = await AdminSignup.findById(uid).select('-password -token');

        if (!supervisor) {
            return res.status(404).json({
                success: false,
                message: 'Supervisor not found.'
            });
        }

        return res.status(200).json({
            success: true,
            data: supervisor
        });

    } catch (error) {
        console.error('[Supervisor GetMe] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error.'
        });
    }
};

// ─── POST /api/supervisor/auth/logout ────────────────────────────────────────
// Logout — blacklist the token
// ─────────────────────────────────────────────────────────────────────────────
exports.logout = async (req, res) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];

        if (token) {
            // Add to blacklist so it can't be used again
            sessionBlacklist.add(token);

            // Clear token from DB
            const uid = req.user?.uid || req.user?.id;
            await AdminSignup.findByIdAndUpdate(uid, { token: null });
        }

        return res.status(200).json({
            success: true,
            message: 'Logged out successfully.'
        });

    } catch (error) {
        console.error('[Supervisor Logout] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error.'
        });
    }
};

// ─── PUT /api/supervisor/auth/change-password ────────────────────────────────
// Change supervisor password
// ─────────────────────────────────────────────────────────────────────────────
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const uid = req.user?.uid || req.user?.id;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Current password and new password are required.'
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'New password must be at least 6 characters.'
            });
        }

        const supervisor = await AdminSignup.findById(uid);
        if (!supervisor) {
            return res.status(404).json({
                success: false,
                message: 'Supervisor not found.'
            });
        }

        // Verify current password
        const isMatch = await supervisor.comparePassword(currentPassword);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Current password is incorrect.'
            });
        }

        // Update password — pre-save hook will hash it
        supervisor.password = newPassword;
        await supervisor.save();

        return res.status(200).json({
            success: true,
            message: 'Password changed successfully. Please login again.'
        });

    } catch (error) {
        console.error('[Supervisor ChangePassword] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error.'
        });
    }
};