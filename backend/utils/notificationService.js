const admin = require('../config/firebase');
const mongoose = require('mongoose');
const Driver = require('../models/Driver');
const User = require('../models/User');

const sendPushNotification = async (tokens, payload) => {
    if (!tokens || tokens.length === 0) return;
    
    // Filter out empty strings
    const validTokens = tokens.filter(token => token && token.trim() !== '');
    if (validTokens.length === 0) return;

    const message = {
        notification: {
            title: payload.title,
            body: payload.body,
        },
        android: {
            priority: 'high',
            notification: {
                sound: 'default',
                channelId: 'transglobe_notifications',
                defaultSound: true,
                defaultVibrateTimings: true,
            },
        },
        apns: {
            payload: {
                aps: {
                    sound: 'default',
                    contentAvailable: true,
                },
            },
        },
        data: Object.fromEntries(
            Object.entries(payload.data || {}).map(([k, v]) => [k, String(v ?? '')])
        ),
        tokens: validTokens,
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} notifications; ${response.failureCount} failed.`);
        
        // Handle failures (e.g., remove invalid tokens)
        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(validTokens[idx]);
                }
            });
            console.warn('Failed tokens:', failedTokens);
        }
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
};

const Notification = require('../models/Notification');

const notifyAllDrivers = async (payload, io) => {
    try {
        const onlineDrivers = await Driver.find({ isOnline: true }).select('fcmToken uid firebaseId _id');
        const tokens = onlineDrivers.map(d => d.fcmToken).filter(t => t);
        await sendPushNotification(tokens, payload);

        if (io) {
            io.to('drivers').emit('new_notification', {
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                createdAt: new Date()
            });
        }
    } catch (error) {
        console.error('Error in notifyAllDrivers:', error);
    }
};

const notifyDriver = async (driverId, payload, io) => {
    try {
        const normalizedId = driverId?.toString?.() || '';
        if (!normalizedId) return;

        let driver = null;
        if (mongoose.Types.ObjectId.isValid(normalizedId)) {
            driver = await Driver.findById(normalizedId).select('fcmToken uid firebaseId');
        }
        if (!driver) {
            driver = await Driver.findOne({
                $or: [{ uid: normalizedId }, { firebaseId: normalizedId }],
            }).select('fcmToken uid firebaseId');
        }

        // Save in-app notification in DB
        try {
            await Notification.create({
                userId: normalizedId,
                role: 'driver',
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                type: payload.data?.type || 'ride',
                isRead: false
            });
        } catch (dbErr) {
            console.warn('Error creating driver notification document:', dbErr.message);
        }

        // Emit real-time drawer notification via socket
        if (io) {
            io.to(normalizedId).emit('new_notification', {
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                createdAt: new Date()
            });
            if (driver?.uid) {
                io.to(driver.uid).emit('new_notification', {
                    title: payload.title,
                    body: payload.body,
                    data: payload.data || {},
                    createdAt: new Date()
                });
            }
        }

        if (driver && driver.fcmToken) {
            await sendPushNotification([driver.fcmToken], payload);
        }
    } catch (error) {
        console.error('Error in notifyDriver:', error);
    }
};

const notifyUser = async (userId, payload, io) => {
    try {
        const normalizedUserId = userId?.toString?.() || '';
        if (!normalizedUserId) return;

        let user = null;
        if (mongoose.Types.ObjectId.isValid(normalizedUserId)) {
            user = await User.findById(normalizedUserId).select('fcmToken uid firebaseId');
        }

        if (!user) {
            user = await User.findOne({
                $or: [{ uid: normalizedUserId }, { firebaseId: normalizedUserId }],
            }).select('fcmToken uid firebaseId');
        }

        // Save in-app notification in DB
        try {
            await Notification.create({
                userId: normalizedUserId,
                role: 'user',
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                type: payload.data?.type || 'ride',
                isRead: false
            });
        } catch (dbErr) {
            console.warn('Error creating user notification document:', dbErr.message);
        }

        // Emit real-time drawer notification via socket
        if (io) {
            io.to(normalizedUserId).emit('new_notification', {
                title: payload.title,
                body: payload.body,
                data: payload.data || {},
                createdAt: new Date()
            });
            if (user?.uid) {
                io.to(user.uid).emit('new_notification', {
                    title: payload.title,
                    body: payload.body,
                    data: payload.data || {},
                    createdAt: new Date()
                });
            }
        }

        if (user && user.fcmToken) {
            await sendPushNotification([user.fcmToken], payload);
        }
    } catch (error) {
        console.error('Error in notifyUser:', error);
    }
};

const notifyAdmin = async (io, payload) => {
    try {
        await Notification.create({
            userId: 'admin',
            role: 'admin',
            title: payload.title,
            body: payload.body,
            data: payload.data || {},
            type: payload.data?.type || 'booking',
            isRead: false
        });
    } catch (dbErr) {
        console.warn('Error creating admin notification document:', dbErr.message);
    }

    if (!io) return;
    try {
        io.to('admin').emit('admin_notification', {
            title: payload.title,
            body: payload.body,
            data: payload.data || {},
            timestamp: new Date()
        });
        io.to('admin').emit('new_notification', {
            title: payload.title,
            body: payload.body,
            data: payload.data || {},
            createdAt: new Date()
        });
    } catch (e) {
        console.error('Error in notifyAdmin:', e);
    }
};

module.exports = {
    sendPushNotification,
    notifyAllDrivers,
    notifyDriver,
    notifyUser,
    notifyAdmin
};
