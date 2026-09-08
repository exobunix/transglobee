const User = require('../models/User');
const Location = require('../models/Location');
const CMS = require('../models/CMS');
const jwt = require('jsonwebtoken');

// Register a new user with email/password
exports.register = async (req, res) => {
    try {
        const { name, email, mobileNumber, password } = req.body;

        if (!email || !password || !mobileNumber) {
            return res.status(400).json({ success: false, message: 'Email, mobileNumber, and password are required' });
        }

        const normalizedEmail = email.toLowerCase().trim();

        // Check if user exists
        const existingUser = await User.findOne({ $or: [{ email: normalizedEmail }, { mobileNumber }] });
        if (existingUser) {
            return res.status(400).json({ success: false, message: 'User already exists with this email or phone' });
        }

        const user = new User({
            name,
            email: normalizedEmail,
            mobileNumber,
            password,
            plainPassword: password
        });

        await user.save();

        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET || 'your_default_jwt_secret',
            { expiresIn: '7d' }
        );

        res.status(201).json({
            success: true,
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                mobileNumber: user.mobileNumber
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Registration failed', error: error.message });
    }
};

// Login user with email/password
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password are required' });
        }

        const normalizedEmail = email.toLowerCase().trim();

        // Find user and include password for comparison
        const user = await User.findOne({ email: normalizedEmail }).select('+password');
        if (!user || !user.password) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET || 'your_default_jwt_secret',
            { expiresIn: '7d' }
        );

        await User.updateOne({ _id: user._id }, { lastLoginAt: Date.now() });

        res.status(200).json({
            success: true,
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                mobileNumber: user.mobileNumber
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Login failed', error: error.message });
    }
};

