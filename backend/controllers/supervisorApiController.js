const mongoose = require('mongoose');
const LogisticsBooking = require('../models/LogisticsBooking');
const ShuttleBooking = require('../models/ShuttleBooking');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');   //add Vehicle schemmea 
const LiveTracking = require('../models/LiveTracking'); // add for for live Tracking 
const History = require('../models/History');

const generateOtp = () => Math.floor(1000 + Math.random() * 9000).toString();
const populateSegmentOtps = (segments) => {
    if (!segments || !Array.isArray(segments)) return segments;
    return segments.map(seg => {
        if (!seg.otp) {
            seg.otp = generateOtp();
        }
        return seg;
    });
};

exports.queue = async (req, res) => {
    try {
        const { origin, destination, urgency, mode, page = 1, limit = 20 } = req.query;
        const filter = { status: { $in: ['pending', 'pending_for_driver', 'processing', 'claimed'] } };
        if (origin) filter['pickup.address'] = new RegExp(origin, 'i');
        if (destination) filter['dropoff.address'] = new RegExp(destination, 'i');
        if (mode) filter.vehicleType = new RegExp(mode, 'i');
        if (urgency) filter.deliveryUrgency = urgency;

        const cabFilter = { status: { $in: ['pending', 'accepted', 'on_the_way', 'ongoing', 'arrived'] } };
        if (origin) cabFilter['locations.address'] = new RegExp(origin, 'i');
        if (destination) cabFilter['locations.address'] = new RegExp(destination, 'i');
        if (mode) cabFilter.rideMode = new RegExp(mode, 'i');

        const skip = (Number(page) - 1) * Number(limit);
        const [logistics, shuttles, cabs] = await Promise.all([
            LogisticsBooking.find(filter).sort({ createdAt: -1 }),
            ShuttleBooking.find(filter).populate('routeId').sort({ createdAt: -1 }),
            History.find(cabFilter).populate('userId').sort({ createdAt: -1 }),
        ]);

        let bookings = [
            ...logistics.map(b => ({ ...b.toObject(), type: 'LOGISTICS' })),
            ...shuttles.map(b => ({ ...b.toObject(), type: 'SHUTTLE' })),
            ...cabs.map(b => ({
                ...b.toObject(),
                type: 'CAB',
                bookingCategory: 'cab',
                userName: b.userId?.name || 'Customer',
                userPhone: b.mobileNumber || b.userId?.mobileNumber || '',
                pickup: { address: b.locations?.[0]?.address || b.locations?.[0]?.title || '' },
                dropoff: { address: b.locations?.[1]?.address || b.locations?.[1]?.title || '' },
                vehicleType: b.vehicleType || b.rideMode || 'Cab',
            }))
        ];

        bookings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        const total = bookings.length;
        const sliced = bookings.slice(skip, skip + Number(limit));

        return res.json({ success: true, bookings: sliced, total, page: Number(page), limit: Number(limit) });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.claimBooking = async (req, res) => {
    try {
        const actorId = req.user?.adminId || req.user?.id;
        const update = { status: 'claimed', claimedAt: new Date() };
        const claimableStatuses = ['pending', 'pending_for_driver', 'processing'];
        if (mongoose.Types.ObjectId.isValid(String(actorId || ''))) update.claimedBy = actorId;

        let booking = await LogisticsBooking.findOneAndUpdate(
            { _id: req.params.bookingId, status: { $in: claimableStatuses } },
            update,
            { new: true }
        );
        if (!booking) {
            booking = await ShuttleBooking.findOneAndUpdate(
                { _id: req.params.bookingId, status: { $in: claimableStatuses } },
                update,
                { new: true }
            );
        }
        if (!booking) {
            booking = await History.findOneAndUpdate(
                { _id: req.params.bookingId, status: { $in: ['pending', 'accepted'] } },
                update,
                { new: true }
            );
        }

        // Idempotent success: if booking already claimed, don't fail with 404.
        if (!booking) {
            booking = await LogisticsBooking.findOne({ _id: req.params.bookingId, status: 'claimed' });
            if (!booking) {
                booking = await ShuttleBooking.findOne({ _id: req.params.bookingId, status: 'claimed' });
            }
            if (!booking) {
                booking = await History.findOne({ _id: req.params.bookingId, status: 'claimed' });
            }
            if (booking) {
                return res.json({ success: true, message: 'Booking already claimed.', bookingId: booking._id });
            }
        }

        if (!booking) return res.status(404).json({ success: false, message: 'Claimable booking not found.' });
        return res.json({ success: true, message: 'Booking claimed successfully.', bookingId: booking._id });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.updateBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const updates = req.body;
        
        let booking = await LogisticsBooking.findByIdAndUpdate(bookingId, updates, { new: true });
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(bookingId, updates, { new: true });
        }
        if (!booking) {
            booking = await History.findByIdAndUpdate(bookingId, updates, { new: true });
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });
        
        return res.json({ success: true, message: 'Booking updated successfully.', booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.createRoadmap = async (req, res) => {
    try {
        const { bookingId, segments = [], totalPrice } = req.body;
        const segmentsWithOtps = populateSegmentOtps(segments);
        let booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { segments: segmentsWithOtps, totalPrice, status: 'processing', roadmapStatus: 'draft' },
            { new: true }
        );
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                bookingId,
                { segments: segmentsWithOtps, totalPrice, status: 'processing', roadmapStatus: 'draft' },
                { new: true }
            );
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });
        return res.status(201).json({ success: true, message: 'Roadmap created.', roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.getRoadmap = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findById(req.params.roadmapId).populate('driverId segments.driverId');
        if (!booking) {
            booking = await ShuttleBooking.findById(req.params.roadmapId).populate('driverId segments.driverId');
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Roadmap not found.' });
        return res.json({ success: true, roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.addSegment = async (req, res) => {
    try {
        const newSegment = { ...req.body, otp: req.body.otp || generateOtp() };
        let booking = await LogisticsBooking.findByIdAndUpdate(req.params.roadmapId, { $push: { segments: newSegment } }, { new: true });
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(req.params.roadmapId, { $push: { segments: newSegment } }, { new: true });
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Roadmap not found.' });
        return res.status(201).json({ success: true, roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.updateSegment = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findOneAndUpdate(
            { _id: req.params.roadmapId, 'segments._id': req.params.segId },
            { $set: Object.fromEntries(Object.entries(req.body).map(([key, value]) => [`segments.$.${key}`, value])) },
            { new: true }
        );
        if (!booking) {
            booking = await ShuttleBooking.findOneAndUpdate(
                { _id: req.params.roadmapId, 'segments._id': req.params.segId },
                { $set: Object.fromEntries(Object.entries(req.body).map(([key, value]) => [`segments.$.${key}`, value])) },
                { new: true }
            );
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Segment not found.' });
        return res.json({ success: true, roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.deleteSegment = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findByIdAndUpdate(req.params.roadmapId, { $pull: { segments: { _id: req.params.segId } } }, { new: true });
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(req.params.roadmapId, { $pull: { segments: { _id: req.params.segId } } }, { new: true });
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Roadmap not found.' });
        return res.json({ success: true, roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.approveRoadmap = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findByIdAndUpdate(
            req.params.roadmapId, 
            { roadmapStatus: 'approved', status: 'pending_for_driver' }, 
            { new: true }
        );
        let isShuttle = false;
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(
                req.params.roadmapId, 
                { roadmapStatus: 'approved', status: 'pending_for_driver' }, 
                { new: true }
            );
            isShuttle = true;
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Roadmap not found.' });

        if (req.io) {
            const socketData = {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                pick: booking.pickup?.address || booking.pickup?.name || 'Pickup Location',
                drop: booking.dropoff?.address || booking.dropoff?.name || 'Dropoff Location',
                pickupLat: booking.pickup?.latitude || booking.pickup?.lat,
                pickupLng: booking.pickup?.longitude || booking.pickup?.lng,
                dropLat: booking.dropoff?.latitude || booking.dropoff?.lat,
                dropLng: booking.dropoff?.longitude || booking.dropoff?.lng,
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

            const { broadcastNewRideToOnlineDrivers } = require('../utils/driverDispatch');
            await broadcastNewRideToOnlineDrivers(req.io, socketData, {
                pushTitle: isShuttle ? 'New shuttle job' : 'New logistics job',
                pushBody: `${socketData.pick} → ${socketData.drop}`,
            });
        }

        return res.json({ success: true, message: 'Roadmap approved and booking sent to drivers.', roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.adjustPricing = async (req, res) => {
    try {
        let booking = await LogisticsBooking.findByIdAndUpdate(req.params.roadmapId, { totalPrice: req.body.totalPrice }, { new: true });
        if (!booking) {
            booking = await ShuttleBooking.findByIdAndUpdate(req.params.roadmapId, { totalPrice: req.body.totalPrice }, { new: true });
        }
        if (!booking) return res.status(404).json({ success: false, message: 'Roadmap not found.' });
        return res.json({ success: true, roadmap: booking });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.availableDrivers = async (req, res) => {
    try {
        const { vehicleType, limit = 30, all } = req.query;
        const filter = { status: 'active' };
        if (all !== 'true') {
            filter.isOnline = true;
        }
        if (vehicleType) filter.vehicleModel = new RegExp(vehicleType, 'i');
        const drivers = await Driver.find(filter).limit(Number(limit)).select('-password');
        return res.json({ success: true, drivers });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

// Update Driver Status (Online/Offline) Api
exports.updateDriverStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { isOnline } = req.body;

        const driver = await Driver.findByIdAndUpdate(
            id,
            { 
                isOnline: isOnline ?? false,
                status: isOnline ? 'active' : 'offline'
            },
            { new: true }
        );

        if (!driver) {
            return res.status(404).json({
                success: false,
                message: 'Driver not found'
            });
        }

        // Notify the driver client via socket.io if connected
        if (req.io) {
            req.io.to(id).emit('status_change', {
                isOnline: isOnline ?? false,
                status: isOnline ? 'active' : 'offline'
            });
            console.log(`[STATUS-SYNC] Emitted status_change to driver ${id} (isOnline: ${isOnline})`);
        }

        return res.status(200).json({
            success: true,
            message: 'Driver status updated successfully',
            driver
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

exports.activeShipments = async (req, res) => {
    try {
        const [logistics, shuttles, cabs] = await Promise.all([
            LogisticsBooking.find({ status: { $in: ['confirmed', 'processing', 'in_transit'] } })
                .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate')
                .lean(),
            ShuttleBooking.find({ status: { $in: ['confirmed', 'processing', 'in_transit'] } })
                .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate')
                .lean(),
            History.find({ status: { $in: ['accepted', 'on_the_way', 'arrived', 'ongoing'] } })
                .populate('userId', 'name mobileNumber')
                .lean(),
        ]);

        const taggedLogistics = logistics.map(b => ({
            ...b,
            type: 'LOGISTICS',
            bookingCategory: 'logistics',
            userName: b.userName || 'Customer',
            userPhone: b.userPhone || '',
            pickup: b.pickup || { address: b.pickupAddress || '' },
            dropoff: b.dropoff || { address: b.receivedAddress || '' },
            vehicleType: b.vehicleType || 'Truck',
        }));

        const taggedShuttles = shuttles.map(b => ({
            ...b,
            type: 'SHUTTLE',
            bookingCategory: 'shuttle',
            userName: b.userName || 'Customer',
            userPhone: b.userPhone || '',
            pickup: b.pickup || { address: b.pickupAddress || '' },
            dropoff: b.dropoff || { address: b.receivedAddress || '' },
            vehicleType: b.vehicleType || 'Shuttle',
        }));

        const taggedCabs = cabs.map(b => ({
            ...b,
            type: 'CAB',
            bookingCategory: 'cab',
            userName: b.userId?.name || b.userName || 'Customer',
            userPhone: b.mobileNumber || b.userId?.mobileNumber || '',
            pickup: { address: b.locations?.[0]?.address || b.locations?.[0]?.title || '' },
            dropoff: { address: b.locations?.[1]?.address || b.locations?.[1]?.title || '' },
            vehicleType: b.vehicleType || b.rideMode || 'Cab',
        }));

        const combined = [...taggedLogistics, ...taggedShuttles, ...taggedCabs].sort(
            (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
        );

        res.status(200).json({
            success: true,
            total: combined.length,
            shipments: combined
        });
    } catch (error) {
        console.error('Active Shipments Error:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


// 1️⃣ Driver Status Overview API in Dasboard
exports.driverStatusOverview = async (req, res) => {
    try {

        const available = await Driver.countDocuments({
            isOnline: true,
            status: 'active'
        });

        const offline = await Driver.countDocuments({
            isOnline: false,
            status: 'active'
        });

        const suspended = await Driver.countDocuments({
            status: 'suspended'
        });

        const pending = await Driver.countDocuments({
            status: 'pending'
        });

        return res.status(200).json({
            success: true,
            data: {
                available,
                offline,
                suspended,
                pending
            }
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 2️⃣ Weekly Trip Graph API in Dasboard
exports.weeklyStats = async (req, res) => {
    try {

        const last7Days = new Date();
        last7Days.setDate(last7Days.getDate() - 7);

        const stats = await LogisticsBooking.aggregate([
            {
                $match: {
                    createdAt: { $gte: last7Days }
                }
            },
            {
                $group: {
                    _id: {
                        $dayOfWeek: "$createdAt"
                    },
                    trips: { $sum: 1 }
                }
            },
            {
                $sort: { _id: 1 }
            }
        ]);

        const daysMap = {
            1: 'Sun',
            2: 'Mon',
            3: 'Tue',
            4: 'Wed',
            5: 'Thu',
            6: 'Fri',
            7: 'Sat'
        };

        const formatted = stats.map(item => ({
            day: daysMap[item._id],
            trips: item.trips
        }));

        return res.status(200).json({
            success: true,
            data: formatted
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

/*********************************************************now API for Fleet**************************************************/ 

// 1 Get Fleet Vehicles API
exports.getFleetVehicles = async (req, res) => {
    try {

        const vehicles = await Vehicle.find()
            .populate('driverId', 'name email mobileNumber')
            // .populate('categoryId', 'name');
                .populate('routes', 'name source destination'); // ✅ Fixed

        return res.status(200).json({
            success: true,
            total: vehicles.length,
            vehicles
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 2 Add Vehicle API
exports.addVehicle = async (req, res) => {
    try {
        const { driverId, categoryId, make, model, year, vin, numberPlate, status } = req.body;

        if (!numberPlate) {
            return res.status(400).json({ success: false, message: 'Number Plate is required' });
        }

        let catId = categoryId;
        if (!catId) {
            const vehicleType = (req.body.type || 'cab').toLowerCase();
            const ServiceCategory = require('../models/ServiceCategory');
            const category = await ServiceCategory.findOne({ type: vehicleType });
            if (category) {
                catId = category._id;
            } else {
                const fallback = await ServiceCategory.findOne();
                if (fallback) catId = fallback._id;
                else return res.status(400).json({ success: false, message: 'No service categories found. Please create one first.' });
            }
        }

        const existingVehicle = await Vehicle.findOne({ numberPlate });

        if (existingVehicle) {
            return res.status(400).json({
                success: false,
                message: 'Vehicle already exists'
            });
        }

        let finalStatus = status || 'active';
        if (finalStatus === 'expired') finalStatus = 'active';

        const vehicle = await Vehicle.create({
            driverId: driverId || null,
            categoryId: catId,
            make,
            model,
            year,
            vin,
            numberPlate,
            status: finalStatus
        });

        return res.status(201).json({
            success: true,
            message: 'Vehicle added successfully',
            vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 2.5) Update Vehicle Api
exports.updateVehicle = async (req, res) => {
    try {
        const { id } = req.params;
        const { driverId, categoryId, make, model, year, vin, numberPlate, status } = req.body;

        let catId = categoryId;
        if (!catId && req.body.type) {
            const vehicleType = req.body.type.toLowerCase();
            const ServiceCategory = require('../models/ServiceCategory');
            const category = await ServiceCategory.findOne({ type: vehicleType });
            if (category) {
                catId = category._id;
            }
        }

        const updates = {
            make,
            model,
            year,
            vin,
            numberPlate,
        };

        if (driverId !== undefined) {
            updates.driverId = driverId || null;
        }
        if (catId) {
            updates.categoryId = catId;
        }
        if (status) {
            updates.status = status === 'expired' ? 'inactive' : status;
        }

        // Remove undefined fields
        Object.keys(updates).forEach(key => updates[key] === undefined && delete updates[key]);

        const vehicle = await Vehicle.findByIdAndUpdate(
            id,
            updates,
            { new: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Vehicle updated successfully',
            vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 3) Update Vechile Status Api  
exports.updateVehicleStatus = async (req, res) => {
    try {

        const { status } = req.body;

        const vehicle = await Vehicle.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Vehicle status updated',
            vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


// 4) Vehicle Location API/ 

exports.getVehicleLocation = async (req, res) => {
    try {

        const vehicle = await Vehicle.findById(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found'
            });
        }

        return res.status(200).json({
            success: true,
            location: vehicle.currentLocation
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


/*********************************************************** working For Live Tacking in in supervisor paneel**********************************/


//1) Create Update Driver Location API
 exports.updateLiveLocation = async (req, res) => {

    try {

        const {
            bookingId,
            driverId,
            latitude,
            longitude,
            heading,
            speed,
            status
        } = req.body;

        if (!bookingId || !driverId || !latitude || !longitude) {
            return res.status(400).json({
                success: false,
                message: 'bookingId, driverId, latitude, longitude required'
            });
        }

        const booking = await LogisticsBooking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        const driver = await Driver.findById(driverId);

        if (!driver) {
            return res.status(404).json({
                success: false,
                message: 'Driver not found'
            });
        }

        const tracking = await LiveTracking.findOneAndUpdate(
            { bookingId },

            {
                bookingId,
                driverId,
                latitude,
                longitude,
                heading,
                speed,
                status,
                lastUpdated: new Date()
            },

            {
                upsert: true,
                new: true
            }
        );

        // SOCKET EMIT
        if (req.io) {

            req.io.to(`tracking_${bookingId}`).emit('fleet_location_updated', {
                bookingId,
                driverId,
                latitude,
                longitude,
                heading,
                speed,
                status,
                updatedAt: new Date()
            });

        }

        res.status(200).json({
            success: true,
            message: 'Live location updated',
            data: tracking
        });

    } catch (error) {

        console.error('Update Live Location Error:', error);

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};


// 2)Get All Live Vehicles API

exports.getLiveFleet = async (req, res) => {

    try {

        const fleet = await LiveTracking.find()

            .populate(
                'driverId',
                'name mobileNumber vehicleModel vehicleNumberPlate isOnline'
            )

            .populate(
                'bookingId',
                'pickup dropoff status totalPrice'
            )

            .sort({ updatedAt: -1 });

        res.status(200).json({
            success: true,
            total: fleet.length,
            data: fleet
        });

    } catch (error) {

        console.error('Get Live Fleet Error:', error);

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 3)Get Single Shipment Tracking

exports.getShipmentTracking = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const tracking = await LiveTracking.findOne({ bookingId })
            .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email')
            .populate('bookingId');

        if (tracking) {
            return res.status(200).json({ success: true, data: tracking });
        }

        let booking = await LogisticsBooking.findById(bookingId)
            .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email location');
        if (!booking) {
            booking = await ShuttleBooking.findById(bookingId)
                .populate('driverId', 'name mobileNumber vehicleModel vehicleNumberPlate photo email location');
        }

        if (!booking) {
            return res.status(404).json({
                success: false,
                message: 'Tracking data not found',
            });
        }

        const driverDoc = booking.driverId;
        const snapshot = booking.driverSnapshot;
        const driverPayload = driverDoc || (snapshot
            ? {
                _id: snapshot.driver_id,
                name: snapshot.name,
                mobileNumber: snapshot.phone,
                vehicleModel: snapshot.vehicle_name,
                vehicleNumberPlate: snapshot.vehicle_number,
                photo: snapshot.photo,
            }
            : null);

        const coords = driverDoc?.location?.coordinates;
        return res.status(200).json({
            success: true,
            data: {
                bookingId: booking,
                driverId: driverPayload,
                status: booking.status,
                latitude: coords?.[1] || null,
                longitude: coords?.[0] || null,
            },
        });
    } catch (error) {
        console.error('Shipment Tracking Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 4)Get Active Shipments
exports.getActiveShipments = async (req, res) => {

    try {

        const shipments = await LogisticsBooking.find({
            status: {
                $in: ['confirmed', 'processing', 'in_transit']
            }
        })

        .populate(
            'driverId',
            'name mobileNumber vehicleModel vehicleNumberPlate'
        )

        .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            total: shipments.length,
            data: shipments
        });

    } catch (error) {

        console.error('Active Shipments Error:', error);

        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};