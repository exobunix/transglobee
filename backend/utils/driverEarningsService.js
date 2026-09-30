const mongoose = require('mongoose');
const Driver = require('../models/Driver');
const Transaction = require('../models/Transaction');

/**
 * Resolves a Driver record from various identifier types (ObjectId, string id, uid, firebaseId)
 */
async function resolveDriver(driverId) {
    if (!driverId) return null;
    let driver = null;
    if (mongoose.Types.ObjectId.isValid(driverId)) {
        driver = await Driver.findById(driverId);
    }
    if (!driver) {
        driver = await Driver.findOne({
            $or: [
                { uid: String(driverId) },
                { firebaseId: String(driverId) },
                { mobileNumber: String(driverId) },
                { email: String(driverId) }
            ]
        });
    }
    return driver;
}

/**
 * Credits driver wallet & logs a completed Transaction when a ride or logistics booking is completed/delivered.
 * Idempotent: will not double-credit if a completed transaction already exists for this booking.
 */
async function creditDriverForCompletedBooking({
    booking,
    bookingType = 'ride', // 'ride' | 'logistics' | 'shuttle'
    driverId = null,
    actualFare = null,
    io = null
}) {
    try {
        if (!booking) return null;

        // Resolve Driver
        const targetDriverId = driverId || booking.driverId;
        const driver = await resolveDriver(targetDriverId);
        if (!driver) {
            console.warn(`[EARNINGS] Driver not found for booking ${booking._id}, driverId: ${targetDriverId}`);
            return null;
        }

        // Ensure booking has driverId linked as ObjectId
        booking.driverId = driver._id;
        if (!booking.driverSnapshot) {
            booking.driverSnapshot = {
                driver_id: driver._id.toString(),
                name: driver.name || 'Driver',
                phone: driver.mobileNumber || driver.phoneNumber || '',
                vehicle_number: driver.vehicleNumberPlate || 'N/A',
                vehicle_name: driver.vehicleModel || 'Vehicle',
                photo: driver.photo || ''
            };
        }

        // Calculate fare earned
        const fareEarned = Number(
            actualFare ?? 
            booking.actualFare ?? 
            booking.fare ?? 
            booking.totalPrice ?? 
            booking.vehiclePrice ?? 
            0
        );

        if (fareEarned <= 0) {
            console.warn(`[EARNINGS] Booking ${booking._id} has zero fare: ${fareEarned}`);
            return null;
        }

        // Set actualFare on booking if not set
        if (!booking.actualFare) {
            booking.actualFare = fareEarned;
        }
        if (!booking.completedAt) {
            booking.completedAt = new Date();
        }

        // Check if transaction already exists (Idempotency)
        let tx = await Transaction.findOne({
            bookingId: booking._id,
            status: 'completed',
            type: 'payment'
        });

        if (tx) {
            console.log(`[EARNINGS] Transaction already exists for booking ${booking._id}, txId: ${tx._id}`);
            return { driver, fareEarned, transaction: tx, alreadyCredited: true };
        }

        // 1. Increment Driver's Wallet Balance
        const updatedDriver = await Driver.findByIdAndUpdate(
            driver._id,
            { $inc: { walletBalance: fareEarned } },
            { new: true }
        );

        // 2. Create Transaction Record
        const userId = mongoose.Types.ObjectId.isValid(booking.userId) ? booking.userId : null;
        tx = await Transaction.create({
            userId,
            driverId: driver._id,
            bookingId: booking._id,
            amount: fareEarned,
            driverEarnings: fareEarned,
            type: 'payment',
            method: booking.paymentMode || 'wallet',
            status: 'completed',
            metadata: {
                bookingType,
                bookingId: booking._id.toString(),
                source: 'booking_completion',
                completedAt: new Date(),
                previousBalance: driver.walletBalance || 0,
                newBalance: updatedDriver ? updatedDriver.walletBalance : 0,
                fare: fareEarned
            }
        });

        console.log(`[EARNINGS] Successfully credited ₹${fareEarned} to driver ${driver.name} (${driver._id}). New Balance: ₹${updatedDriver?.walletBalance}`);

        // 3. Emit real-time socket events to driver
        if (io && updatedDriver) {
            const driverRoom = driver._id.toString();
            io.to(driverRoom).emit('wallet_balance_updated', {
                walletBalance: updatedDriver.walletBalance,
                balance: updatedDriver.walletBalance,
                amountAdded: fareEarned,
                bookingId: booking._id.toString()
            });
            io.to(driverRoom).emit('driver_earnings_updated', {
                driverId: driver._id.toString(),
                newBalance: updatedDriver.walletBalance,
                fareEarned,
                bookingId: booking._id.toString()
            });
        }

        return { driver: updatedDriver, fareEarned, transaction: tx, alreadyCredited: false };
    } catch (err) {
        console.error('[EARNINGS-ERROR] Failed to credit driver for completed booking:', err);
        return null;
    }
}

module.exports = {
    resolveDriver,
    creditDriverForCompletedBooking
};