// Save specific location (Home, Office, Pin, etc.)
exports.saveSavedLocation = async (req, res) => {
    try {
        const { mobileNumber, title, address, latitude, longitude, type } = req.body;

        if (!mobileNumber || !address || !latitude || !longitude) {
            return res.status(400).json({ message: 'mobileNumber, address, latitude, and longitude are required' });
        }

        // Find the user to get their ID
        const user = await User.findOne({ mobileNumber });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Create new location entry
        const locationEntry = new Location({
            userId: user._id,
            mobileNumber: user.mobileNumber,
            title: title || address.split(',')[0], // Use first part of address if no title
            address: address,
            latitude: latitude,
            longitude: longitude,
            type: type || 'pickup'
        });

        await locationEntry.save();

        res.status(201).json({
            message: 'Location saved successfully',
            location: locationEntry
        });
    } catch (error) {
        console.error('Error saving search history:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Step 1: Save phone number to DB after OTP verification
exports.registerPhone = async (req, res) => {
    try {
        let { mobileNumber, uid } = req.body;

        if (!mobileNumber) {
            return res.status(400).json({ message: 'mobileNumber is required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);

        // Check if user already exists with this phone number
        let user = await User.findOne({ mobileNumber });

        if (user) {
            // User already exists, update lastActive and return
            user.lastActive = Date.now();
            if (uid) user.uid = uid; // Save/update Firebase UID
            await user.save();
            return res.status(200).json({
                message: 'User already exists',
                user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
                isNewUser: false
            });
        }

        // Create new user with phone number and optional uid
        user = new User({ mobileNumber, uid });

        await user.save();
        return res.status(201).json({
            message: 'Phone number registered successfully',
            user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
            isNewUser: true
        });
    } catch (error) {
        console.error('Error registering phone:', error);
        if (error.code === 11000) {
            // duplicate key, likely due to unique index on email or mobile
            const field = Object.keys(error.keyPattern || {})[0];
            return res.status(400).json({ message: `${field || 'Field'} already exists` });
        }
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Step 2: Save user name after OTP verification
exports.saveName = async (req, res) => {
    try {
        let { mobileNumber, name } = req.body;

        if (!mobileNumber || !name) {
            return res.status(400).json({ message: 'mobileNumber and name are required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);
        const user = await User.findOne({ mobileNumber });

        if (!user) {
            return res.status(404).json({ message: 'User not found. Please register phone first.' });
        }

        user.name = name;
        user.lastActive = Date.now();
        await user.save();

        return res.status(200).json({
            message: 'Name saved successfully',
            user: { id: user._id, name: user.name, mobileNumber: user.mobileNumber }
        });
    } catch (error) {
        console.error('Error saving name:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// helper to normalise mobile numbers while preserving leading plus
function normalizeMobile(num) {
    if (!num) return num;
    const trimmed = String(num).trim();
    const hasPlus = trimmed.startsWith('+');
    const digits = trimmed.replace(/[^\d]/g, '');
    return hasPlus ? `+${digits}` : digits;
}

// Get user profile by phone number
exports.getProfile = async (req, res) => {
    try {
        let { mobileNumber } = req.params;
        let { uid } = req.query;

        // Fallback to authenticated user's ID if no specific user requested
        if (!mobileNumber && !uid && req.user) {
            uid = req.user.uid || req.user.id;
        }

        mobileNumber = normalizeMobile(mobileNumber);

        if (!mobileNumber && !uid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(uid ? [{ uid }] : []),
                ...(uid && uid.length === 24 ? [{ _id: uid }] : []),
            ],
        }).populate('assignedRoutes');

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ user });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update user profile by phone number
exports.updateProfile = async (req, res) => {
    try {
        let { mobileNumber } = req.params;
        const {
            name,
            mobileNumber: newMobile,
            currentMobileNumber,
            uid,
            email,
        } = req.body;

        mobileNumber = normalizeMobile(mobileNumber || currentMobileNumber || newMobile);

        if (!mobileNumber && !uid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(uid ? [{ uid }] : []),
            ],
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // if a new mobile number is provided, ensure it's not taken
        if (newMobile && newMobile !== user.mobileNumber) {
            const normNew = normalizeMobile(newMobile);
            const existing = await User.findOne({ mobileNumber: normNew });
            if (existing && existing._id.toString() !== user._id.toString()) {
                return res.status(400).json({ message: 'Mobile number already in use' });
            }
            user.mobileNumber = normNew;
        }

        if (name) user.name = name;
        if (uid) user.uid = uid;
        if (email !== undefined) user.email = email || undefined;
        user.lastActive = Date.now();
        await user.save();

        res.status(200).json({
            message: 'Profile updated successfully',
            user: {
                id: user._id,
                uid: user.uid,
                name: user.name,
                mobileNumber: user.mobileNumber,
                email: user.email,
            }
        });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};


// ─── GET /api/user/booking/:bookingId/driver-details ─────────────────────────
// When driver accepts ride → user sees driver name, photo, vehicle, phone
// ─────────────────────────────────────────────────────────────────────────────
exports.getDriverDetailsForUser = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const authUid = req.user?.uid || req.user?.id || req.user?.firebaseId;
        const User = require('../models/User');
        const History = require('../models/History');
        const LogisticsBooking = require('../models/LogisticsBooking');

        let user = null;
        if (authUid) {
            if (require('mongoose').Types.ObjectId.isValid(authUid)) {
                user = await User.findById(authUid);
            }
            if (!user) {
                user = await User.findOne({ uid: authUid });
            }
        }

        let ride = await History.findById(bookingId);
        let isLogistics = false;
        if (!ride) {
            ride = await LogisticsBooking.findById(bookingId);
            isLogistics = !!ride;
        }

        if (!ride) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found.',
            });
        }

        const rideUserId = ride.userId?.toString?.() || ride.userId;
        const allowedUserIds = new Set(
            [user?._id?.toString(), user?.uid, authUid].filter(Boolean)
        );
        if (user && rideUserId && !allowedUserIds.has(rideUserId)) {
            return res.status(403).json({
                success: false,
                message: 'Unauthorized access to this booking.',
            });
        }

        const hasDriver =
            ride.driverId ||
            ride.driverSnapshot ||
            ['accepted', 'confirmed', 'on_the_way', 'arrived', 'ongoing', 'in_transit', 'processing']
                .includes(String(ride.status || '').toLowerCase());

        if (!hasDriver && ['pending', 'cancelled', 'rejected'].includes(ride.status)) {
            return res.status(400).json({
                success: false,
                message: `No driver assigned yet. Booking status is: ${ride.status}`,
            });
        }

        let snapshot = ride.driverSnapshot;
        if (!snapshot && ride.driverId) {
            const Driver = require('../models/Driver');
            const driver = await Driver.findById(ride.driverId);
            if (driver) {
                snapshot = {
                    driver_id: driver._id,
                    name: driver.name,
                    phone: driver.mobileNumber || driver.phoneNumber,
                    vehicle_number: driver.vehicleNumberPlate,
                    vehicle_name: driver.vehicleModel,
                    photo: driver.photo || '',
                };
            }
        }

        if (!snapshot) {
            return res.status(404).json({
                success: false,
                message: 'Driver details not available yet.',
            });
        }

        let driverLocation = null;
        if (ride.driverId) {
            const Driver = require('../models/Driver');
            const driverDoc = await Driver.findById(ride.driverId).select('location').lean();
            const coords = driverDoc?.location?.coordinates;
            if (Array.isArray(coords) && coords.length >= 2) {
                driverLocation = {
                    latitude: coords[1],
                    longitude: coords[0],
                };
            }
        }

        const pickup = isLogistics
            ? ride.pickup?.address
            : ride.locations?.find((l) => l.type === 'pickup')?.address;
        const drop = isLogistics
            ? ride.dropoff?.address
            : ride.locations?.find((l) => l.type === 'dropoff')?.address;

        return res.status(200).json({
            success: true,
            message: 'Driver details fetched successfully.',
            data: {
                driver: {
                    driver_id: snapshot.driver_id,
                    id: snapshot.driver_id,
                    name: snapshot.name || 'Driver',
                    phone: snapshot.phone || null,
                    vehicle_number: snapshot.vehicle_number || 'N/A',
                    vehicle_name: snapshot.vehicle_name || 'Vehicle',
                    vehicleNumber: snapshot.vehicle_number || 'N/A',
                    vehicleName: snapshot.vehicle_name || 'Vehicle',
                    photo: snapshot.photo || 'https://i.pravatar.cc/150?u=driver',
                    location: driverLocation,
                    latitude: driverLocation?.latitude,
                    longitude: driverLocation?.longitude,
                },
                booking: {
                    id: ride._id,
                    status: ride.status,
                    otp: ride.otp,
                    fare: ride.fare || ride.totalPrice,
                    paymentMode: ride.paymentMode,
                    paymentStatus: ride.paymentStatus,
                    distance: ride.distance || ride.distanceKm,
                    pickup,
                    drop,
                },
            },
        });

    } catch (error) {
        console.error('[getDriverDetailsForUser] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error. Please try again.'
        });
    }
};

exports.updateFCMToken = async (req, res) => {
    try {
        const { userId, fcmToken } = req.body;
        if (!userId || !fcmToken) {
            return res.status(400).json({ message: 'userId and fcmToken are required' });
        }
        await User.findByIdAndUpdate(userId, { fcmToken });
        res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
    } catch (error) {
        console.error('Error updating FCM Token:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.getCMSContent = async (req, res) => {
    try {
        const { type } = req.query;
        const query = type ? { type } : {};
        const contents = await CMS.find(query);
        res.status(200).json({ success: true, contents });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

// Get saved addresses
exports.getSavedAddresses = async (req, res) => {
    try {
        const userId = req.user.id || req.user.uid;
        const user = await User.findOne({
            $or: [
                { _id: userId.length === 24 ? userId : undefined },
                { uid: userId }
            ].filter(Boolean)
        });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.status(200).json({ success: true, addresses: user.addresses || [] });
    } catch (error) {
        console.error('Error fetching saved addresses:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

// Add new saved address
exports.addSavedAddress = async (req, res) => {
    try {
        const userId = req.user.id || req.user.uid;
        const user = await User.findOne({
            $or: [
                { _id: userId.length === 24 ? userId : undefined },
                { uid: userId }
            ].filter(Boolean)
        });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        user.addresses.push(req.body);
        await user.save();

        res.status(201).json({ success: true, addresses: user.addresses });
    } catch (error) {
        console.error('Error adding saved address:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

// Update saved address
exports.updateSavedAddress = async (req, res) => {
    try {
        const userId = req.user.id || req.user.uid;
        const { addressId } = req.params;
        const user = await User.findOne({
            $or: [
                { _id: userId.length === 24 ? userId : undefined },
                { uid: userId }
            ].filter(Boolean)
        });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const address = user.addresses.id(addressId);
        if (!address) {
            return res.status(404).json({ success: false, message: 'Address not found' });
        }

        Object.assign(address, req.body);
        await user.save();

        res.status(200).json({ success: true, addresses: user.addresses });
    } catch (error) {
        console.error('Error updating saved address:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};

// Delete saved address
exports.deleteSavedAddress = async (req, res) => {
    try {
        const userId = req.user.id || req.user.uid;
        const { addressId } = req.params;
        const user = await User.findOne({
            $or: [
                { _id: userId.length === 24 ? userId : undefined },
                { uid: userId }
            ].filter(Boolean)
        });

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        user.addresses.pull({ _id: addressId });
        await user.save();

        res.status(200).json({ success: true, addresses: user.addresses });
    } catch (error) {
        console.error('Error deleting saved address:', error);
        res.status(500).json({ success: false, message: 'Server error', error: error.message });
    }
};
