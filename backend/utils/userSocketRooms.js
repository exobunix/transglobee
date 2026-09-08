const mongoose = require('mongoose');
const User = require('../models/User');

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

const emitToRideParticipants = async (io, ride, event, payload) => {
    if (!io || !ride) return;
    const rooms = await resolveUserSocketRooms(ride);
    let emitter = io;
    rooms.forEach((room) => {
        emitter = emitter.to(room);
    });
    emitter.emit(event, payload);
};

const buildDriverSnapshot = (driver) => {
    if (!driver) return null;
    return {
        driver_id: driver._id,
        name: driver.name || 'Driver',
        phone: driver.mobileNumber || driver.phoneNumber || '',
        vehicle_number: driver.vehicleNumberPlate || 'N/A',
        vehicle_name: driver.vehicleModel || 'Vehicle',
        photo: driver.photo || driver.profilePic || '',
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

module.exports = {
    resolveUserSocketRooms,
    emitToRideParticipants,
    buildDriverSnapshot,
    formatDriverForClient,
};
