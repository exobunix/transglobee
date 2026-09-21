const mongoose = require("mongoose");
const RideType = require("../models/RideType");
const History = require("../models/History");
const User = require("../models/User"); // used for populating name
const LogisticsBooking = require("../models/LogisticsBooking"); // Add this
const ShuttleBooking = require("../models/ShuttleBooking");
const { notifyAllDrivers } = require('../utils/notificationService');
const {
    broadcastNewRideToOnlineDrivers,
    notifyAdminAndSupervisor,
} = require('../utils/driverDispatch');

const Review = require("../models/Review");

const normalizeMobileNumber = (value) => {
    if (!value) return '';
    const trimmed = String(value).trim();
    const hasPlus = trimmed.startsWith('+');
    const digits = trimmed.replace(/[^\d]/g, '');
    return hasPlus ? `+${digits}` : digits;
};

const https = require('https');

const reverseGeocode = (lat, lng) => {
    return new Promise((resolve) => {
        if (!lat || !lng) return resolve(null);
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        if (!apiKey) return resolve(null);

        const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${apiKey}`;
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.status === 'OK' && parsed.results && parsed.results.length > 0) {
                        resolve(parsed.results[0].formatted_address);
                    } else {
                        resolve(null);
                    }
                } catch (e) {
                    resolve(null);
                }
            });
        }).on('error', () => resolve(null));
    });
};

const findUserByRideIdentity = async ({ uid, mobileNumber, email }) => {
    const lookups = [];

    if (uid) {
        lookups.push({ uid });
        if (mongoose.Types.ObjectId.isValid(uid)) {
            lookups.push({ _id: uid });
        }
    }

    if (mobileNumber) {
        const normalized = normalizeMobileNumber(mobileNumber);
        if (normalized) {
            lookups.push({ mobileNumber: normalized });
            if (normalized.startsWith('+91')) {
                lookups.push({ mobileNumber: normalized.replace('+91', '') });
            } else if (!normalized.startsWith('+')) {
                lookups.push({ mobileNumber: `+91${normalized}` });
            }
        }
    }

    if (email) {
        lookups.push({ email });
    }

    if (!lookups.length) {
        return null;
    }

    return User.findOne({ $or: lookups });
};

const resolveDocId = (value) => {
    if (!value) return '';
    if (typeof value === 'object' && value._id) {
        return value._id.toString();
    }
    return value.toString();
};

const resolveUserSocketRooms = async (ride) => {
    const rooms = new Set();
    if (!ride) return [];

    const rideRoom = ride._id?.toString?.();
    if (rideRoom) rooms.add(rideRoom);

    const userRef = ride.userId;
    if (userRef?._id) {
        rooms.add(userRef._id.toString());
    }
    if (typeof userRef === 'object' && userRef?.uid) {
        rooms.add(userRef.uid.toString());
    }
    if (userRef && typeof userRef !== 'object') {
        rooms.add(userRef.toString());
    }

    try {
        let userDoc = null;
        const mongoUserId = userRef?._id?.toString?.()
            || (mongoose.Types.ObjectId.isValid(userRef) ? userRef.toString() : null);
        if (mongoUserId) {
            userDoc = await User.findById(mongoUserId).select('uid _id').lean();
        } else if (userRef) {
            userDoc = await User.findOne({
                $or: [{ uid: userRef.toString() }, { firebaseId: userRef.toString() }],
            }).select('uid _id').lean();
        }
        if (userDoc?._id) rooms.add(userDoc._id.toString());
        if (userDoc?.uid) rooms.add(userDoc.uid.toString());
    } catch (lookupError) {
        console.warn('[SOCKET] Could not resolve user rooms:', lookupError.message);
    }

    return [...rooms].filter(Boolean);
};

const resolveDriverRecord = async (driverId) => {
    if (!driverId) return null;
    const Driver = require('../models/Driver');
    let driver = null;
    if (mongoose.Types.ObjectId.isValid(driverId)) {
        driver = await Driver.findById(driverId).select(
            'name mobileNumber phoneNumber vehicleNumberPlate vehicleModel photo uid _id location'
        );
    }
    if (!driver) {
        driver = await Driver.findOne({
            $or: [{ uid: driverId }, { firebaseId: driverId }],
        }).select(
            'name mobileNumber phoneNumber vehicleNumberPlate vehicleModel photo uid _id location'
        );
    }
    return driver;
};

const buildDriverSnapshot = (driver) => {
    if (!driver) return null;
    return {
        driver_id: driver._id,
        name: driver.name || 'Driver',
        phone: driver.mobileNumber || driver.phoneNumber || '',
        vehicle_number: driver.vehicleNumberPlate || 'N/A',
        vehicle_name: driver.vehicleModel || 'Vehicle',
        photo: driver.photo || '',
    };
};

const formatDriverForClient = (snapshot) => {
    if (!snapshot) return null;
    return {
        driver_id: snapshot.driver_id?.toString?.() || snapshot.driver_id,
        _id: snapshot.driver_id?.toString?.() || snapshot.driver_id,
        name: snapshot.name || 'Driver',
        phone: snapshot.phone || '',
        vehicle_number: snapshot.vehicle_number || 'N/A',
        vehicle_name: snapshot.vehicle_name || 'Vehicle',
        vehicleNumber: snapshot.vehicle_number || 'N/A',
        vehicleName: snapshot.vehicle_name || 'Vehicle',
        photo: snapshot.photo || '',
    };
};

exports.getRideTypes = async (req, res) => {
    try {
        let rides = await RideType.find({ status: true });

        res.status(200).json({
            success: true,
            data: rides
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

exports.getRideById = async (req, res) => {
    try {
        const { rideId } = req.params;
        if (!rideId) {
            return res.status(400).json({ success: false, message: 'rideId is required.' });
        }

        let ride = await History.findById(rideId).lean();
        let type = 'ride';

        if (!ride) {
            ride = await LogisticsBooking.findById(rideId).populate('segments.driverId').lean();
            type = 'logistics';
        }

        if (!ride) {
            const ShuttleBooking = require('../models/ShuttleBooking');
            ride = await ShuttleBooking.findById(rideId).populate('segments.driverId').lean();
            if (ride) {
                type = 'shuttle';
            }
        }

        if (!ride) {
            return res.status(404).json({ success: false, message: 'Ride not found.' });
        }

        let bookingUser = null;
        if (ride.userId) {
            try {
                bookingUser = await User.findById(ride.userId).select('name mobileNumber').lean();
            } catch (_) {}
        }

        let reqDriverId = null;
        if (req.user) {
            const Driver = require('../models/Driver');
            const identifier = req.user.uid || req.user.id;
            let driver;
            if (mongoose.Types.ObjectId.isValid(identifier)) {
                driver = await Driver.findById(identifier);
            }
            if (!driver) driver = await Driver.findOne({ uid: identifier });
            if (!driver) driver = await Driver.findOne({ firebaseId: identifier });
            if (driver) reqDriverId = driver._id.toString();
        }

        if (reqDriverId && (type === 'logistics' || type === 'shuttle') && ride.segments && ride.segments.length > 0) {
            const assignedSeg = ride.segments.find(s => s.driverId && s.driverId.toString() === reqDriverId);
            if (assignedSeg) {
                ride.fare = assignedSeg.price || 0;
                ride.totalPrice = assignedSeg.price || 0;
                ride.vehiclePrice = assignedSeg.price || 0;
            }
        }

        let driverForClient = formatDriverForClient(ride.driverSnapshot);
        if (!driverForClient && ride.driverId) {
            const driver = await resolveDriverRecord(ride.driverId);
            if (driver) {
                driverForClient = formatDriverForClient(buildDriverSnapshot(driver));
            }
        }

        const pickupAddr = ride.locations?.[0]?.address || ride.pickup?.address || ride.pickupLocation?.address || 'Pickup';
        const dropAddr = ride.locations?.[1]?.address || ride.dropoff?.address || ride.dropLocation?.address || 'Dropoff';

        const payload = {
            ...ride,
            bookingId: ride._id,
            userName: ride.userName || bookingUser?.name || ride.name || 'Guest User',
            userPhone: ride.userPhone || bookingUser?.mobileNumber || ride.mobileNumber || ride.phone || '',
            phone: ride.userPhone || bookingUser?.mobileNumber || ride.mobileNumber || ride.phone || '',
            pickupAddress: pickupAddr,
            dropAddress: dropAddr,
            otp: ride.otp,
            driver: driverForClient,
            driverSnapshot: ride.driverSnapshot || (driverForClient ? {
                driver_id: driverForClient.driver_id,
                name: driverForClient.name,
                phone: driverForClient.phone,
                vehicle_number: driverForClient.vehicle_number,
                vehicle_name: driverForClient.vehicle_name,
                photo: driverForClient.photo,
            } : null),
        };

        return res.status(200).json({
            success: true,
            type,
            data: payload,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getMyRides = async (req, res) => {
    try {
        const authUid = req.user?.uid || req.user?.id || req.user?.firebaseId || req.query?.userId;
        const authEmail = req.user?.email || req.query?.email;

        let user = null;
        const guestPhone = req.query?.phone || req.query?.mobileNumber || req.headers['x-guest-phone'];

        if (authUid) {
            user = await User.findOne({ $or: [{ uid: authUid }, { _id: authUid }] }).lean();
        } else if (guestPhone) {
            user = await User.findOne({ mobileNumber: guestPhone }).lean();
        }

        if (!user && authEmail) {
            user = await User.findOne({ email: authEmail }).lean();
        }

        const historyQuery = {};
        const logisticsQuery = {};

        if (user?._id) {
            historyQuery.userId = user._id;
        } else if (authUid && mongoose.Types.ObjectId.isValid(authUid)) {
            historyQuery.userId = authUid;
        } else if (guestPhone) {
            historyQuery.mobileNumber = guestPhone;
        }

        if (user?.uid) {
            logisticsQuery.userId = { $in: [user.uid, user._id?.toString()].filter(Boolean) };
        } else if (authUid) {
            logisticsQuery.userId = authUid;
        }

        const [historyRides, logisticsBookings] = await Promise.all([
            Object.keys(historyQuery).length
                ? History.find(historyQuery).sort({ createdAt: -1 }).lean()
                : Promise.resolve([]),
            Object.keys(logisticsQuery).length
                ? LogisticsBooking.find(logisticsQuery).populate('segments.driverId').sort({ createdAt: -1 }).lean()
                : Promise.resolve([]),
        ]);

        const taggedCab = historyRides.map((ride) => ({
            ...ride,
            type: 'cab',
            bookingCategory: 'cab',
            displayType: 'CAB',
        }));

        const taggedLogistics = logisticsBookings.map((booking) => {
            const category = booking.bookingCategory === 'shuttle' ? 'shuttle' : 'logistics';
            return {
                ...booking,
                type: category,
                bookingCategory: category,
                displayType: category === 'shuttle' ? 'SHUTTLE' : 'LOGISTICS',
            };
        });

        const data = [...taggedCab, ...taggedLogistics].sort(
            (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
        );

        return res.status(200).json({ success: true, data });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getDriverBookings = async (req, res) => {
    try {
        // Log at the very beginning to identify when it's hit and which driver is requesting
        const requestIdentifier = req.user ? (req.user.uid || req.user.id) : 'Unauthenticated';
        console.log(`[DRIVER-FETCH] Request from identifier: ${requestIdentifier}`);

        const Driver = require("../models/Driver");
        const mongoose = require("mongoose");
        let currentDriver;
        if (req.user) {
            const identifier = req.user.uid || req.user.id;
            console.log(`[BOOKINGS-DEBUG] Searching for driver with identifier: ${identifier}`);
            if (mongoose.Types.ObjectId.isValid(identifier)) {
                currentDriver = await Driver.findById(identifier);
                console.log(`[DRIVER-FETCH] Current driver search result: ${currentDriver ? currentDriver.name : 'NOT FOUND'}`);
            }
            if (!currentDriver) {
                currentDriver = await Driver.findOne({ uid: identifier });
            }
            if (!currentDriver) {
                currentDriver = await Driver.findOne({ firebaseId: identifier });
            }
            console.log(`[BOOKINGS-DEBUG] Driver found: ${currentDriver ? currentDriver.name : 'NONE'}`);
        }

        currentDriver = currentDriver || req.user?.dbUser || null;
        const currentDriverId = resolveDocId(currentDriver?._id);

        const lookbackDays = 7;
        const lookbackDate = new Date(Date.now() - lookbackDays * 24 * 60 * 60 * 1000);

        const rideQuery = currentDriver?._id ? {
            createdAt: { $gte: lookbackDate },
            $or: [
                { driverId: currentDriver._id },
                { "driverSnapshot.driver_id": currentDriver._id },
                { rejectedBy: currentDriver._id },
                {
                    status: { $in: ['pending', 'pending_for_driver'] },
                    rejectedBy: { $ne: currentDriver._id }
                }
            ]
        } : {
            createdAt: { $gte: lookbackDate },
            status: { $in: ['pending', 'pending_for_driver'] }
        };

        const bookings = await History.find(rideQuery).populate('userId', 'name').sort({ createdAt: -1 });

        // Merge with Logistics Bookings assigned to this driver or explicitly dispatched
        let logistics = [];
        if (currentDriver?._id) {
            logistics = await LogisticsBooking.find({ 
                createdAt: { $gte: lookbackDate },
                $or: [
                    { driverId: currentDriver._id },
                    ...(currentDriverId ? [{ driverId: currentDriverId }] : []),
                    { "segments.driverId": currentDriver._id },
                    ...(currentDriverId ? [{ "segments.driverId": currentDriverId }] : []),
                    { rejectedBy: currentDriver._id },
                    {
                        status: 'pending_for_driver',
                        roadmapStatus: 'approved',
                        rejectedBy: { $ne: currentDriver._id }
                    }
                ]
            }).sort({ createdAt: -1 });
        } else {
            logistics = [];
        }

        // Map logistics to a format the Driver App expects (BookingModel)
        const mappedLogistics = logistics.map(lb => {
            let matchedFare = lb.totalPrice || lb.vehiclePrice || 0;
            if (lb.segments && lb.segments.length > 0 && currentDriver) {
                const assignedSeg = lb.segments.find(s => 
                    (s.driverId && (s.driverId.toString() === currentDriver._id.toString() || 
                                     (currentDriverId && s.driverId.toString() === currentDriverId.toString())))
                );
                if (assignedSeg) {
                    matchedFare = assignedSeg.price || 0;
                }
            }
            return {
                _id: lb._id,
                userName: lb.userName || 'Customer',
                userPhone: lb.userPhone || '',
                pickupAddress: lb.pickup?.address || 'Pickup Location',
                dropAddress: lb.dropoff?.address || 'Dropoff Location',
                pickupLat: lb.pickup?.lat,
                pickupLng: lb.pickup?.lng,
                dropLat: lb.dropoff?.lat,
                dropLng: lb.dropoff?.lng,
                fare: matchedFare,
                distanceKm: lb.distanceKm || 0,
                status: lb.status,
                createdAt: lb.createdAt,
                rideMode: lb.vehicleType || 'truck', 
                vehicleType: lb.vehicleType || 'truck',
                railwayStation: lb.railwayStation,
                driverId: lb.driverId,
                type: 'LOGISTICS',
                pickupDetails: {
                    house: lb.pickupAddress?.houseNumber,
                    floor: lb.pickupAddress?.floorNumber,
                    landmark: lb.pickupAddress?.landmark,
                    city: lb.pickupAddress?.city,
                    pincode: lb.pickupAddress?.pincode
                },
                dropDetails: {
                    house: lb.receivedAddress?.houseNumber,
                    floor: lb.receivedAddress?.floorNumber,
                    landmark: lb.receivedAddress?.landmark,
                    city: lb.receivedAddress?.city,
                    pincode: lb.receivedAddress?.pincode
                },
                items: lb.items || [],
                rejectedBy: lb.rejectedBy || [],
                totalPrice: matchedFare,
                transportName: lb.transportName,
                transportNumber: lb.transportNumber,
                segments: lb.segments || [],
                otp: lb.otp
            };
        });

        // Merge with Shuttle Bookings assigned to this driver or explicitly dispatched
        let shuttles = [];
        if (currentDriver?._id) {
            shuttles = await ShuttleBooking.find({
                createdAt: { $gte: lookbackDate },
                $or: [
                    { driverId: currentDriver._id },
                    ...(currentDriverId ? [{ driverId: currentDriverId }] : []),
                    { "segments.driverId": currentDriver._id },
                    ...(currentDriverId ? [{ "segments.driverId": currentDriverId }] : []),
                    { rejectedBy: currentDriver._id },
                    {
                        status: 'pending_for_driver',
                        roadmapStatus: 'approved',
                        rejectedBy: { $ne: currentDriver._id }
                    }
                ]
            }).sort({ createdAt: -1 });
        }

        const mappedShuttles = shuttles.map(sb => {
            let matchedFare = sb.totalPrice || 0;
            if (sb.segments && sb.segments.length > 0 && currentDriver) {
                const assignedSeg = sb.segments.find(s => 
                    (s.driverId && (s.driverId.toString() === currentDriver._id.toString() || 
                                     (currentDriverId && s.driverId.toString() === currentDriverId.toString())))
                );
                if (assignedSeg) {
                    matchedFare = assignedSeg.price || 0;
                }
            }
            return {
                _id: sb._id,
                userName: sb.userName || 'Customer',
                userPhone: sb.userPhone || '',
                pickupAddress: sb.pickup?.address || 'Pickup Location',
                dropAddress: sb.dropoff?.address || 'Dropoff Location',
                pickupLat: sb.pickup?.lat,
                pickupLng: sb.pickup?.lng,
                dropLat: sb.dropoff?.lat,
                dropLng: sb.dropoff?.lng,
                fare: matchedFare,
                distanceKm: sb.distanceKm || 0,
                status: sb.status,
                createdAt: sb.createdAt,
                rideMode: sb.vehicleType || 'shuttle', 
                vehicleType: sb.vehicleType || 'shuttle',
                driverId: sb.driverId,
                type: 'SHUTTLE',
                rejectedBy: sb.rejectedBy || [],
                totalPrice: matchedFare,
                segments: sb.segments || [],
                otp: sb.otp
            };
        });

        // Combine and sort
        const allBookings = [...bookings, ...mappedLogistics, ...mappedShuttles].sort((a, b) => 
            new Date(b.createdAt) - new Date(a.createdAt)
        );

        res.json({
            success: true,
            bookings: allBookings.map(b => {
                let displayStatus = b.status;
                // If I rejected it, show as 'rejected' for my personal history list
                if (currentDriver && b.rejectedBy && b.rejectedBy.some(id => id.toString() === currentDriver._id.toString())) {
                    displayStatus = 'rejected';
                }

                return {
                    _id: b._id,
                    userName: b.userId?.name || b.userName || 'Customer',
                    userPhone: b.mobileNumber || b.userPhone,
                    pickupAddress: b.locations ? (b.locations[0]?.address || '') : (b.pickup?.address || b.pickupAddress || ''),
                    dropAddress: b.locations ? (b.locations[1]?.address || '') : (b.dropoff?.address || b.dropAddress || ''),
                    fare: b.fare || b.totalPrice || 0,
                    distanceKm: parseFloat(b.distance) || b.distanceKm || 0,
                    status: displayStatus,
                    rideMode: b.rideMode,
                    vehicleType: b.vehicleType || b.rideMode, // Ensure vehicleType is present
                    createdAt: b.createdAt,
                    userId: b.userId?._id || b.userId,
                    pickupLat: b.locations ? b.locations[0]?.latitude : b.pickup?.lat,
                    pickupLng: b.locations ? b.locations[0]?.longitude : b.pickup?.lng,
                    dropLat: b.locations ? b.locations[1]?.latitude : b.dropoff?.lat,
                    dropLng: b.locations ? b.locations[1]?.longitude : b.dropoff?.lng,
                    otp: b.otp,
                    paymentStatus: b.paymentStatus || 'unpaid',
                    actualFare: b.actualFare,
                    driverId: b.driverId,
                    railwayStation: b.railwayStation,
                    transportName: b.transportName,
                    transportNumber: b.transportNumber,
                    type: b.type, // To distinguish LOGISTICS/SHUTTLE
                    segments: b.segments || []
                };
            })
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};



// To save user's "input fill" (Ride Request / Booking)
exports.createRideRequest = async (req, res) => {
    try {
                // const { mobileNumber, locations, rideMode, paymentMode, fare, distance, vehicleType, typeOfGood, helperCount, logisticItems } = req.body;
                const { name, mobileNumber, locations, rideMode, paymentMode, fare, distance, vehicleType, typeOfGood, helperCount, logisticItems, routeId, discountAmount, discount, appliedCoupon } = req.body;

        // Verify we have required fields
        if (!locations || !locations.pickup || !locations.dropoff || !rideMode || !fare) {
            return res.status(400).json({
                success: false,
                message: "Missing required fields: locations, rideMode, and fare are mandatory"
            });
        }

        if (locations && locations.pickup) {
            if (locations.pickup.title === 'Current Location' || locations.pickup.address === 'Current Location' || locations.pickup.address === 'Using GPS') {
                const resolved = await reverseGeocode(locations.pickup.latitude, locations.pickup.longitude);
                if (resolved) {
                    locations.pickup.address = resolved;
                    locations.pickup.title = resolved.split(',')[0];
                }
            }
        }
        if (locations && locations.dropoff) {
            if (locations.dropoff.title === 'Current Location' || locations.dropoff.address === 'Current Location' || locations.dropoff.address === 'Using GPS') {
                const resolved = await reverseGeocode(locations.dropoff.latitude, locations.dropoff.longitude);
                if (resolved) {
                    locations.dropoff.address = resolved;
                    locations.dropoff.title = resolved.split(',')[0];
                }
            }
        }

        // Resolve the booking user from any identity we have.
        let authUid = req.user?.uid || req.user?.id || req.user?.firebaseId || req.user?.sub;
        let authEmail = req.user?.email || req.user?.user_email || '';
        let userPhone = normalizeMobileNumber(
            mobileNumber || req.user?.phone_number || req.user?.phoneNumber || req.user?.mobileNumber || req.user?.phone
        );

        if (!authUid && !userPhone && !authEmail) {
            // Support guest user booking seamlessly
            const guestId = `guest_${Date.now()}_${Math.floor(1000 + Math.random() * 9000)}`;
            authUid = guestId;
            userPhone = `+9199999${Math.floor(10000 + Math.random() * 90000)}`;
        }

        let user = await findUserByRideIdentity({
            uid: authUid,
            mobileNumber: userPhone,
            email: authEmail,
        });

        if (user) {
            const updateFields = {};
            if (authUid && !user.uid) updateFields.uid = authUid;
            if (authEmail && !user.email) updateFields.email = authEmail;
            if (userPhone && !user.mobileNumber) updateFields.mobileNumber = userPhone;
            if ((name || req.user?.name) && !user.name) updateFields.name = name || req.user?.name;

            if (Object.keys(updateFields).length) {
                try {
                    await User.updateOne({ _id: user._id }, { $set: updateFields });
                    user = await User.findById(user._id);
                } catch (updateError) {
                    console.warn('[RIDE] Failed to backfill user fields:', updateError.message);
                }
            }
        }

        if (!user) {
            console.log(`User not found in DB. Auto-registering...`);
            try {
                user = await User.create({
                    uid: authUid || undefined,
                    mobileNumber: userPhone || undefined,
                    name: name || req.user?.name || 'Guest User',
                    email: authEmail || undefined,
                });
                console.log(`Auto-registered user: ${user._id}`);
            } catch (createError) {
                console.error('Failed to auto-register user:', createError);

                // If the record already exists but the lookup missed it, retry by uid/email/phone before failing.
                try {
                    user = await findUserByRideIdentity({
                        uid: authUid,
                        mobileNumber: userPhone,
                        email: authEmail,
                    });
                } catch (_) {
                    user = null;
                }

                if (!user) {
                    try {
                        const fallbackUid = `guest_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
                        user = await User.create({
                            uid: fallbackUid,
                            name: name || 'Guest User',
                        });
                    } catch (e2) {
                        user = await User.findOne();
                    }
                }
            }
        }

        if (userPhone && !user.mobileNumber) {
            user.mobileNumber = userPhone;
            await user.save();
        }

        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        const newRide = await History.create({
            userId: user._id,
            mobileNumber: user.mobileNumber,
            rideMode,
            paymentMode: paymentMode || "cash",
            distance: distance || "",
            fare: fare,
            otp,
            vehicleType,
            typeOfGood,
            helperCount: helperCount || 0,
            logisticItems: logisticItems || [],
            routeId: routeId || null,
            discountAmount: discountAmount || discount || 0,
            appliedCoupon: appliedCoupon || null,
            locations: [
                {
                    type: "pickup",
                    title: locations.pickup.title,
                    address: locations.pickup.address,
                    latitude: locations.pickup.latitude,
                    longitude: locations.pickup.longitude
                },
                {
                    type: "dropoff",
                    title: locations.dropoff.title,
                    address: locations.dropoff.address,
                    latitude: locations.dropoff.latitude,
                    longitude: locations.dropoff.longitude
                }
            ]
        });

        if (req.io) {
            const socketData = {
                id: newRide._id.toString(),
                userName: user.name || 'Customer',
                phone: user.mobileNumber,
                pick: locations.pickup.address,
                drop: locations.dropoff.address,
                pickupLat: locations.pickup.latitude,
                pickupLng: locations.pickup.longitude,
                dropLat: locations.dropoff.latitude,
                dropLng: locations.dropoff.longitude,
                distance: distance || 0,
                fare: fare,
                rideMode: rideMode,
                vehicleType: vehicleType || rideMode,
                status: 'pending',
                userId: user._id.toString(),
                userName: user.name || name || 'Guest User',
                userPhone: user.mobileNumber || userPhone || '',
                phone: user.mobileNumber || userPhone || '',
                type: 'CAB',
                bookingCategory: 'cab',
                routeId: newRide.routeId ? newRide.routeId.toString() : null,
                message: 'New cab ride requested',
            };

            // Cab (Ola/Uber style): all drivers + admin/supervisor dashboards
            await broadcastNewRideToOnlineDrivers(req.io, socketData, {
                pushTitle: 'New cab ride',
                pushBody: `${locations.pickup.address} → ${locations.dropoff.address}`,
            });

            notifyAdminAndSupervisor(req.io, socketData);
        }

        res.status(201).json({
            success: true,
            message: "Ride request created successfully",
            data: newRide
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// generic list of all rides (could be filtered by status, driverId, etc.)
exports.getRideDetails = async (req, res) => {
    try {
        // optional query params for filtering
        const filter = {};
        if (req.query.status) filter.status = req.query.status;
        if (req.query.driverId) filter.driverId = req.query.driverId;

        const rides = await History.find(filter)
            .populate('userId', 'name')
            .select('mobileNumber locations distance fare paymentMode status');

        const response = rides.map((ride) => ({
            userName: ride.userId?.name,
            phoneNumber: ride.mobileNumber,
            pickup: ride.locations[0]?.address || '',
            drop: ride.locations[1]?.address || '',
            distance: ride.distance,
            price: ride.fare,
            paymentMode: ride.paymentMode,
            status: ride.status,
            rideId: ride._id,
        }));

        res.json({
            success: true,
            data: response,
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// return only pending rides (driver app uses this)
exports.getPendingRides = async (req, res) => {
    try {
        const Driver = require("../models/Driver");
        const Vehicle = require("../models/Vehicle");
        const mongoose = require("mongoose");

        let driverRoutes = [];
        let hasVehicle = false;

        if (req.user) {
            const identifier = req.user.uid || req.user.id;
            let currentDriver;
            if (mongoose.Types.ObjectId.isValid(identifier)) {
                currentDriver = await Driver.findById(identifier);
            }
            if (!currentDriver) {
                currentDriver = await Driver.findOne({ uid: identifier });
            }
            if (!currentDriver) {
                currentDriver = await Driver.findOne({ firebaseId: identifier });
            }

            if (currentDriver) {
                const vehicle = await Vehicle.findOne({ driverId: currentDriver._id });
                if (vehicle && vehicle.routes) {
                    driverRoutes = vehicle.routes.map(r => r.toString());
                    hasVehicle = true;
                }
            }
        }

        const recentTimeLimit = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours limit
        const ridesQuery = { 
            status: 'pending',
            createdAt: { $gte: recentTimeLimit }
        };
        if (hasVehicle && driverRoutes.length > 0) {
            ridesQuery.$or = [
                { routeId: { $exists: false } },
                { routeId: null },
                { routeId: { $in: driverRoutes } }
            ];
        } else {
            ridesQuery.$or = [
                { routeId: { $exists: false } },
                { routeId: null }
            ];
        }

        const rides = await History.find(ridesQuery)
            .populate('userId', 'name')
            .select('mobileNumber locations distance fare paymentMode status userId rideMode vehicleType typeOfGood createdAt routeId');

        const logisticsPending = await LogisticsBooking.find({
            status: { $in: ['pending', 'pending_for_driver'] },
            createdAt: { $gte: recentTimeLimit }
        }).select('userName userPhone pickup dropoff distanceKm totalPrice vehicleType status userId createdAt');

        const rideResponse = rides.map((ride) => ({
            id: ride._id,
            userName: ride.userId?.name || 'Unknown',
            phone: ride.mobileNumber,
            pick: ride.locations?.[0]?.address || '',
            drop: ride.locations?.[1]?.address || '',
            distance: ride.distance,
            fare: ride.fare,
            paymentMode: ride.paymentMode,
            rideMode: ride.rideMode,
            vehicleType: ride.vehicleType,
            typeOfGood: ride.typeOfGood,
            status: ride.status,
            userId: ride.userId?._id || ride.userId,
            routeId: ride.routeId,
            createdAt: ride.createdAt
        }));

        const logisticsResponse = logisticsPending.map((booking) => ({
            id: booking._id,
            userName: booking.userName || 'Unknown',
            phone: booking.userPhone || '',
            pick: booking.pickup?.address || booking.pickup?.name || '',
            drop: booking.dropoff?.address || booking.dropoff?.name || '',
            distance: booking.distanceKm || 0,
            fare: booking.totalPrice || 0,
            paymentMode: 'N/A',
            rideMode: booking.vehicleType || 'Logistics',
            vehicleType: booking.vehicleType || 'Logistics',
            typeOfGood: 'Logistics',
            status: booking.status,
            userId: booking.userId,
            createdAt: booking.createdAt
        }));

        const response = [...rideResponse, ...logisticsResponse].sort(
            (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
        );

        res.json({ success: true, data: response });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// assign ride to driver (used by driver_service.acceptRide)
exports.assignRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { driverId: bodyDriverId, fare } = req.body;
        const authDriverId = req.user?.uid || req.user?.id || req.user?.firebaseId;
        const resolvedDriverId = bodyDriverId || authDriverId;

        let ride = await History.findById(rideId).populate('userId', 'name mobileNumber');
        let isLogistics = false;

        if (!ride) {
            const LogisticsBooking = require('../models/LogisticsBooking');
            ride = await LogisticsBooking.findById(rideId);
            if (!ride) return res.status(404).json({ message: 'Ride/Booking not found' });
            isLogistics = true;
        }

        // Concurrency Guard: Check if another driver has already accepted
        if (ride.driverId && ride.status !== 'pending' && ride.status !== 'pending_for_driver') {
            return res.status(409).json({
                success: false,
                message: 'This booking has already been accepted by another driver.'
            });
        }

        ride.status = isLogistics ? 'confirmed' : 'accepted';
        ride.driverActionAt = new Date();
        if (fare) ride.fare = fare;

        if (!ride.otp) {
            ride.otp = Math.floor(1000 + Math.random() * 9000).toString();
        }

        let driverSnapshot = null;
        const driver = await resolveDriverRecord(resolvedDriverId);
        if (driver) {
            ride.driverId = driver._id;
            driverSnapshot = buildDriverSnapshot(driver);
            ride.driverSnapshot = driverSnapshot;
        } else {
            console.warn('[ASSIGN-RIDE] Driver record not found for id:', resolvedDriverId);
        }

        await ride.save();

        if (req.io) {
            console.log(`[RIDE-DEBUG] Emitting ride_accepted for ${isLogistics ? 'Logistics' : 'Ride'} ${ride._id.toString()}`);
            const bookingUserName = isLogistics
                ? (ride.userName || 'Customer')
                : (ride.userId?.name || 'Customer');
            const bookingUserPhone = isLogistics
                ? (ride.userPhone || '')
                : (ride.mobileNumber || ride.userId?.mobileNumber || '');
            const userRooms = await resolveUserSocketRooms(ride);
            console.log(`[RIDE-DEBUG] ride_accepted rooms: ${userRooms.join(', ')}`);

            const acceptedPayload = {
                rideId: ride._id.toString(),
                status: ride.status,
                driver: formatDriverForClient(driverSnapshot || ride.driverSnapshot),
                fare: ride.totalPrice || ride.fare,
                otp: ride.otp,
                type: isLogistics ? 'LOGISTICS' : 'CAB',
            };

            // Emit to each user room
            userRooms.forEach((room) => {
                req.io.to(room).emit("ride_accepted", acceptedPayload);
                req.io.to(room).emit("ride_status_update", acceptedPayload);
            });
            // Also emit directly to the ride room
            req.io.to(ride._id.toString()).emit("ride_accepted", acceptedPayload);
            req.io.to(ride._id.toString()).emit("ride_status_update", acceptedPayload);

            if (driver?.location?.coordinates?.length >= 2) {
                const [lng, lat] = driver.location.coordinates;
                req.io.to(ride._id.toString()).emit("driver_location_update", {
                    rideId: ride._id.toString(),
                    latitude: lat,
                    longitude: lng,
                    heading: 0,
                });
            }
            const targetDriverRoom =
                driver?.uid?.toString() ||
                driver?._id?.toString() ||
                resolvedDriverId;
            if (targetDriverRoom) {
                req.io.to(targetDriverRoom).emit("new_ride", {
                    id: ride._id.toString(),
                    userName: bookingUserName,
                    phone: bookingUserPhone,
                    pick: isLogistics ? (ride.pickup?.address || 'Pickup Location') : (ride.locations?.[0]?.address || 'Pickup'),
                    drop: isLogistics ? (ride.dropoff?.address || 'Dropoff Location') : (ride.locations?.[1]?.address || 'Dropoff'),
                    pickupLat: isLogistics ? ride.pickup?.latitude : ride.locations?.[0]?.latitude,
                    pickupLng: isLogistics ? ride.pickup?.longitude : ride.locations?.[0]?.longitude,
                    dropLat: isLogistics ? ride.dropoff?.latitude : ride.locations?.[1]?.latitude,
                    dropLng: isLogistics ? ride.dropoff?.longitude : ride.locations?.[1]?.longitude,
                    distance: isLogistics ? `${ride.distanceKm || 0} km` : ride.distance || 0,
                    fare: ride.totalPrice || ride.fare || 0,
                    rideMode: (isLogistics ? ride.vehicleType : ride.rideMode || 'economy'),
                    status: ride.status,
                    userId: ride.userId?.toString(),
                    type: isLogistics ? 'LOGISTICS' : 'CAB',
                    otp: ride.otp,
                    vehicleType: ride.vehicleType,
                    transportName: ride.transportName,
                    transportNumber: ride.transportNumber
                });
            }
            // Also notify all other drivers that this ride is taken so popup immediately dismisses
            req.io.emit("ride_assigned", { rideId: ride._id.toString(), bookingId: ride._id.toString() });
        }

        const { notifyUser } = require('../utils/notificationService');
        notifyUser(ride.userId?._id?.toString?.() || ride.userId?.toString?.(), {
            title: "Ride Accepted",
            body: `Your ride has been accepted by ${ride.driverSnapshot?.name || 'a driver'}.`,
            data: {
                rideId: ride._id.toString(),
                type: 'RIDE_ACCEPTED'
            }
        });

        res.json({ success: true, ride });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// reject ride (driver app)
exports.rejectRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { driverId } = req.body;

        let ride = await History.findById(rideId);
        let isLogistics = false;

        if (!ride) {
            const LogisticsBooking = require('../models/LogisticsBooking');
            ride = await LogisticsBooking.findById(rideId);
            if (ride) isLogistics = true;
        }

        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        if (!isLogistics) {
            ride.driverActionAt = new Date();
        }

        if (driverId) {
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('_id');
            }
            if (!driver) {
                driver = await Driver.findOne({ uid: driverId }).select('_id');
            }
            if (!driver) {
                driver = await Driver.findOne({ firebaseId: driverId }).select('_id');
            }
            
            if (driver) {
                // Initialize array if empty
                if (!ride.rejectedBy) ride.rejectedBy = [];
                
                // Add to rejected array if not present
                if (!ride.rejectedBy.some(id => id.toString() === driver._id.toString())) {
                    ride.rejectedBy.push(driver._id);
                }
                
                // If assigned specifically to this driver, clear assignment
                if (ride.driverId && ride.driverId.toString() === driver._id.toString()) {
                    ride.driverId = null;
                    ride.status = 'pending';
                }
            }
        } else {
            // General rejection fallback
             if (ride.driverId) {
                ride.driverId = null;
                ride.status = 'pending';
             }
        }

        await ride.save();

        if (req.io) {
            req.io.emit("ride_status_updated", {
                rideId: ride._id.toString(),
                status: ride.status,
                type: isLogistics ? 'LOGISTICS' : 'CAB'
            });
        }

        return res.json({ success: true, message: `${isLogistics ? 'Logistics booking' : 'Ride'} rejected`, ride });
    } catch (err) {
        return res.status(500).json({ message: err.message });
    }
};

// update ride status
exports.updateRideStatus = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { status, delayReason, actualFare, driverId } = req.body;
        
        // Try finding in standard rides
        let ride = await History.findById(rideId);
        let isLogistics = false;

        // Try finding in logistics if not found in standard rides
        if (!ride) {
            ride = await LogisticsBooking.findById(rideId);
            if (ride) isLogistics = true;
        }

        if (!ride) return res.status(404).json({ message: 'Ride or Booking not found' });
        
        const oldStatus = ride.status;

        // For logistics, 'accepted' maps to 'confirmed' status
        if (status) {
            if (isLogistics && status === 'accepted') {
                ride.status = 'confirmed';
                if (!ride.otp) {
                    ride.otp = Math.floor(1000 + Math.random() * 9000).toString();
                }
            } else if (isLogistics && status === 'ongoing') {
                ride.status = 'in_transit';
            } else if (isLogistics && status === 'completed') {
                ride.status = 'delivered';
            } else {
                ride.status = status;
            }
        }
        if (delayReason) ride.delayReason = delayReason;
        if (actualFare != null) ride.actualFare = actualFare;

        // If transitioning to cancelled status
        if (ride.status === 'cancelled' && oldStatus !== 'cancelled') {
            const isMidRide = (oldStatus === 'ongoing' || oldStatus === 'in_transit');
            let distanceTravelled = 0;
            let calculatedDistance = 0;
            
            let pLat = null;
            let pLng = null;
            if (isLogistics) {
                pLat = ride.pickup ? ride.pickup.lat : null;
                pLng = ride.pickup ? ride.pickup.lng : null;
            } else {
                const pickupPoint = ride.locations && ride.locations.find(loc => loc.type === 'pickup');
                pLat = pickupPoint ? pickupPoint.latitude : null;
                pLng = pickupPoint ? pickupPoint.longitude : null;
            }

            try {
                const LiveTracking = require('../models/LiveTracking');
                const tracking = await LiveTracking.findOne({ bookingId: ride._id });
                if (pLat != null && pLng != null && tracking && tracking.latitude != null && tracking.longitude != null) {
                    const R = 6371; // Earth radius in km
                    const dLat = (tracking.latitude - pLat) * Math.PI / 180;
                    const dLon = (tracking.longitude - pLng) * Math.PI / 180;
                    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                              Math.cos(pLat * Math.PI / 180) * Math.cos(tracking.latitude * Math.PI / 180) *
                              Math.sin(dLon/2) * Math.sin(dLon/2);
                    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                    calculatedDistance = R * c;
                }
            } catch (err) {
                console.error("Error calculating cancellation distance:", err);
            }

            distanceTravelled = req.body.distanceTravelled != null ? Number(req.body.distanceTravelled) : calculatedDistance;
            distanceTravelled = Math.round(distanceTravelled * 100) / 100;

            const totalFare = isLogistics ? (ride.totalPrice || 0) : (ride.fare || 0);
            const totalDistance = isLogistics ? (ride.distanceKm || 0) : parseFloat(ride.distance || 0);
            
            // Cap distance
            if (totalDistance > 0 && distanceTravelled > totalDistance) {
                distanceTravelled = totalDistance;
            }

            const fraction = totalDistance > 0 ? (distanceTravelled / totalDistance) : 0;
            const cancellationFare = Math.round(totalFare * Math.min(1.0, fraction));

            ride.cancelReason = req.body.reason || req.body.cancelReason || "User cancelled";
            ride.distanceTravelled = distanceTravelled;
            ride.cancelledMidRide = isMidRide;

            if (isLogistics) {
                ride.cancellationCharge = cancellationFare;
            } else {
                ride.cancellationFare = cancellationFare;
            }
        }

        // record which driver made the change; driverId may be passed
        if (driverId) {
            ride.driverActionAt = new Date();
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            }
            if (!driver) {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            }
            if (!driver) {
                driver = await Driver.findOne({ firebaseId: driverId }).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            }
            if (driver) {
                ride.driverId = driver._id;              // ensure link
                ride.driverSnapshot = {
                    driver_id: driver._id.toString(),
                    name: driver.name || 'Driver',
                    phone: driver.mobileNumber || '',
                    vehicle_number: driver.vehicleNumberPlate || 'N/A',
                    vehicle_name: driver.vehicleModel || 'Vehicle',
                    photo: driver.photo || ''
                };
            }
        }

        await ride.save();

        // Credit driver wallet if completed/delivered
        if ((ride.status === 'completed' || ride.status === 'delivered') && oldStatus !== 'completed' && oldStatus !== 'delivered') {
            const fareEarned = Number(ride.actualFare || ride.fare || ride.totalPrice || actualFare || 0);
            if (fareEarned > 0 && ride.driverId) {
                const Driver = require('../models/Driver');
                await Driver.findByIdAndUpdate(ride.driverId, {
                    $inc: { walletBalance: fareEarned }
                });
            }
        }
        if (req.io) {
            // Emit to user's personal room AND the specific ride room
            const targetUserRoom = resolveDocId(ride.userId);
            if (targetUserRoom) {
                req.io.to(targetUserRoom).to(ride._id.toString()).emit("ride_status_update", {
                    rideId: ride._id.toString(),
                    status: ride.status,
                    driver: ride.driverSnapshot,
                    ride: ride
                });
            }
            if (status === 'cancelled' || ride.status === 'cancelled') {
                req.io.emit("ride_cancelled", { 
                    rideId: ride._id.toString(),
                    ride: ride
                });
                req.io.emit("ride_assigned", { rideId: ride._id.toString() }); // fallback generic removal
            }
        }

        // --- Push Notification to User ---
        const { notifyUser } = require('../utils/notificationService');
        let bodyText = `Your ride status is now: ${ride.status.toUpperCase()}`;
        if (status === 'arrived') bodyText = "Your driver has arrived at the pickup location!";
        if (status === 'completed') bodyText = "Your ride is complete. Thank you for riding with Transglobe!";
        if (status === 'cancelled') bodyText = "Your ride has been cancelled.";

        notifyUser(resolveDocId(ride.userId), {
            title: "Ride Update",
            body: bodyText,
            data: {
                rideId: ride._id.toString(),
                status: ride.status,
                type: 'STATUS_UPDATE'
            }
        });

        res.json({ success: true, ride });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.verifyRideOtp = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { otp } = req.body;

        let ride = await History.findById(rideId);
        let isLogistics = false;
        let isShuttle = false;

        if (!ride) {
            ride = await LogisticsBooking.findById(rideId);
            if (ride) {
                isLogistics = true;
            } else {
                ride = await ShuttleBooking.findById(rideId);
                if (ride) {
                    isShuttle = true;
                }
            }
        }

        if (!ride) {
            return res.status(404).json({ success: false, message: "Ride not found" });
        }

        const isSegmentRide = (isLogistics || isShuttle) && ride.segments && ride.segments.length > 0;

        if (isSegmentRide) {
            const Driver = require('../models/Driver');
            let driver;
            if (req.user) {
                const identifier = req.user.uid || req.user.id;
                if (mongoose.Types.ObjectId.isValid(identifier)) {
                    driver = await Driver.findById(identifier);
                }
                if (!driver) driver = await Driver.findOne({ uid: identifier });
                if (!driver) driver = await Driver.findOne({ firebaseId: identifier });
            }
            const driverId = driver ? driver._id.toString() : null;

            if (!driverId) {
                return res.status(401).json({ success: false, message: "Driver credentials not resolved." });
            }

            // Find the segment assigned to this driver that is pending or processing
            const activeSegIndex = ride.segments.findIndex(seg => 
                seg.driverId && 
                seg.driverId.toString() === driverId && 
                (seg.status === 'pending' || seg.status === 'processing')
            );

            if (activeSegIndex === -1) {
                return res.status(400).json({ success: false, message: "No active segment found assigned to this driver." });
            }

            const activeSegment = ride.segments[activeSegIndex];

            // If the booking status is in_transit, then the driver is verifying the final delivery OTP
            if (ride.status === 'in_transit') {
                const isLastSegment = (activeSegIndex === ride.segments.length - 1);
                if (!isLastSegment) {
                    return res.status(400).json({ success: false, message: "Intermediate segments do not require OTP verification to complete." });
                }

                // Verify final delivery OTP
                if (ride.otp !== otp) {
                    return res.status(400).json({ success: false, message: "Invalid Delivery OTP" });
                }

                ride.status = 'delivered';
                ride.segments[activeSegIndex].status = 'completed';
                await ride.save();

                res.json({ success: true, message: "OTP verified correctly. Shipment delivered successfully." });

                // Socket notification to user
                if (req.io) {
                    const targetUserRoom = resolveDocId(ride.userId);
                    if (targetUserRoom) {
                        req.io.to(targetUserRoom).to(ride._id.toString()).emit("ride_status_update", {
                            rideId: ride._id.toString(),
                            status: ride.status,
                            type: isShuttle ? 'SHUTTLE' : 'LOGISTICS'
                        });
                        req.io.to(targetUserRoom).to(ride._id.toString()).emit("roadmap_updated", {
                            rideId: ride._id.toString(),
                            segments: ride.segments
                        });
                    }
                }

                // Push notification to user
                const { notifyUser } = require('../utils/notificationService');
                notifyUser(resolveDocId(ride.userId), {
                    title: "Shipment Delivered",
                    body: "Your shipment has been successfully delivered!",
                    data: {
                        rideId: ride._id.toString(),
                        status: ride.status,
                        type: 'STATUS_UPDATE'
                    }
                });
                return;
            } else {
                // Starting the segment (status is confirmed / pending_for_driver)
                if (activeSegment.otp !== otp) {
                    return res.status(400).json({ success: false, message: "Invalid Segment OTP" });
                }

                ride.status = 'in_transit';
                ride.segments[activeSegIndex].status = 'processing';
                await ride.save();

                res.json({ success: true, message: "OTP verified correctly. Segment journey started." });

                // Socket notification to user
                if (req.io) {
                    const targetUserRoom = resolveDocId(ride.userId);
                    if (targetUserRoom) {
                        req.io.to(targetUserRoom).to(ride._id.toString()).emit("ride_status_update", {
                            rideId: ride._id.toString(),
                            status: ride.status,
                            type: isShuttle ? 'SHUTTLE' : 'LOGISTICS'
                        });
                        req.io.to(targetUserRoom).to(ride._id.toString()).emit("roadmap_updated", {
                            rideId: ride._id.toString(),
                            segments: ride.segments
                        });
                    }
                }

                // Push notification to user
                const { notifyUser } = require('../utils/notificationService');
                notifyUser(resolveDocId(ride.userId), {
                    title: "Segment Started",
                    body: `Segment ${activeSegIndex + 1} has started.`,
                    data: {
                        rideId: ride._id.toString(),
                        status: ride.status,
                        type: 'STATUS_UPDATE'
                    }
                });
                return;
            }
        }

        // Fallback for direct bookings or history (no segments)
        if (ride.otp !== otp) {
            return res.status(400).json({ success: false, message: "Invalid OTP" });
        }

        const isTransit = (isLogistics || isShuttle);
        ride.status = isTransit ? (ride.status === 'in_transit' ? 'delivered' : 'in_transit') : (ride.status === 'ongoing' ? 'completed' : 'ongoing');
        await ride.save();

        res.json({ success: true, message: "OTP verified correctly." });

        // Socket notification to user
        if (req.io) {
            const targetUserRoom = resolveDocId(ride.userId);
            if (targetUserRoom) {
                req.io.to(targetUserRoom).to(ride._id.toString()).emit("ride_status_update", {
                    rideId: ride._id.toString(),
                    status: ride.status,
                    type: isLogistics ? 'LOGISTICS' : (isShuttle ? 'SHUTTLE' : 'CAB')
                });
            }
        }

        // Push notification to user
        const { notifyUser } = require('../utils/notificationService');
        notifyUser(resolveDocId(ride.userId), {
            title: isTransit ? (ride.status === 'delivered' ? "Shipment Delivered" : "Shipment In Transit") : (ride.status === 'completed' ? "Ride Completed" : "Ride Started"),
            body: isTransit ? (ride.status === 'delivered' ? "Your items have been delivered!" : "Your items are now en route!") : (ride.status === 'completed' ? "OTP Verified. Thank you!" : "OTP Verified. Your journey has begun!"),
            data: {
                rideId: ride._id.toString(),
                status: ride.status,
                type: 'STATUS_UPDATE'
            }
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.updateFare = async (req, res) => {
    try {
        const { rideId, extraFare } = req.body;
        const ride = await History.findById(rideId);
        if (!ride) {
            return res.status(404).json({ success: false, message: "Ride not found" });
        }

        ride.fare += extraFare;
        await ride.save();

        res.json({ success: true, message: "Fare updated", fare: ride.fare });

        // Emit socket event to drivers
        if (req.io) {
            req.io.emit("fare_updated", {
                rideId: ride._id,
                newFare: ride.fare
            });
        }

        // Push notification to drivers
        const { notifyAllDrivers } = require('../utils/notificationService');
        notifyAllDrivers({
            title: "Fare Increased!",
            body: `Fare for ${ride.rideMode} ride increased to ₹${ride.fare}`,
            data: {
                rideId: ride._id.toString(),
                type: 'FARE_UPDATED'
            }
        });

    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.submitReview = async (req, res) => {
    try {
        const { bookingId, driverId, rating, comment } = req.body;
        const review = await Review.create({
            bookingId,
            fromId: req.user.id || req.user._id, // User ID from token
            toId: driverId,
            onModel: 'Driver',
            rating,
            comment
        });
        res.status(201).json({ success: true, data: review });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.payRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        let ride = await History.findById(rideId);
        let isLogistics = false;
        if (!ride) {
            const LogisticsBooking = require('../models/LogisticsBooking');
            ride = await LogisticsBooking.findById(rideId);
            isLogistics = !!ride;
        }
        if (!ride) return res.status(404).json({ success: false, message: "Ride not found" });

        ride.paymentStatus = 'paid';
        await ride.save();

        if (req.io) {
            // Signal to everyone in the ride room (User AND Driver)
            req.io.to(ride._id.toString()).emit("ride_status_update", {
                rideId: ride._id.toString(),
                paymentStatus: 'paid'
            });
            // Specific signal to driver to show feedback or QR
            req.io.to(ride._id.toString()).emit("payment_requested", {
                rideId: ride._id.toString(),
                amount: ride.fare || ride.totalPrice
            });
        }

        res.json({ success: true, message: "Payment successful", ride });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
