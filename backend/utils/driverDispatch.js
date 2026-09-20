const Driver = require('../models/Driver');
const { notifyAllDrivers } = require('./notificationService');

/**
 * Emit new_ride to every online driver's socket room (+ optional FCM).
 */
async function broadcastNewRideToOnlineDrivers(io, socketData, options = {}) {
    if (!io || !socketData) {
        return { sent: 0 };
    }

    // Determine target online drivers. If routeId is present, restrict to drivers assigned to vehicles running on this route.
    const routeId = socketData.routeId || options.routeId;
    const maxDistanceMeters = 10000; // 10 km radius
    const pickupLat = socketData.pickupLat !== undefined ? Number(socketData.pickupLat) : undefined;
    const pickupLng = socketData.pickupLng !== undefined ? Number(socketData.pickupLng) : undefined;

    let onlineDrivers = [];
    let query = { isOnline: true };

    if (routeId) {
        const Vehicle = require('../models/Vehicle');
        const vehicles = await Vehicle.find({ routes: routeId }).select('driverId').lean();
        const driverIds = vehicles.map(v => v.driverId?.toString()).filter(Boolean);
        query._id = { $in: driverIds };
    }

    if (pickupLat !== undefined && pickupLng !== undefined && !isNaN(pickupLat) && !isNaN(pickupLng)) {
        try {
            // Attempt geospatial query using MongoDB $near (requires 2dsphere index)
            const geoQuery = {
                ...query,
                location: {
                    $near: {
                        $geometry: {
                            type: 'Point',
                            coordinates: [pickupLng, pickupLat]
                        },
                        $maxDistance: maxDistanceMeters
                    }
                }
            };
            onlineDrivers = await Driver.find(geoQuery).select('_id uid name fcmToken location').lean();
        } catch (geoError) {
            console.error('[DISPATCH] Geospatial query failed, falling back to manual in-memory filtering:', geoError.message);
            // Fallback: Fetch all online drivers matching the query and filter manually in memory
            const allOnline = await Driver.find(query).select('_id uid name fcmToken location').lean();
            onlineDrivers = allOnline.filter(driver => {
                if (!driver.location || !driver.location.coordinates || driver.location.coordinates.length < 2) {
                    return false;
                }
                const [dLng, dLat] = driver.location.coordinates;
                const dist = calculateHaversineDistance(pickupLat, pickupLng, dLat, dLng);
                return dist <= (maxDistanceMeters / 1000.0);
            });
        }
    } else {
        onlineDrivers = await Driver.find(query).select('_id uid name fcmToken').lean();
    }

    // Fallback: If no drivers found within 10km radius or driver coordinates missing, dispatch to all online drivers
    if (!onlineDrivers.length) {
        console.log(`[DISPATCH] Broadening dispatch to all online drivers for ride ${socketData.id}`);
        onlineDrivers = await Driver.find({ isOnline: true }).select('_id uid name fcmToken').lean();
    }

    // Broadcast globally to connected drivers
    io.emit('new_ride', socketData);

    // Also emit to individual driver rooms
    onlineDrivers.forEach((driver) => {
        const roomId = driver._id.toString();
        io.to(roomId).emit('new_ride', socketData);
        if (driver.uid) {
            io.to(driver.uid).emit('new_ride', socketData);
        }
    });

    if (options.push !== false) {
        const label = socketData.type === 'CAB' || socketData.type === 'RETAIL'
            ? 'New cab ride'
            : (socketData.type === 'SHUTTLE' ? 'New shuttle job' : 'New logistics job');
        
        const tokens = onlineDrivers.map(d => d.fcmToken).filter(t => t);
        if (tokens.length > 0) {
            const { sendPushNotification } = require('./notificationService');
            await sendPushNotification(tokens, {
                title: options.pushTitle || label,
                body: options.pushBody || `${socketData.pick || 'Pickup'} → ${socketData.drop || 'Drop'}`,
                data: {
                    rideId: String(socketData.id || ''),
                    type: String(socketData.type || 'CAB'),
                    bookingCategory: String(socketData.bookingCategory || socketData.type || ''),
                },
            });
        }
    }

    console.log(`[DISPATCH] new_ride sent to ${onlineDrivers.length} online driver(s) (${socketData.type}) for route: ${routeId || 'all'}`);
    return { sent: onlineDrivers.length };
}

/** Admin + supervisor dashboards only — never drivers. */
function notifyAdminAndSupervisor(io, socketData) {
    if (!io || !socketData) return;
    io.emit('admin_new_booking', socketData);
    io.emit('supervisor_new_booking', socketData);
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
