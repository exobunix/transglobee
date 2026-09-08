/**
 * Booking Status Lifecycle Enforcement
 *
 * Valid transitions (state machine):
 *
 * Logistics:
 *   pending → pending_for_driver → confirmed → processing → in_transit → delivered
 *   Any state → cancelled (with admin override)
 *
 * Rides (History):
 *   pending → accepted → on_the_way → arrived → ongoing → completed
 *   Any state → cancelled
 */

const LOGISTICS_TRANSITIONS = {
    pending:            ['pending_for_driver', 'confirmed', 'cancelled'],
    pending_for_driver: ['confirmed', 'processing', 'cancelled'],
    confirmed:          ['processing', 'in_transit', 'cancelled'],
    processing:         ['in_transit', 'cancelled'],
    in_transit:         ['delivered', 'cancelled'],
    delivered:          [],   // terminal
    cancelled:          [],   // terminal
};

const RIDE_TRANSITIONS = {
    pending:    ['accepted', 'cancelled'],
    accepted:   ['on_the_way', 'cancelled'],
    on_the_way: ['arrived', 'cancelled'],
    arrived:    ['ongoing', 'cancelled'],
    ongoing:    ['completed', 'cancelled'],
    completed:  [],
    cancelled:  [],
};

/**
 * Validate that a status transition is allowed.
 * @param {string} currentStatus
 * @param {string} newStatus
 * @param {'logistics'|'ride'} bookingType
 * @param {boolean} isAdminOverride  Admin can force any transition
 * @returns {{ allowed: boolean, reason?: string }}
 */
const validateTransition = (currentStatus, newStatus, bookingType = 'logistics', isAdminOverride = false) => {
    // Admins can override any transition (emergency cancellation, etc.)
    if (isAdminOverride) return { allowed: true };

    // Same status — no-op allowed
    if (currentStatus === newStatus) return { allowed: true };

    const table = bookingType === 'ride' ? RIDE_TRANSITIONS : LOGISTICS_TRANSITIONS;
    const allowed = table[currentStatus];

    if (!allowed) {
        return { allowed: false, reason: `Unknown current status: ${currentStatus}` };
    }

    if (!allowed.includes(newStatus)) {
        return {
            allowed: false,
            reason: `Cannot transition from "${currentStatus}" to "${newStatus}". Allowed next states: [${allowed.join(', ')}]`,
        };
    }

    return { allowed: true };
};

/**
 * Cancellation charge rules (time-based).
 * Returns the cancellation charge in rupees.
 *
 * @param {Date} bookingCreatedAt
 * @param {number} totalFare
 * @param {'logistics'|'ride'} bookingType
 * @returns {{ charge: number, reason: string }}
 */
const calculateCancellationCharge = (bookingCreatedAt, totalFare = 0, bookingType = 'logistics') => {
    const now = Date.now();
    const createdAt = new Date(bookingCreatedAt).getTime();
    const minutesSinceBooking = (now - createdAt) / 60000;

    if (bookingType === 'ride') {
        // Rides: free within 2 min, ₹50 within 5 min, 20% after
        if (minutesSinceBooking <= 2) return { charge: 0, reason: 'Free cancellation (within 2 minutes)' };
        if (minutesSinceBooking <= 5) return { charge: 50, reason: '₹50 fee (cancelled 2–5 minutes after booking)' };
        return { charge: Math.round(totalFare * 0.20), reason: '20% of fare (cancelled after 5 minutes)' };
    }

    // Logistics: free within 10 min, ₹100 within 1 hour, 10% after
    if (minutesSinceBooking <= 10) return { charge: 0, reason: 'Free cancellation (within 10 minutes)' };
    if (minutesSinceBooking <= 60) return { charge: 100, reason: '₹100 fee (cancelled within 1 hour)' };
    if (minutesSinceBooking <= 60 * 24) return { charge: Math.round(totalFare * 0.10), reason: '10% of fare (cancelled within 24 hours)' };
    return { charge: Math.round(totalFare * 0.25), reason: '25% of fare (cancelled after 24 hours)' };
};

module.exports = { validateTransition, calculateCancellationCharge, LOGISTICS_TRANSITIONS, RIDE_TRANSITIONS };
