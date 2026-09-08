const Admin = require('../models/AdminSchema');
const AdminSignup = require('../models/adminSignup');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Booking = require('../models/Booking');
const LogisticsBooking = require('../models/LogisticsBooking');
const ShuttleBooking = require('../models/ShuttleBooking');
const Complaint = require('../models/Complaint');
const Vehicle = require('../models/Vehicle');
const ServiceCategory = require('../models/ServiceCategory');
const History = require('../models/History');
const Route = require('../models/Route');
const Review = require('../models/Review');
const DelayLog = require('../models/DelayLog');
const CMS = require('../models/CMS');
const Shift = require('../models/Shift');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const imagekit = require('../config/imagekit');
const Transaction = require('../models/Transaction');
const sendEmail = require('../utils/sendEmail');
const sendSMS = require('../utils/sendSMS');
const firebaseAdmin = require('../config/firebase');

// Controller for syncing admin data upon login
const syncAdminData = async (req, res) => {
    try {
        let token = req.headers.authorization;
        if (token && token.startsWith('Bearer ')) {
            token = token.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ message: 'No Google auth token provided.' });
        }

        const decoded = await firebaseAdmin.auth().verifyIdToken(token);
        const email = decoded.email?.toLowerCase().trim();
        const name = decoded.name || decoded.email || 'Admin';

        if (!email) {
            return res.status(400).json({ message: 'Google account email not found.' });
        }

        let admin = await AdminSignup.findOne({ email });
        if (!admin) {
            admin = await AdminSignup.create({
                name,
                email,
                password: `google_${decoded.uid}_${Date.now()}`,
                role: 'admin',
            });
        }

        const sessionToken = jwt.sign(
            { id: admin._id, email: admin.email, role: admin.role },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '1d' }
        );

        admin.name = admin.name || name;
        admin.token = sessionToken;
        await admin.save();

        res.status(200).json({
            success: true,
            message: 'Admin synced successfully',
            token: sessionToken,
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                role: admin.role,
            }
        });
    } catch (error) {
        console.error('Error syncing admin:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Get all drivers for admin dashboard
const getAllDrivers = async (req, res) => {
    try {
        const filter = {};
        if (req.query.status) {
            // handle pending_approval alias
            filter.status = req.query.status === 'pending_approval' ? 'pending' : req.query.status;
        }
        const drivers = await Driver.find(filter).sort({ createdAt: -1 });
        res.status(200).json({ drivers });
    } catch (error) {
        console.error('Error fetching drivers:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update driver status (e.g., approve/verify)
const updateDriverStatus = async (req, res) => {
    try {
        const { driverId } = req.params;
        const { status, isApproved } = req.body;

        if (!['pending', 'active', 'suspended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const updateData = { status };
        
        // If an admin sets status to active, they are implicitly approving the driver.
        if (status === 'active') {
            updateData.isApproved = true;
        } else if (isApproved !== undefined) {
            updateData.isApproved = isApproved;
        }

        const driver = await Driver.findByIdAndUpdate(
            driverId,
            updateData,
            { new: true }
        );

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        res.status(200).json({
            message: `Driver status updated to ${status}`,
            driver
        });
    } catch (error) {
        console.error('Error updating driver status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Warn a driver
const warnDriver = async (req, res) => {
    try {
        const { reason } = req.body;
        const driverId = req.params.driverId;

        const driver = await Driver.findById(driverId);
        if (!driver) return res.status(404).json({ message: "Driver not found" });

        driver.warningCount = (driver.warningCount || 0) + 1;
        driver.lastWarningReason = reason;
        driver.lastWarningDate = new Date();

        if (driver.warningCount >= 3) {
            driver.status = "suspended";
        }

        await driver.save();

        if (driver.email) {
            await sendEmail(driver.email, "Admin Warning Notice", reason);
        }
        if (driver.mobileNumber || driver.phone) {
            await sendSMS(driver.mobileNumber || driver.phone, reason);
        }

        res.json({ success: true, message: "Warning sent successfully" });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// --- USER MANAGEMENT ---

// Get all users
const getAllUsers = async (req, res) => {
    try {
        const users = await User.find().populate('assignedRoutes').sort({ createdAt: -1 });
        res.status(200).json({ users });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Create user — Admin creates user account (no self registration)
// const createUser = async (req, res) => {
//     try {
//         const { name, email, mobileNumber, password, role } = req.body;

//         // Validate
//         if (!email || !password) {
//             return res.status(400).json({
//                 success: false,
//                 message: 'Email and password are required.'
//             });
//         }

//         if (password.length < 6) {
//             return res.status(400).json({
//                 success: false,
//                 message: 'Password must be at least 6 characters.'
//             });
//         }

//         // Check duplicate
//         const existing = await User.findOne({
//             $or: [
//                 { email: email.toLowerCase().trim() },
//                 ...(mobileNumber ? [{ mobileNumber }] : [])
//             ]
//         });

//         if (existing) {
//             return res.status(400).json({
//                 success: false,
//                 message: 'User already exists with this email or phone.'
//             });
//         }

//         // Create user
//         const user = new User({
//             name:         name || '',
//             email:        email.toLowerCase().trim(),
//             mobileNumber: mobileNumber || undefined,
//             password,
//             role:         role || 'user',
//             status:       'active'
//         });

//         await user.save();

//         return res.status(201).json({
//             success: true,
//             message: 'User created successfully by admin.',
//             data: {
//                 id:           user._id,
//                 name:         user.name,
//                 email:        user.email,
//                 mobileNumber: user.mobileNumber,
//                 role:         user.role,
//                 status:       user.status
//             }
//         });

//     } catch (error) {
//         console.error('[createUser] Error:', error.message);
//         if (error.code === 11000) {
//             return res.status(400).json({
//                 success: false,
//                 message: 'Email or phone already exists.'
//             });
//         }
//         return res.status(500).json({
//             success: false,
//             message: 'Server error.',
//             error: process.env.NODE_ENV === 'development' ? error.message : undefined
//         });
//     }
// };

const createUser = async (req, res) => {
    try {
        const {
            name,
            email,
            mobileNumber,
            password,
            companyName,
            address,
            gstNumber,
            corporateId,
            username,
            status
        } = req.body;

        // Validate required fields
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required.'
            });
        }

        if (!name) {
            return res.status(400).json({
                success: false,
                message: 'Full name is required.'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'Password must be at least 6 characters.'
            });
        }

        // Check duplicate email
        const existingEmail = await User.findOne({
            email: email.toLowerCase().trim()
        });
        if (existingEmail) {
            return res.status(400).json({
                success: false,
                message: 'User already exists with this email.'
            });
        }

        // Check duplicate mobile
        if (mobileNumber) {
            const existingMobile = await User.findOne({ mobileNumber });
            if (existingMobile) {
                return res.status(400).json({
                    success: false,
                    message: 'User already exists with this mobile number.'
                });
            }
        }

        // Check duplicate username
        if (username) {
            const existingUsername = await User.findOne({ username });
            if (existingUsername) {
                return res.status(400).json({
                    success: false,
                    message: 'Username already taken.'
                });
            }
        }

        // Create corporate user
        const user = new User({
            name,
            email:        email.toLowerCase().trim(),
            mobileNumber: mobileNumber  || undefined,
            password,
            plainPassword: password,
            username:     username      || undefined,
            companyName:  companyName   || '',
            address:      address       || '',
            gstNumber:    gstNumber     || '',
            corporateId:  corporateId   || '',
            role:         'corporate',
            status:       status        || 'active'
        });

        await user.save();

        return res.status(201).json({
            success: true,
            message: 'Corporate user created successfully.',
            data: {
                id:           user._id,
                name:         user.name,
                email:        user.email,
                mobileNumber: user.mobileNumber,
                username:     user.username,
                companyName:  user.companyName,
                address:      user.address,
                gstNumber:    user.gstNumber,
                corporateId:  user.corporateId,
                role:         user.role,
                status:       user.status
            }
        });

    } catch (error) {
        console.error('[createUser] Error:', error.message);
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                message: 'Email, mobile or username already exists.'
            });
        }
        return res.status(500).json({
            success: false,
            message: 'Server error.',
            error: error.message
        });
    }
};

// Update user status (block/deactivate/activate)
const updateUserStatus = async (req, res) => {
    try {
        const { userId } = req.params;
        const { status } = req.body;

        if (!['active', 'inactive', 'suspended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const user = await User.findByIdAndUpdate(userId, { status }, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: `User status updated to ${status}`, user });
    } catch (error) {
        console.error('Error updating user status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Assign Routes to User
const assignRoutesToUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const { assignedRoutes } = req.body; // Expecting array of Route ObjectIds

        if (!Array.isArray(assignedRoutes)) {
            return res.status(400).json({ message: 'assignedRoutes must be an array' });
        }

        const user = await User.findByIdAndUpdate(userId, { assignedRoutes }, { new: true }).populate('assignedRoutes');
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: 'Assigned routes updated', user });
    } catch (error) {
        console.error('Error assigning routes to user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Edit user profile
const updateUserProfile = async (req, res) => {
    try {
        const { userId } = req.params;
        const updates = req.body;

        const user = await User.findByIdAndUpdate(userId, updates, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: 'User profile updated', user });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Toggle Fraudulent status
const blacklistUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const { isFraudulent } = req.body;

        const user = await User.findByIdAndUpdate(userId, { isFraudulent }, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: `User fraudulent status set to ${isFraudulent}`, user });
    } catch (error) {
        console.error('Error blacklisting user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Delete driver record
const deleteDriver = async (req, res) => {
    try {
        const { driverId } = req.params;
        const driver = await Driver.findByIdAndDelete(driverId);

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        res.status(200).json({ message: 'Driver deleted successfully' });
    } catch (error) {
        console.error('Error deleting driver:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Delete user record
const deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findByIdAndDelete(userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- BOOKING MANAGEMENT ---

const getAllBookings = async (req, res) => {
    try {
        const { type } = req.query;
        let bookings = [];

        if (type === 'logistics') {
            const rawBookings = await LogisticsBooking.find().sort({ createdAt: -1 });
            bookings = rawBookings.map(b => ({
                ...b.toObject(),
                bookingId: b._id,
                type: 'logistics',
                pickup: b.pickup?.address || b.pickup?.name || '',
                drop: b.dropoff?.address || b.dropoff?.name || '',
            }));
            return res.status(200).json({ success: true, bookings });
        }
        if (type === 'shuttle') {
            const rawBookings = await ShuttleBooking.find().populate('routeId').sort({ createdAt: -1 });
            bookings = rawBookings.map(b => ({
                ...b.toObject(),
                bookingId: b._id,
                type: 'shuttle',
                pickup: b.pickupLocation || '',
                drop: b.dropoffLocation || '',
            }));
            return res.status(200).json({ success: true, bookings });
        }
        if (type === 'ride') {
            const rawBookings = await History.find().populate('userId driverId').sort({ createdAt: -1 });
            bookings = rawBookings.map(b => ({
                ...b.toObject(),
                bookingId: b._id,
                type: 'ride',
                pickup: b.locations?.[0]?.address || b.locations?.[0]?.title || b.pickupLocation || '',
                drop: b.locations?.[1]?.address || b.locations?.[1]?.title || b.dropoffLocation || '',
                pickupLocation: b.locations?.[0]?.address || b.locations?.[0]?.title || b.pickupLocation || '',
                dropoffLocation: b.locations?.[1]?.address || b.locations?.[1]?.title || b.dropoffLocation || '',
            }));
            return res.status(200).json({ success: true, bookings });
        }

        const [rides, logistics, shuttles] = await Promise.all([
            History.find().populate('userId driverId').sort({ createdAt: -1 }),
            LogisticsBooking.find().sort({ createdAt: -1 }),
            ShuttleBooking.find().populate('routeId').sort({ createdAt: -1 }),
        ]);

        const formattedRides = rides.map(b => ({
            ...b.toObject(),
            bookingId: b._id,
            type: 'ride',
            pickup: b.locations?.[0]?.address || b.locations?.[0]?.title || b.pickupLocation || '',
            drop: b.locations?.[1]?.address || b.locations?.[1]?.title || b.dropoffLocation || '',
            pickupLocation: b.locations?.[0]?.address || b.locations?.[0]?.title || b.pickupLocation || '',
            dropoffLocation: b.locations?.[1]?.address || b.locations?.[1]?.title || b.dropoffLocation || '',
        }));
        const formattedLogistics = logistics.map(b => ({ ...b.toObject(), bookingId: b._id, type: 'logistics', pickup: b.pickup?.address, drop: b.dropoff?.address }));
        const formattedShuttles = shuttles.map(b => ({ ...b.toObject(), bookingId: b._id, type: 'shuttle', pickup: b.pickupLocation, drop: b.dropoffLocation }));

        res.status(200).json({ 
            success: true, 
            bookings: { 
                rides: formattedRides, 
                logistics: formattedLogistics, 
                shuttles: formattedShuttles 
            } 
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateBookingStatus = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { status, action, driverId, newFare, newStatus, reason } = req.body;
        const update = {};
        
        let finalStatus = status || newStatus;
        if (!finalStatus && driverId) {
            // Auto-transition to confirmed/accepted if driver assigned
            finalStatus = 'confirmed'; 
        }

        if (finalStatus) update.status = finalStatus;
        if (driverId) update.driverId = driverId;
        if (newFare !== undefined) {
            update.fare = newFare;
            update.totalPrice = newFare;
        }
        if (reason) update.adminReason = reason;
        if (action === 'cancel') update.status = 'cancelled';

        let booking = await Booking.findByIdAndUpdate(bookingId, update, { new: true });
        if (!booking) booking = await History.findByIdAndUpdate(bookingId, update, { new: true });
        if (!booking) booking = await LogisticsBooking.findByIdAndUpdate(bookingId, update, { new: true });
        if (!booking) booking = await ShuttleBooking.findByIdAndUpdate(bookingId, update, { new: true });
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });
        res.status(200).json({ success: true, booking });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getUserBookings = async (req, res) => {
    try {
        const { userId } = req.params;
        const bookings = await Booking.find({ userId }).populate('driverId').sort({ createdAt: -1 });
        res.status(200).json({ bookings });
    } catch (error) {
        console.error('Error fetching user bookings:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- COMPLAINTS ---

const getAllComplaints = async (req, res) => {
    try {
        const complaints = await Complaint.find().populate('userId').sort({ createdAt: -1 });
        res.status(200).json({ complaints });
    } catch (error) {
        console.error('Error fetching complaints:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateComplaintStatus = async (req, res) => {
    try {
        const { complaintId } = req.params;
        const { status } = req.body;

        const complaint = await Complaint.findByIdAndUpdate(complaintId, { status }, { new: true });
        if (!complaint) return res.status(404).json({ message: 'Complaint not found' });

        res.status(200).json({ message: `Complaint status updated to ${status}`, complaint });
    } catch (error) {
        console.error('Error updating complaint status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- REVIEWS ---

const getAllReviews = async (req, res) => {
    try {
        const reviews = await Review.find().populate('fromId toId bookingId').sort({ createdAt: -1 });
        res.status(200).json({ reviews });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- VEHICLE MANAGEMENT ---

const getAllVehicles = async (req, res) => {
    try {
        const vehicles = await Vehicle.find().populate('driverId categoryId');
        res.status(200).json({ vehicles });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateVehicleStatus = async (req, res) => {
    try {
        const { vehicleId } = req.params;
        const { status } = req.body;
        const vehicle = await Vehicle.findByIdAndUpdate(vehicleId, { status }, { new: true });
        res.status(200).json({ vehicle });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateVehicle = async (req, res) => {
    try {
        const { vehicleId } = req.params;
        const updates = req.body;
        
        // Handle special document verification fields if they come in a flat way
        if (updates.rcVerified !== undefined || updates.insuranceVerified !== undefined) {
            const vehicle = await Vehicle.findById(vehicleId);
            if (!vehicle) return res.status(404).json({ message: 'Vehicle not found' });
            
            if (updates.rcVerified !== undefined) {
                if (!vehicle.documents) vehicle.documents = {};
                if (!vehicle.documents.rc) vehicle.documents.rc = {};
                vehicle.documents.rc.verified = updates.rcVerified;
            }
            if (updates.insuranceVerified !== undefined) {
                if (!vehicle.documents) vehicle.documents = {};
                if (!vehicle.documents.insurance) vehicle.documents.insurance = {};
                vehicle.documents.insurance.verified = updates.insuranceVerified;
            }
            
            // Apply other updates
            Object.keys(updates).forEach(key => {
                if (key !== 'rcVerified' && key !== 'insuranceVerified' && key !== 'documents') {
                    vehicle[key] = updates[key];
                }
            });
            
            await vehicle.save();
            return res.status(200).json({ success: true, vehicle });
        }

        const vehicle = await Vehicle.findByIdAndUpdate(vehicleId, updates, { new: true });
        if (!vehicle) return res.status(404).json({ message: 'Vehicle not found' });
        
        res.status(200).json({ success: true, vehicle });
    } catch (error) {
        console.error('Error updating vehicle:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const createVehicle = async (req, res) => {
    try {
        console.log('Create Vehicle Request:', req.body);
        const { driverId, categoryId, make, model, year, vin, numberPlate, status } = req.body;
        
        if (!numberPlate) {
            return res.status(400).json({ message: 'Number Plate is required' });
        }

        let catId = categoryId;
        if (!catId) {
            const vehicleType = (req.body.type || 'cab').toLowerCase();
            const category = await ServiceCategory.findOne({ type: vehicleType });
            if (category) {
                catId = category._id;
            } else {
                const fallback = await ServiceCategory.findOne();
                if (fallback) catId = fallback._id;
                else return res.status(400).json({ message: 'No service categories found. Please create one first.' });
            }
        }

        const existingVehicle = await Vehicle.findOne({ numberPlate });
        if (existingVehicle) {
            return res.status(400).json({ message: 'Vehicle with this number plate already exists' });
        }

        // Map frontend status to backend enum
        let finalStatus = status || 'inactive';
        if (finalStatus === 'expired') finalStatus = 'inactive';

        const vehicle = new Vehicle({
            driverId: driverId || null,
            categoryId: catId,
            make,
            model,
            year,
            vin,
            numberPlate,
            status: finalStatus
        });

        await vehicle.save();
        res.status(201).json({ success: true, message: 'Vehicle created successfully', vehicle });
    } catch (error) {
        console.error('Error creating vehicle:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- SERVICE CATEGORIES ---

const createServiceCategory = async (req, res) => {
    try {
        const category = new ServiceCategory(req.body);
        await category.save();
        res.status(201).json({ category });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getServiceCategories = async (req, res) => {
    try {
        const categories = await ServiceCategory.find();
        res.status(200).json({ categories });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- ROUTE MANAGEMENT ---

const createRoute = async (req, res) => {
    try {
        const routeData = { ...req.body };
        // Sync source/destination with startLocation/endLocation
        if (routeData.startLocation && !routeData.source) {
            routeData.source = routeData.startLocation;
        } else if (routeData.source && !routeData.startLocation) {
            routeData.startLocation = routeData.source;
        }
        if (routeData.endLocation && !routeData.destination) {
            routeData.destination = routeData.endLocation;
        } else if (routeData.destination && !routeData.endLocation) {
            routeData.endLocation = routeData.destination;
        }

        const route = new Route(routeData);
        await route.save();
        res.status(201).json({ route });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getAllRoutes = async (req, res) => {
    try {
        const routes = await Route.find().lean();
        const mappedRoutes = routes.map(route => {
            return {
                ...route,
                startLocation: route.startLocation || route.source || 'N/A',
                endLocation: route.endLocation || route.destination || 'N/A',
                source: route.source || route.startLocation || 'N/A',
                destination: route.destination || route.endLocation || 'N/A'
            };
        });
        res.status(200).json({ routes: mappedRoutes });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const routeData = { ...req.body };
        // Sync source/destination with startLocation/endLocation
        if (routeData.startLocation && !routeData.source) {
            routeData.source = routeData.startLocation;
        } else if (routeData.source && !routeData.startLocation) {
            routeData.startLocation = routeData.source;
        }
        if (routeData.endLocation && !routeData.destination) {
            routeData.destination = routeData.endLocation;
        } else if (routeData.destination && !routeData.endLocation) {
            routeData.endLocation = routeData.destination;
        }

        const route = await Route.findByIdAndUpdate(id, routeData, { new: true });
        if (!route) {
            return res.status(404).json({ success: false, message: 'Route not found' });
        }
        res.status(200).json({ success: true, route });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const deleteRoute = async (req, res) => {
    try {
        const { id } = req.params;
        const route = await Route.findByIdAndDelete(id);
        if (!route) {
            return res.status(404).json({ success: false, message: 'Route not found' });
        }
        res.status(200).json({ success: true, message: 'Route deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- SETTLEMENTS & REPORTS ---

const getTransactionReports = async (req, res) => {
    try {
        const transactions = await Transaction.find().populate('userId driverId bookingId').sort({ createdAt: -1 });
        res.status(200).json({ transactions });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- CMS & NOTIFICATIONS --- // CMS (Content Management System)

const updateCMSContent = async (req, res) => {
    try {
        const { key, value, type } = req.body;
        const content = await CMS.findOneAndUpdate({ key }, { value, type }, { upsert: true, new: true });
        res.status(200).json({ content });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getCMSContent = async (req, res) => {
    try {
        const { type } = req.query;
        const query = type ? { type } : {};
        const contents = await CMS.find(query);
        res.status(200).json({ contents });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const deleteCMSContent = async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await CMS.findByIdAndDelete(id);
        if (!deleted) {
            return res.status(404).json({ message: 'CMS content not found' });
        }
        res.status(200).json({ success: true, message: 'Deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- DELAY MONITORING ---

const logDelay = async (req, res) => {
    try {
        const { bookingId, reason, delayMinutes, notes } = req.body;
        const delay = new DelayLog({
            bookingId,
            reason,
            delayMinutes,
            notes
        });
        await delay.save();
        res.status(201).json({ message: 'Delay logged successfully', delay });
    } catch (error) {
        console.error('Error logging delay:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getPlatformStats = async (req, res) => {
    try {
        const totalUsers = await User.countDocuments();
        const totalDrivers = await Driver.countDocuments();
        const totalVehicles = await Vehicle.countDocuments();
        res.status(200).json({
            totalFleets: totalVehicles,
            fleetGrowth: 0.15,
            supportTickets: 12,
            urgentTickets: 3,
            totalUsers,
            totalDrivers,
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

module.exports = {
    syncAdminData,
    getAllDrivers,
    updateDriverStatus,
    warnDriver,
    getAllUsers,
    createUser,   // ✅ ADD THIS
    updateUserStatus,
    updateUserProfile,
    blacklistUser,
    deleteDriver,
    deleteUser,
    getUserBookings,
    getAllComplaints,
    updateComplaintStatus,
    getAllVehicles,
    createVehicle,
    updateVehicleStatus,
    updateVehicle,
    createServiceCategory,
    getServiceCategories,
    createRoute,
    getAllRoutes,
    updateRoute,
    deleteRoute,
    getTransactionReports,
    updateCMSContent,
    getCMSContent,
    deleteCMSContent,
    logDelay,
    getAllBookings,
    updateBookingStatus,
    getAllReviews,
    getPlatformStats,
    assignRoutesToUser,
    
    // Shift Management
    createShift: async (req, res) => {
        try {
            const shift = new Shift(req.body);
            await shift.save();
            res.status(201).json({ shift });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    },
    getAllShifts: async (req, res) => {
        try {
            const shifts = await Shift.find();
            res.status(200).json({ shifts });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    },
    updateShift: async (req, res) => {
        try {
            const { id } = req.params;
            const shift = await Shift.findByIdAndUpdate(id, req.body, { new: true });
            if (!shift) {
                return res.status(404).json({ success: false, message: 'Shift not found' });
            }
            res.status(200).json({ success: true, shift });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    },
    deleteShift: async (req, res) => {
        try {
            const { id } = req.params;
            const shift = await Shift.findByIdAndDelete(id);
            if (!shift) {
                return res.status(404).json({ success: false, message: 'Shift not found' });
            }
            res.status(200).json({ success: true, message: 'Shift deleted successfully' });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    },
    uploadFile: async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).json({ message: 'No file uploaded' });
            }
            imagekit.upload({
                file: req.file.buffer,
                fileName: `cms_${Date.now()}`,
                folder: '/TRANSGLOBE/cms'
            }, async (error, result) => {
                if (error) {
                    console.error('ImageKit upload error:', error);
                    return res.status(500).json({ message: 'Upload failed', error: error.message });
                }
                res.status(200).json({ success: true, url: result.url });
            });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    }
};
