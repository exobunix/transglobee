const Driver = require('../models/Driver');
const { notifyAllDrivers } = require('./notificationService');

/**
 * Emit new_ride to every online driver's socket room (+ optional FCM).
 */
async function broadcastNewRideToOnlineDrivers(io, socketData, options = {}) {
    if (!io || !socketData) {
        return { sent: 0 };
    }

    // Determine target drivers. For CAB bookings, dispatch universally to all non-suspended drivers.
    const routeId = socketData.routeId || options.routeId;
    const isCab = (socketData.type === 'CAB' || socketData.type === 'RETAIL' || socketData.bookingCategory === 'cab');

    let targetDrivers = [];

    if (isCab) {
        // Universal Cab Dispatch: Send to ALL registered drivers who are not suspended
        targetDrivers = await Driver.find({ 
            status: { $ne: 'suspended' } 
        }).select('_id uid name fcmToken isOnline location').lean();
    } else {
        let query = { isOnline: true };
        if (routeId) {
            const Vehicle = require('../models/Vehicle');
            const vehicles = await Vehicle.find({ routes: routeId }).select('driverId').lean();
            const driverIds = vehicles.map(v => v.driverId?.toString()).filter(Boolean);
            query._id = { $in: driverIds };
        }
        targetDrivers = await Driver.find(query).select('_id uid name fcmToken location').lean();
        if (!targetDrivers.length) {
            targetDrivers = await Driver.find({ status: { $ne: 'suspended' } }).select('_id uid name fcmToken').lean();
        }
    }

    // Broadcast globally to all connected clients & drivers room
    io.emit('new_ride', socketData);
    io.to('drivers').emit('new_ride', socketData);

    // Also emit to individual driver rooms
    targetDrivers.forEach((driver) => {
        const roomId = driver._id.toString();
        io.to(roomId).emit('new_ride', socketData);
        if (driver.uid) {
            io.to(driver.uid).emit('new_ride', socketData);
        }
    });

    if (options.push !== false) {
        const label = isCab
            ? 'New cab ride'
            : (socketData.type === 'SHUTTLE' ? 'New shuttle job' : 'New logistics job');
        
        const tokens = targetDrivers.map(d => d.fcmToken).filter(Boolean);
        if (tokens.length > 0) {
            const { sendPushNotification } = require('./notificationService');
            await sendPushNotification(tokens, {
                title: options.pushTitle || label,
                body: options.pushBody || `${socketData.pick || 'Pickup'} → ${socketData.drop || 'Drop'}`,
                data: {
                    rideId: String(socketData.id || socketData.bookingId || ''),
                    type: String(socketData.type || 'CAB'),
                    bookingCategory: String(socketData.bookingCategory || socketData.type || ''),
                },
            });
        }
    }

    console.log(`[DISPATCH] new_ride sent to ${targetDrivers.length} driver(s) (${socketData.type})`);
    return { sent: targetDrivers.length };
}

/** Admin + supervisor dashboards only — never drivers. */
function notifyAdminAndSupervisor(io, socketData) {
    if (!io || !socketData) return;
    io.emit('admin_new_booking', socketData);
    io.emit('supervisor_new_booking', socketData);
    io.emit('new_booking', socketData);
}

/**
 * Logistics / shuttle: drivers only after roadmap is approved (or explicit pending_for_driver).
 */
function canDispatchToDrivers(booking) {
    if (!booking) return false;
    const status = String(booking.status || '').toLowerCase();
    const roadmap = String(booking.roadmapStatus || '').toLowerCase();
    if (roadmap && roadmap !== 'approved' && status !== 'pending_for_driver') {
        return false;
    }
    return status === 'pending_for_driver' || roadmap === 'approved';
}

function calculateHaversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of Earth in km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // Distance in km
}

module.exports = {
    broadcastNewRideToOnlineDrivers,
    notifyAdminAndSupervisor,
    canDispatchToDrivers,
};
