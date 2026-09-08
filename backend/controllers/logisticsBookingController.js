const LogisticsBooking = require('../models/LogisticsBooking');
const ShuttleBooking = require('../models/ShuttleBooking');
const { validateTransition, calculateCancellationCharge } = require('../utils/bookingLifecycle');
const {
    broadcastNewRideToOnlineDrivers,
    notifyAdminAndSupervisor,
    canDispatchToDrivers,
} = require('../utils/driverDispatch');
const {
    emitToRideParticipants,
    buildDriverSnapshot,
    formatDriverForClient,
} = require('../utils/userSocketRooms');

const normalizeLocation = (location, fallbackName, fallbackAddress) => {
    if (!location && !fallbackName && !fallbackAddress) {
        return null;
    }

    return {
        name: location?.name ?? fallbackName ?? fallbackAddress ?? 'Location',
        address: location?.address ?? fallbackAddress ?? fallbackName ?? 'Location',
        lat: Number(location?.lat ?? location?.latitude ?? 0),
        lng: Number(location?.lng ?? location?.longitude ?? 0),
    };
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

const normalizeDimension = (value, fallback = 1) => {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
    return parsed;
};

const normalizeItems = (items = [], fallbackWeight = 0) => {
    if (!Array.isArray(items)) return [];

    return items
        .map((item) => ({
            itemName: item?.itemName ?? item?.name ?? item?.goodsType ?? 'General Goods',
            type: item?.type ?? 'General',
            length: normalizeDimension(item?.length, 1),
            height: normalizeDimension(item?.height, 1),
            width: normalizeDimension(item?.width, 1),
            unit: item?.unit ?? 'cm',
            weight: normalizeDimension(item?.weight ?? fallbackWeight, Math.max(Number(fallbackWeight) || 1, 1)),
            quantity: Math.max(Number(item?.quantity ?? 1) || 1, 1),
        }))
        .filter((item) => item.itemName);
};

const normalizeAddressDetails = (address, fallbackLocation, expectedType) => {
    if (!address) return null;

    return {
        type: expectedType,
        label: address?.label ?? fallbackLocation?.name ?? expectedType,
        fullAddress: fallbackLocation?.address ?? address?.fullAddress ?? address?.label ?? '',
        houseNumber: address?.houseNumber ?? '',
        floorNumber: address?.floorNumber ?? '',
        landmark: address?.landmark ?? '',
        city: address?.city ?? '',
        pincode: address?.pincode ?? '',
        phone: address?.phone ?? '',
        email: address?.email ?? '',
    };
};

const validateItems = (items = []) => {
    if (!Array.isArray(items) || items.length === 0) {
        return 'At least one item is required.';
    }

    for (const item of items) {
        const itemName = item?.itemName ?? item?.name ?? item?.goodsType;
        if (!itemName || !String(itemName).trim()) {
            return 'Each item must have a valid item name.';
        }

        const length = Number(item?.length ?? 0);
        const width = Number(item?.width ?? 0);
        const height = Number(item?.height ?? 0);

        if (length <= 0 || width <= 0 || height <= 0) {
            return 'Each item must have length, width, and height greater than zero.';
        }
    }

    return null;
};

const GOODS_TYPES = [
    'Electronics',
    'Furniture',
    'Documents',
    'Perishables',
    'Machinery',
    'Textiles',
    'Chemicals',
    'Fragile',
    'Other',
];

// ─── POST /api/logistics-bookings  ──────────────────────
// Create a new logistics booking with all details
exports.createBooking = async (req, res) => {
    try {
        const {
            userId: bodyUserId,
            userName,
            userPhone,
            pickup,
            dropoff,
            pickupLocation,
            dropLocation,
            distanceKm,
            distance,
            vehicleType,
            vehiclePrice,
            items,
            helperCount,
            helperCost,
            additionalCharges,
            discountAmount,
            totalPrice,
            appliedCoupon,
            pickupAddress,
            receivedAddress,
            deliveryAddressDetails,
            segments,
            pickupName,
            dropName,
            modeOfTravel,
            price,
            weight,
            fare,
            bookingCategory: bodyCategory,
            type: bodyType,
        } = req.body;

        const bookingCategoryRaw = (bodyCategory || bodyType || 'logistics').toString().toLowerCase();
        const bookingCategory = bookingCategoryRaw === 'shuttle' ? 'shuttle' : 'logistics';
        const isShuttleBooking = bookingCategory === 'shuttle';

        const userId = bodyUserId || req.user?.uid || req.user?.id || req.user?.firebaseId;
        const pickupInput = pickup || pickupLocation;
        const dropoffInput = dropoff || dropLocation;

        if (pickupInput && (pickupInput.name === 'Current Location' || pickupInput.title === 'Current Location' || pickupInput.address === 'Current Location' || pickupInput.address === 'Using GPS')) {
            const resolved = await reverseGeocode(pickupInput.lat || pickupInput.latitude, pickupInput.lng || pickupInput.longitude);
            if (resolved) {
                pickupInput.address = resolved;
                pickupInput.name = resolved.split(',')[0];
                pickupInput.title = resolved.split(',')[0];
            }
        }
        if (dropoffInput && (dropoffInput.name === 'Current Location' || dropoffInput.title === 'Current Location' || dropoffInput.address === 'Current Location' || dropoffInput.address === 'Using GPS')) {
            const resolved = await reverseGeocode(dropoffInput.lat || dropoffInput.latitude, dropoffInput.lng || dropoffInput.longitude);
            if (resolved) {
                dropoffInput.address = resolved;
                dropoffInput.name = resolved.split(',')[0];
                dropoffInput.title = resolved.split(',')[0];
            }
        }

        const pickupTitle = pickupName || pickupInput?.title || pickupInput?.name;
        const dropTitle = dropName || dropoffInput?.title || dropoffInput?.name;

        const normalizedPickup = normalizeLocation(pickupInput, pickupTitle, pickupTitle);
        const normalizedDropoff = normalizeLocation(dropoffInput, dropTitle, dropTitle);
        const normalizedVehicleType = vehicleType ?? modeOfTravel ?? (isShuttleBooking ? 'Shuttle' : 'General');
        let normalizedItems = normalizeItems(items, weight);
        const normalizedVehiclePrice = Number(vehiclePrice ?? price ?? fare ?? totalPrice ?? 0);
        const normalizedTotalPrice = Number(totalPrice ?? price ?? fare ?? vehiclePrice ?? 0);
        const normalizedDistanceKm = Number(distanceKm ?? distance ?? 0);
        const normalizedPickupAddress = normalizeAddressDetails(
            pickupAddress || pickupInput,
            normalizedPickup,
            'pickup'
        );
        const normalizedReceivedAddress = normalizeAddressDetails(
            receivedAddress || deliveryAddressDetails || dropoffInput,
            normalizedDropoff,
            'received'
        );

        if (isShuttleBooking && normalizedItems.length === 0) {
            normalizedItems = [{
                itemName: 'Shuttle booking',
                type: 'Passenger',
                length: 1,
                width: 1,
                height: 1,
                unit: 'cm',
            }];
        }

        // Basic validation
        if (!userId || !normalizedPickup || !normalizedDropoff || !normalizedVehicleType) {
            console.warn('[LOGISTICS] Booking validation failed: missing required fields', {
                userId,
                hasPickup: !!normalizedPickup,
                hasDropoff: !!normalizedDropoff,
                vehicleType: normalizedVehicleType,
            });
            return res.status(400).json({
                success: false,
                message: 'userId, pickup, dropoff, and vehicleType are required.',
            });
        }

        if (
            String(normalizedPickup.address || '').trim().toLowerCase() ===
            String(normalizedDropoff.address || '').trim().toLowerCase()
        ) {
            console.warn('[LOGISTICS] Booking validation failed: pickup/dropoff identical', {
                userId,
                pickup: normalizedPickup.address,
                dropoff: normalizedDropoff.address,
            });
            return res.status(400).json({
                success: false,
                message: 'Pickup and drop locations must be different.',
            });
        }

        const itemsValidationError = isShuttleBooking ? null : validateItems(normalizedItems);
        if (itemsValidationError) {
            console.warn('[LOGISTICS] Booking validation failed: invalid items', {
                userId,
                vehicleType: normalizedVehicleType,
                error: itemsValidationError,
                items: normalizedItems,
            });
            return res.status(400).json({
                success: false,
                message: itemsValidationError,
            });
        }

        const booking = new LogisticsBooking({
            userId,
            userName:       userName       ?? req.user?.name ?? "Guest User",
            userPhone:      userPhone      ?? req.user?.phone_number ?? "",
            bookingCategory,
            pickup:         normalizedPickup,
            dropoff:        normalizedDropoff,
            distanceKm:     normalizedDistanceKm,
            vehicleType:    normalizedVehicleType,
            vehiclePrice:   normalizedVehiclePrice,
            items:          normalizedItems,
            helperCount:    helperCount    ?? 0,
            helperCost:     helperCost     ?? 0,
            additionalCharges: additionalCharges ?? 0,
            discountAmount: discountAmount ?? 0,
            totalPrice:     normalizedTotalPrice,
            appliedCoupon:  appliedCoupon  ?? null,
            pickupAddress:  normalizedPickupAddress,
            receivedAddress: normalizedReceivedAddress,
            segments:       segments       ?? [],
            status: 'pending',
            roadmapStatus: 'draft',
        });

        await booking.save();

        if (req.io) {
            const socketData = {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                type: isShuttleBooking ? 'SHUTTLE' : 'LOGISTICS',
                bookingCategory,
                status: 'pending',
                roadmapStatus: 'draft',
                pickup: booking.pickup?.address || 'Pickup',
                drop: booking.dropoff?.address || 'Dropoff',
                pick: booking.pickup?.address || 'Pickup',
                dropoff: booking.dropoff?.address || 'Dropoff',
                fare: booking.totalPrice,
                distance: `${booking.distanceKm || 0} km`,
                message: isShuttleBooking
                    ? 'New shuttle booking — awaiting roadmap approval'
                    : 'New logistics booking — awaiting roadmap approval',
            };
            // Logistics & shuttle: admin/supervisor only until roadmap is approved
            notifyAdminAndSupervisor(req.io, socketData);
        }

        return res.status(201).json({
            success: true,
            message: 'Logistics booking created successfully!',
            bookingId: booking._id,
            data: booking,
        });

    } catch (error) {
        console.error('Error creating logistics booking:', error);
        return res.status(500).json({
            success: false,
            message: 'Server error while creating booking.',
            error: error.message,
        });
    }
};

// ─── GET /api/logistics-bookings/user/:userId  ──────────
// Get all bookings for a specific user
exports.getUserBookings = async (req, res) => {
    try {
        const { userId } = req.params;
        const bookings = await LogisticsBooking.find({ userId }).sort({ createdAt: -1 });
        return res.status(200).json({ success: true, data: bookings });
    } catch (error) {
        console.error('Error fetching user bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/logistics-bookings  ───────────────────────
// Get all bookings (Admin)
exports.getAllBookings = async (req, res) => {
    try {
        // Use aggregation to join with the User collection
        // Since userId is a string, we lookup in the User collection's _id or uid field
        const bookings = await LogisticsBooking.aggregate([
            {
                $lookup: {
                    from: 'users',
                    localField: 'userId',
                    foreignField: 'uid', // Match with Firebase UID
                    as: 'userInfo'
                }
            },
            {
                $addFields: {
                    userName: { 
                        $ifNull: [ 
                            { $arrayElemAt: ['$userInfo.name', 0] },
                            { $ifNull: [ "$userName", "$userId" ] }
                        ] 
                    },
                    userPhone: {
                        $ifNull: [
                            { $arrayElemAt: ['$userInfo.mobileNumber', 0] },
                            { $ifNull: [ "$userPhone", "" ] }
                        ]
                    }
                }
            },
            {
                $lookup: {
                    from: 'drivers',
                    localField: 'driverId',
                    foreignField: '_id',
                    as: 'driverInfo',
                },
            },
            {
                $addFields: {
                    assignedDriver: { $arrayElemAt: ['$driverInfo', 0] },
                },
            },
            {
                $sort: { createdAt: -1 }
            },
            {
                $project: { userInfo: 0, driverInfo: 0 }
            }
        ]);

        console.log(`[LOGISTICS] Backend found ${bookings.length} total bookings with enriched user names.`);
        return res.status(200).json({ success: true, data: bookings });
    } catch (error) {
        console.error('Error fetching all bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/logistics-bookings/:id  ───────────────────
// Get a single booking by ID
exports.getBookingById = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findById(req.params.id)
            .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email')
            .populate('segments.driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email');
        let isShuttle = false;
        if (!booking) {
            booking = await ShuttleBooking.findById(req.params.id)
                .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email')
                .populate('segments.driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email');
            isShuttle = !!booking;
        }
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }
        const payload = booking.toObject();
        payload.assignedDriver = booking.driverId || booking.driverSnapshot || null;
        payload.type = isShuttle ? 'SHUTTLE' : (booking.bookingCategory || 'LOGISTICS').toUpperCase();
        return res.status(200).json({ success: true, data: payload });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/logistics-bookings/:id/status  ──────────
// Update booking status (Admin / Driver)
exports.updateStatus = async (req, res) => {
    try {
        const { status, adminOverride = false } = req.body;
        const allowed = ['pending', 'pending_for_driver', 'confirmed', 'processing', 'in_transit', 'delivered', 'cancelled'];
        if (!allowed.includes(status)) {
            return res.status(400).json({ success: false, message: 'Invalid status value.' });
        }

        // Fetch current booking for lifecycle validation
        let existing = await LogisticsBooking.findById(req.params.id);
        let isShuttle = false;
        if (!existing) {
            existing = await ShuttleBooking.findById(req.params.id);
            if (!existing) return res.status(404).json({ success: false, message: 'Booking not found.' });
            isShuttle = true;
        }

        // Enforce lifecycle transitions
        const { allowed: canTransition, reason } = validateTransition(
            existing.status, status, isShuttle ? 'shuttle' : 'logistics', adminOverride
        );
        if (!canTransition) {
            return res.status(422).json({ success: false, message: reason });
        }

        // Calculate cancellation charge if applicable
        let cancellationCharge = 0;
        if (status === 'cancelled') {
            const { charge } = calculateCancellationCharge(existing.createdAt, existing.totalPrice, isShuttle ? 'shuttle' : 'logistics');
            cancellationCharge = charge;
        }

        // Intercept intermediate segment completions
        if (status === 'delivered' && existing.segments && existing.segments.length > 0) {
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

            if (driverId) {
                // Find the active segment for this driver
                const activeSegIndex = existing.segments.findIndex(seg => 
                    seg.driverId && 
                    seg.driverId.toString() === driverId && 
                    seg.status === 'processing'
                );

                if (activeSegIndex !== -1) {
                    const isLastSegment = (activeSegIndex === existing.segments.length - 1);
                    if (isLastSegment) {
                        // Final segment completion requires OTP!
                        if (!adminOverride) {
                            return res.status(400).json({ 
                                success: false, 
                                message: "Verification OTP is required to complete final delivery." 
                            });
                        }
                    } else {
                        // Intermediate segment completion: mark segment completed
                        existing.segments[activeSegIndex].status = 'completed';
                        
                        // Set booking status to pending_for_driver so next driver can take over
                        existing.status = 'pending_for_driver';
                        
                        await existing.save();

                        // Notify User via Socket
                        if (req.io) {
                            req.io.to(existing.userId.toString()).emit("roadmap_updated", {
                                rideId: existing._id.toString(),
                                segments: existing.segments
                            });
                            req.io.to(existing.userId.toString()).emit("ride_status_update", {
                                rideId: existing._id.toString(),
                                status: existing.status,
                                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS'
                            });
                        }

                        return res.status(200).json({ 
                            success: true, 
                            message: `Segment ${activeSegIndex + 1} completed.`, 
                            data: existing 
                        });
                    }
                }
            }
        }

        const Model = isShuttle ? ShuttleBooking : LogisticsBooking;
        const booking = await Model.findByIdAndUpdate(
            req.params.id,
            { status, ...(cancellationCharge > 0 && { cancellationCharge }) },
            { new: true }
        );
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // --- Push Notification To User ---
        const { notifyUser } = require('../utils/notificationService');
        let bodyText = `Your shipment is now: ${status.toUpperCase()}`;
        if (status === 'confirmed') bodyText = "Your shipment has been confirmed by our team.";
        if (status === 'in_transit') bodyText = "Your shipment is now in transit!";
        if (status === 'delivered') bodyText = "Your shipment has been delivered successfully. Thank you for using Transglobe!";
        if (status === 'cancelled') bodyText = "Your shipment has been cancelled.";

        notifyUser(booking.userId, {
            title: "Shipment Update",
            body: bodyText,
            data: {
                bookingId: booking._id.toString(),
                status: booking.status,
                type: 'SHIPMENT_UPDATE'
            }
        });

        // Notify User via Socket
        if (req.io) {
            req.io.to(booking.userId.toString()).emit("ride_status_update", {
                rideId: booking._id.toString(),
                status: booking.status,
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS'
            });
        }

        return res.status(200).json({ success: true, message: 'Status updated.', data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/logistics-bookings/:id/assign ──────────
// Assign a driver to a logistics booking and notify them
exports.assignDriver = async (req, res) => {
    try {
        const { driverId, transportName, transportNumber, estimatedTime, estimatedDate, bookingId: bodyId } = req.body;
        const bookingId = req.params.id || bodyId;

        console.log(`[LOGISTICS-DISPATCH] Request for booking ${bookingId} with target: ${driverId}`);

        if (!bookingId) {
            return res.status(400).json({ success: false, message: 'Booking ID is required.' });
        }

        if (!driverId) {
            return res.status(400).json({ success: false, message: 'Assign target (driverId or "all") is required.' });
        }

        let updateData = {};
        if (driverId === 'all') {
            // General Dispatch
            updateData = { 
                driverId: null,
                status: 'pending_for_driver' 
            };
        } else {
            // Specific Assignment
            updateData = { 
                driverId: driverId,
                status: 'processing'
            };
        }

        // Add transport details if provided
        if (transportName) updateData.transportName = transportName;
        if (transportNumber) updateData.transportNumber = transportNumber;
        if (estimatedTime) updateData.estimatedTime = estimatedTime;
        if (estimatedDate) updateData.estimatedDate = estimatedDate;

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            updateData,
            { new: true }
        );

        if (!booking) {
            console.error(`[LOGISTICS-DISPATCH] Booking ${bookingId} not found!`);
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        console.log(`[LOGISTICS-DISPATCH] DB Updated. Status: ${booking.status}, Member: ${booking.driverId || 'ALL'}`);

        if (req.io) {
            const isShuttle = booking.bookingCategory === 'shuttle';
            const socketData = {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                pick: booking.pickup?.address || 'Pickup Location',
                drop: booking.dropoff?.address || 'Dropoff Location',
                pickupLat: booking.pickup?.lat ?? booking.pickup?.latitude,
                pickupLng: booking.pickup?.lng ?? booking.pickup?.longitude,
                dropLat: booking.dropoff?.lat ?? booking.dropoff?.latitude,
                dropLng: booking.dropoff?.lng ?? booking.dropoff?.longitude,
                distance: `${booking.distanceKm} km`,
                fare: booking.totalPrice || booking.vehiclePrice || 0,
                rideMode: booking.vehicleType || 'flatbed',
                status: booking.status,
                userId: booking.userId?.toString(),
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS',
                bookingCategory: booking.bookingCategory || 'logistics',
                railwayStation: booking.railwayStation,
                transportName: booking.transportName,
                transportNumber: booking.transportNumber,
                estimatedTime: booking.estimatedTime,
                estimatedDate: booking.estimatedDate,
            };

            if (!canDispatchToDrivers(booking)) {
                console.log('[LOGISTICS-DISPATCH] Skipping drivers — roadmap not approved yet.');
                notifyAdminAndSupervisor(req.io, {
                    ...socketData,
                    message: 'Driver assignment saved. Approve roadmap to notify drivers.',
                });
            } else if (driverId === 'all') {
                console.log('[LOGISTICS-DISPATCH] Broadcasting to all online drivers (roadmap approved).');
                await broadcastNewRideToOnlineDrivers(req.io, socketData);
            } else {
                console.log(`[LOGISTICS-DISPATCH] Sending to specific driver ${driverId}.`);
                req.io.to(driverId.toString()).emit('new_ride', socketData);
                req.io.to(driverId.toString()).emit('ride_assigned', {
                    bookingId: booking._id.toString(),
                    message: 'You have been assigned a new shipment.',
                });
            }
        }

        return res.status(200).json({ 
            success: true, 
            message: driverId === 'all' ? 'Order dispatched successfully.' : 'Driver assigned and notified successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error assigning driver:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/logistics-bookings/:id/roadmap/approve ───
// Approve roadmap and broadcast to all online drivers (shuttle + logistics)
exports.approveRoadmap = async (req, res) => {
    try {
        const bookingId = req.params.id;
        let booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { roadmapStatus: 'approved', status: 'pending_for_driver' },
            { new: true }
        );
        let isShuttle = false;
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                bookingId,
                { roadmapStatus: 'approved', status: 'pending_for_driver' },
                { new: true }
            );
            isShuttle = true;
        }
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        if (req.io) {
            const socketData = {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                pick: booking.pickup?.address || booking.pickup?.name || 'Pickup Location',
                drop: booking.dropoff?.address || booking.dropoff?.name || 'Dropoff Location',
                pickupLat: booking.pickup?.lat ?? booking.pickup?.latitude,
                pickupLng: booking.pickup?.lng ?? booking.pickup?.longitude,
                dropLat: booking.dropoff?.lat ?? booking.dropoff?.latitude,
                dropLng: booking.dropoff?.lng ?? booking.dropoff?.longitude,
                distance: `${booking.distanceKm || 0} km`,
                fare: booking.totalPrice || booking.vehiclePrice || 0,
                rideMode: booking.vehicleType || (isShuttle ? 'Shuttle' : 'flatbed'),
                status: 'pending_for_driver',
                roadmapStatus: 'approved',
                userId: booking.userId?.toString(),
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS',
                bookingCategory: isShuttle ? 'shuttle' : (booking.bookingCategory || 'logistics'),
                railwayStation: booking.railwayStation,
                transportName: booking.transportName,
                transportNumber: booking.transportNumber,
                estimatedTime: booking.estimatedTime,
                estimatedDate: booking.estimatedDate,
                message: isShuttle
                    ? 'Shuttle roadmap approved — available for drivers'
                    : 'Logistics roadmap approved — available for drivers',
            };

            await broadcastNewRideToOnlineDrivers(req.io, socketData, {
                pushTitle: isShuttle ? 'New shuttle job' : 'New logistics job',
                pushBody: `${socketData.pick} → ${socketData.drop}`,
            });
            notifyAdminAndSupervisor(req.io, socketData);
        }

        return res.status(200).json({
            success: true,
            message: 'Roadmap approved and booking sent to drivers.',
            data: booking,
        });
    } catch (error) {
        console.error('Error approving roadmap:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/logistics-bookings/:id/roadmap ──────────
// Update the entire roadmap (Multi-segment journey)
exports.updateRoadmap = async (req, res) => {
    try {
        const { segments } = req.body;
        const bookingId = req.params.id;

        if (!segments || !Array.isArray(segments)) {
            return res.status(400).json({ success: false, message: 'Valid segments array is required.' });
        }

        // Validate segment driver assignment requires addresses
        for (let i = 0; i < segments.length; i++) {
            const seg = segments[i];
            if (seg.driverId) {
                if (!seg.start || !seg.start.address || !seg.start.address.trim() ||
                    !seg.end || !seg.end.address || !seg.end.address.trim()) {
                    return res.status(400).json({
                        success: false,
                        message: `Cannot assign driver to segment ${i + 1} because its start or end address is empty.`
                    });
                }
            }
        }

        const generateOtp = () => Math.floor(1000 + Math.random() * 9000).toString();
        const segmentsWithOtps = (segments || []).map(seg => {
            if (!seg.otp) seg.otp = generateOtp();
            return seg;
        });

        let booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { segments: segmentsWithOtps },
            { new: true }
        );

        let isShuttle = false;
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                bookingId,
                { segments: segmentsWithOtps },
                { new: true }
            );
            isShuttle = true;
        }

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Notify User via Socket
        if (req.io) {
            req.io.to(booking.userId.toString()).emit("roadmap_updated", {
                rideId: bookingId,
                segments: booking.segments
            });
        }

        // Notify User via Push
        const { notifyUser } = require('../utils/notificationService');
        notifyUser(booking.userId, {
            title: "Journey Updated",
            body: "A supervisor has updated your shipment roadmap. Check the app for details.",
            data: {
                bookingId: booking._id.toString(),
                type: 'ROADMAP_UPDATE'
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: 'Roadmap updated successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error updating roadmap:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/logistics-bookings/:id/segment/:segmentId/assign ──────────
// Assign a driver to a specific segment
exports.assignSegmentDriver = async (req, res) => {
    try {
        const { driverId } = req.body;
        const { id: bookingId, segmentId } = req.params;

        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        const segment = booking.segments.id(segmentId);
        if (!segment) {
            return res.status(404).json({ success: false, message: 'Segment not found.' });
        }

        if (driverId) {
            if (!segment.start || !segment.start.address || !segment.start.address.trim() ||
                !segment.end || !segment.end.address || !segment.end.address.trim()) {
                return res.status(400).json({
                    success: false,
                    message: 'Cannot assign driver: segment start and end addresses must be filled.'
                });
            }
        }

        segment.driverId = driverId;
        segment.status = 'processing';
        await booking.save();

        // Populate segments.driverId before sending socket
        await booking.populate('segments.driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email');

        if (req.io) {
            if (driverId !== 'all') {
                req.io.to(driverId.toString()).emit("new_ride", {
                    id: booking._id.toString(),
                    segmentId: segmentId,
                    userName: booking.userName,
                    pick: segment.start.address,
                    drop: segment.end.address,
                    type: 'LOGISTICS_SEGMENT'
                });
            }
            // Also notify the user to update the roadmap timeline
            req.io.to(booking.userId.toString()).emit("roadmap_updated", {
                rideId: bookingId,
                segments: booking.segments
            });
        }

        return res.status(200).json({ 
            success: true, 
            message: 'Segment driver assigned.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error assigning segment driver:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/driver/pending-bookings ──────────────────
exports.getDriverPendingBookings = async (req, res) => {
    try {
        const dispatchableStatus = {
            $or: [
                { status: 'pending_for_driver' },
                { roadmapStatus: 'approved', status: { $nin: ['cancelled', 'delivered', 'completed', 'confirmed'] } },
            ],
        };

        // If authenticated, exclude bookings this driver already rejected, and fetch their location
        let mongoDriverId = null;
        let driverLat = null;
        let driverLng = null;
        if (req.user) {
            const driverId = req.user.uid || req.user.id;
            const mongoose = require('mongoose');
            const Driver = require('../models/Driver');

            mongoDriverId = driverId;
            let d = null;
            if (driverId && !mongoose.Types.ObjectId.isValid(driverId)) {
                d = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
                if (d) mongoDriverId = d._id;
            } else if (driverId) {
                d = await Driver.findById(driverId);
            }
            if (d && d.location && Array.isArray(d.location.coordinates) && d.location.coordinates.length >= 2) {
                driverLng = d.location.coordinates[0];
                driverLat = d.location.coordinates[1];
            }
        }

        const getDistance = (lat1, lon1, lat2, lon2) => {
            if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return null;
            const R = 6371; // km
            const dLat = (lat2 - lat1) * Math.PI / 180;
            const dLon = (lon2 - lon1) * Math.PI / 180;
            const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                      Math.sin(dLon/2) * Math.sin(dLon/2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            return R * c;
        };

        let logisticsQuery = { ...dispatchableStatus };
        let shuttleQuery = { ...dispatchableStatus };

        if (mongoDriverId) {
            logisticsQuery.rejectedBy = { $ne: mongoDriverId };
            shuttleQuery.rejectedBy = { $ne: mongoDriverId };
        }

        const History = require('../models/History');
        let cabQuery = { status: 'pending' };
        if (mongoDriverId) {
            cabQuery.rejectedBy = { $ne: mongoDriverId };
        }

        const [logistics, shuttles, cabRides] = await Promise.all([
            LogisticsBooking.find(logisticsQuery).sort({ createdAt: -1 }),
            ShuttleBooking.find(shuttleQuery).populate('routeId').sort({ createdAt: -1 }),
            History.find(cabQuery).populate('userId', 'name mobileNumber').sort({ createdAt: -1 }),
        ]);

        const formattedShuttles = shuttles.map(b => ({
            ...b.toObject(),
            bookingId: b._id,
            id: b._id.toString(),
            type: 'SHUTTLE',
            bookingCategory: 'shuttle',
            pickup: b.pickup || { address: b.pickupLocation || '' },
            dropoff: b.dropoff || { address: b.dropoffLocation || '' },
            status: b.status,
            roadmapStatus: b.roadmapStatus,
        }));

        const formattedCabs = cabRides.map((ride) => ({
            id: ride._id,
            userName: ride.userId?.name || 'Customer',
            phone: ride.mobileNumber,
            pick: ride.locations?.[0]?.address || '',
            drop: ride.locations?.[1]?.address || '',
            pickupLat: ride.locations?.[0]?.latitude,
            pickupLng: ride.locations?.[0]?.longitude,
            dropLat: ride.locations?.[1]?.latitude,
            dropLng: ride.locations?.[1]?.longitude,
            distance: ride.distance,
            fare: ride.fare,
            rideMode: ride.rideMode,
            vehicleType: ride.vehicleType || ride.rideMode,
            status: 'pending',
            type: 'CAB',
            bookingCategory: 'cab',
            userId: ride.userId?._id || ride.userId,
            createdAt: ride.createdAt,
        }));

        const bookings = [
            ...formattedCabs,
            ...logistics.map(b => ({
                ...b.toObject(),
                id: b._id.toString(),
                type: (b.bookingCategory === 'shuttle' ? 'SHUTTLE' : 'LOGISTICS'),
                bookingCategory: b.bookingCategory || 'logistics',
                status: b.status,
                roadmapStatus: b.roadmapStatus,
            })),
            ...formattedShuttles
        ];

        // Process distance
        const processedBookings = bookings.map(b => {
            let pickupLat = null;
            let pickupLng = null;

            if (b.type === 'CAB') {
                pickupLat = b.pickupLat;
                pickupLng = b.pickupLng;
            } else {
                pickupLat = b.pickup?.lat;
                pickupLng = b.pickup?.lng;
            }

            const distanceToDriver = getDistance(driverLat, driverLng, pickupLat, pickupLng);
            return {
                ...b,
                distanceToDriver
            };
        });

        // Filter: only show bookings within 50km if driver location is available
        let filteredBookings = processedBookings;
        if (driverLat != null && driverLng != null) {
            filteredBookings = processedBookings.filter(b => b.distanceToDriver === null || b.distanceToDriver <= 50);
        }

        // Sort: nearest first, fallback to latest first
        filteredBookings.sort((a, b) => {
            if (driverLat != null && driverLng != null) {
                const distA = a.distanceToDriver ?? Infinity;
                const distB = b.distanceToDriver ?? Infinity;
                if (distA !== distB) {
                    return distA - distB;
                }
            }
            return new Date(b.createdAt) - new Date(a.createdAt);
        });

        console.log(`[PENDING-BOOKINGS] Found ${filteredBookings.length} bookings (auth: ${req.user ? 'yes' : 'no'}, location: ${driverLat != null ? 'yes' : 'no'})`);
        return res.status(200).json({ success: true, bookings: filteredBookings });
    } catch (error) {
        console.error('Error fetching driver pending bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};


// ─── PATCH /api/booking/:id/accept ─────────────────────
exports.acceptBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const driverId = req.user.uid || req.user.id;
        const mongoose = require('mongoose');
        const Driver = require('../models/Driver');

        let mongoDriverId = driverId;
        let driver;
        if (!mongoose.Types.ObjectId.isValid(driverId)) {
            driver = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
            if (driver) mongoDriverId = driver._id;
        } else {
            driver = await Driver.findById(driverId);
        }

        const otp = Math.floor(1000 + Math.random() * 9000).toString();
        const driverSnapshot = buildDriverSnapshot(driver);

        let booking = await LogisticsBooking.findByIdAndUpdate(
            id,
            {
                status: 'confirmed',
                driverId: mongoDriverId,
                otp,
                driverSnapshot,
            },
            { new: true }
        );
        let isShuttle = false;
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                id,
                {
                    status: 'confirmed',
                    driverId: mongoDriverId,
                    otp,
                    driverSnapshot,
                },
                { new: true }
            );
            isShuttle = true;
        }

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        const driverPayload = formatDriverForClient(driverSnapshot || booking.driverSnapshot);

        if (req.io) {
            const acceptedPayload = {
                rideId: booking._id.toString(),
                status: 'confirmed',
                otp: booking.otp,
                fare: booking.totalPrice || booking.vehiclePrice,
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS',
                driver: driverPayload,
            };
            await emitToRideParticipants(req.io, booking, 'ride_accepted', acceptedPayload);
            await emitToRideParticipants(req.io, booking, 'ride_status_update', acceptedPayload);
            req.io.emit('ride_assigned', { rideId: booking._id.toString() });
            req.io.emit('admin_booking_updated', {
                bookingId: booking._id.toString(),
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS',
                status: booking.status,
                driver: driverPayload,
                assignedDriver: driverPayload,
            });
            req.io.emit('supervisor_booking_updated', {
                bookingId: booking._id.toString(),
                type: isShuttle ? 'SHUTTLE' : 'LOGISTICS',
                status: booking.status,
                driver: driverPayload,
                assignedDriver: driverPayload,
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Booking accepted.',
            data: {
                ...booking.toObject(),
                driver: driverPayload,
                assignedDriver: driverPayload,
            },
        });
    } catch (error) {
        console.error('Error accepting booking:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/booking/:id/reject ─────────────────────
exports.rejectBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const driverId = req.user.uid || req.user.id;
        const mongoose = require('mongoose');
        const Driver = require('../models/Driver');

        let mongoDriverId = driverId;
        if (!mongoose.Types.ObjectId.isValid(driverId)) {
            const d = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
            if (d) mongoDriverId = d._id;
        }

        let booking = await LogisticsBooking.findByIdAndUpdate(
            id,
            { $addToSet: { rejectedBy: mongoDriverId } },
            { new: true }
        );
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                id,
                { $addToSet: { rejectedBy: mongoDriverId } },
                { new: true }
            );
        }

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        return res.status(200).json({ success: true, message: 'Booking rejected.' });
    } catch (error) {
        console.error('Error rejecting booking:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/logistics-bookings/:id/railway-station ───
// Assign a railway station for train-based logistics (Admin)
exports.updateRailwayStation = async (req, res) => {
    try {
        const { stationName } = req.body;
        const bookingId = req.params.id;

        if (!stationName) {
            return res.status(400).json({ success: false, message: 'Station name is required.' });
        }

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { railwayStation: stationName },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        return res.status(200).json({ 
            success: true, 
            message: 'Railway station assigned successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error updating railway station:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PUT/PATCH /api/logistics-bookings/:id/billing ───
// Updates billing breakdown for a booking
exports.updateBilling = async (req, res) => {
    try {
        const { id } = req.params;
        const { 
            vehiclePrice, 
            helperCost, 
            additionalCharges, 
            discount,         // From user request
            discountAmount,   // Legacy/Existing
            totalPrice,       // Legacy/Existing
            totalAmount       // From user request
        } = req.body;

        const bookingId = id || req.params.id;
        console.log(`[BILLING-UPDATE] Processing request for: ${bookingId}`);

        // Fetch current booking
        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        // Restriction: Processing stage is read-only for admin
        if (booking.status === 'processing' || booking.status === 'confirmed') {
            console.warn(`[BILLING-UPDATE] Blocked: Booking ${bookingId} is in ${booking.status} state.`);
            return res.status(403).json({ 
                success: false, 
                message: 'Editing is disabled while the order is being processed by the driver.' 
            });
        }

        // Map fields safely (supporting both naming conventions)
        if (vehiclePrice !== undefined) booking.vehiclePrice = Number(vehiclePrice);
        if (helperCost !== undefined) booking.helperCost = Number(helperCost);
        if (additionalCharges !== undefined) booking.additionalCharges = Number(additionalCharges);
        
        // Handle discount/discountAmount
        if (discount !== undefined) booking.discountAmount = Number(discount);
        else if (discountAmount !== undefined) booking.discountAmount = Number(discountAmount);

        // Calculate or assign total
        if (totalAmount !== undefined) {
          booking.totalPrice = Number(totalAmount);
        } else if (totalPrice !== undefined) {
          booking.totalPrice = Number(totalPrice);
        } else {
          // Auto-calculate if not explicitly provided
          booking.totalPrice = booking.vehiclePrice + booking.helperCost + booking.additionalCharges - booking.discountAmount;
        }

        await booking.save();

        console.log(`[BILLING-UPDATE] Success. New Total: ₹${booking.totalPrice}`);

        return res.status(200).json({ 
            success: true, 
            message: 'Billing updated successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('[BILLING-UPDATE] Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PRD Compatibility APIs (/api/logistics/*) ──────────────────────────────

exports.estimateLogistics = async (req, res) => {
    try {
        const {
            distanceKm = 0,
            weightKg = 0,
            preferredMode = 'road',
            deliveryUrgency = 'standard',
            insuranceRequired = false,
            declaredValue = 0,
        } = req.body || {};

        const normalizedDistance = Math.max(Number(distanceKm) || 0, 0);
        const normalizedWeight = Math.max(Number(weightKg) || 0, 0);
        const mode = String(preferredMode || 'road').toLowerCase();
        const urgency = String(deliveryUrgency || 'standard').toLowerCase();

        const modeMultiplier = {
            road: 1,
            train: 0.85,
            air: 2.4,
            sea: 1.6,
            best_available: 1,
        }[mode] ?? 1;

        const urgencyMultiplier = {
            standard: 1,
            express: 1.25,
            same_day: 1.55,
        }[urgency] ?? 1;

        const baseCharge = 120;
        const distanceCharge = normalizedDistance * 14 * modeMultiplier;
        const weightCharge = normalizedWeight * 4.5 * modeMultiplier;
        const handlingCharge = normalizedWeight > 100 ? 250 : 80;
        const insuranceCharge = insuranceRequired
            ? Math.max(Number(declaredValue) || 0, 0) * 0.01
            : 0;

        const subtotal =
            (baseCharge + distanceCharge + weightCharge + handlingCharge + insuranceCharge) *
            urgencyMultiplier;
        const taxes = subtotal * 0.18;
        const estimatedPrice = Number((subtotal + taxes).toFixed(2));

        const etaHours = Math.max((normalizedDistance / 35) * modeMultiplier, 2);

        return res.status(200).json({
            success: true,
            data: {
                estimatedPrice,
                estimatedTransitHours: Number(etaHours.toFixed(1)),
                currency: 'INR',
                breakdown: {
                    baseCharge: Number(baseCharge.toFixed(2)),
                    distanceCharge: Number(distanceCharge.toFixed(2)),
                    weightCharge: Number(weightCharge.toFixed(2)),
                    handlingCharge: Number(handlingCharge.toFixed(2)),
                    insuranceCharge: Number(insuranceCharge.toFixed(2)),
                    taxes: Number(taxes.toFixed(2)),
                },
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.getLogisticsHistory = async (req, res) => {
    try {
        const userId = req.query.userId || req.user?.uid || req.user?.id;
        const page = Math.max(Number(req.query.page) || 1, 1);
        const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
        const skip = (page - 1) * limit;

        if (!userId) {
            return res.status(400).json({ success: false, message: 'userId is required.' });
        }

        const [bookings, total] = await Promise.all([
            LogisticsBooking.find({ userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
            LogisticsBooking.countDocuments({ userId }),
        ]);

        return res.status(200).json({
            success: true,
            data: bookings,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.trackLogisticsBooking = async (req, res) => {
    try {
        const booking = await LogisticsBooking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        const currentSegment =
            booking.segments?.find((segment) => segment.status === 'processing') || null;

        return res.status(200).json({
            success: true,
            data: {
                bookingId: booking._id,
                status: booking.status,
                pickup: booking.pickup,
                dropoff: booking.dropoff,
                currentSegment,
                segments: booking.segments || [],
                updatedAt: booking.updatedAt,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.cancelLogisticsBooking = async (req, res) => {
    try {
        req.body = { ...(req.body || {}), status: 'cancelled' };
        return exports.updateStatus(req, res);
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

exports.acceptRoadmap = async (req, res) => {
    if (!req.params.id && req.params.bookingId) {
        req.params.id = req.params.bookingId;
    }
    return exports.approveRoadmap(req, res);
};

exports.getGoodsTypes = async (_req, res) => {
    return res.status(200).json({ success: true, data: GOODS_TYPES });
};
