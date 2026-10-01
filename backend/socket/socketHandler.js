const { Server } = require("socket.io");
const Message = require("../models/Message");
const Booking = require("../models/Booking");

const initSocket = (server) => {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        },
    });

    console.log("Socket.io initialized");

    io.on("connection", (socket) => {
        console.log("A user connected:", socket.id);

        // Join personal room based on userId for targeted messaging
        socket.on("register", async (data) => {
            const userId = typeof data === 'string' ? data : data.userId;
            const name = typeof data === 'object' ? data.name : "User";
            if (userId) {
                socket.join(userId);
                console.log(`User ${userId} (${name}) registered and joined room`);

                // Auto-join alternate rooms (MongoDB _id and Firebase uid) to prevent ID mismatch
                try {
                    const User = require('../models/User');
                    const Driver = require('../models/Driver');
                    const mongoose = require('mongoose');

                    let userOrDriver = null;
                    if (mongoose.Types.ObjectId.isValid(userId)) {
                        userOrDriver = await User.findById(userId);
                    }
                    if (!userOrDriver) {
                        userOrDriver = await User.findOne({ uid: userId });
                    }
                    if (!userOrDriver) {
                        if (mongoose.Types.ObjectId.isValid(userId)) {
                            userOrDriver = await Driver.findById(userId);
                        }
                        if (!userOrDriver) {
                            userOrDriver = await Driver.findOne({
                                $or: [{ uid: userId }, { firebaseId: userId }]
                            });
                        }
                    }

                    if (userOrDriver) {
                        const dbId = userOrDriver._id.toString();
                        const fbId = userOrDriver.uid || userOrDriver.firebaseId;
                        if (dbId && dbId !== userId) {
                            socket.join(dbId);
                            console.log(`Socket ${socket.id} also joined DB ID room: ${dbId}`);
                        }
                        if (fbId && fbId !== userId) {
                            socket.join(fbId);
                            console.log(`Socket ${socket.id} also joined FB ID room: ${fbId}`);
                        }
                        // If driver, auto-join 'drivers' room
                        const isDriver = await Driver.exists({ _id: userOrDriver._id });
                        if (isDriver) {
                            socket.join('drivers');
                            console.log(`Socket ${socket.id} auto-joined 'drivers' room`);
                        }
                    }
                } catch (err) {
                    console.error("Error joining secondary rooms:", err);
                }

                socket.emit("connection_success", { 
                    userId,
                    name
                });
            }
        });

        socket.on("join_drivers", (data) => {
            socket.join("drivers");
            console.log(`Socket ${socket.id} joined 'drivers' room via join_drivers event`);
        });

        // Add this new one in soket io for live tracking
        // JOIN LOGISTICS TRACKING ROOM
        socket.on("join_tracking", (bookingId) => {

        socket.join(`tracking_${bookingId}`);

        console.log(`Socket joined tracking room: tracking_${bookingId}`);
    });

// });

        // Join specific ride room
        socket.on("join_ride", (rideId) => {
            if (rideId) {
                socket.join(rideId);
                console.log(`Socket ${socket.id} joined ride room: ${rideId}`);
            }
        });

        // Update Fare and Notify User
        socket.on("update_fare", async (data) => {
            const { rideId, amount, newFare } = data;
            try {
                // Update in database
                await Booking.findByIdAndUpdate(rideId, { fare: newFare });
                
                // Notify user in the ride room
                io.to(rideId).emit("fare_increased", {
                    rideId,
                    amount,
                    newFare,
                    message: `Driver has increased the fare by ₹${amount}. New fare is ₹${newFare}.`
                });
                
                console.log(`Fare updated for ride ${rideId}: +${amount} (Total: ${newFare})`);
            } catch (error) {
                console.error("Error updating fare:", error);
                socket.emit("fare_error", { error: "Failed to update fare" });
            }
        });

        // Send and Persist Message
        socket.on("send_message", async (data) => {
            const { senderId, receiverId, message, senderRole, senderName } = data;
            const bId = data.bookingId || data.rideId;

            try {
                // Save to MongoDB with bookingId
                const newMessage = await Message.create({
                    senderId: senderId ? String(senderId) : 'unknown',
                    receiverId: receiverId ? String(receiverId) : 'unknown',
                    message,
                    senderRole: senderRole || 'unknown',
                    bookingId: bId ? String(bId) : null
                });

                // Resolve all alternate rooms for sender and receiver to ensure delivery
                const User = require('../models/User');
                const Driver = require('../models/Driver');
                const mongoose = require('mongoose');

                const getTargetRooms = async (id) => {
                    const rooms = [];
                    if (!id) return rooms;
                    const idStr = String(id).trim();
                    if (!idStr || idStr === 'undefined' || idStr === 'null') return rooms;
                    rooms.push(idStr);
                    
                    let entity = null;
                    try {
                        if (mongoose.Types.ObjectId.isValid(idStr)) {
                            entity = await User.findById(idStr);
                        }
                        if (!entity) {
                            entity = await User.findOne({ uid: idStr });
                        }
                        if (!entity) {
                            if (mongoose.Types.ObjectId.isValid(idStr)) {
                                entity = await Driver.findById(idStr);
                            }
                            if (!entity) {
                                entity = await Driver.findOne({
                                    $or: [{ uid: idStr }, { firebaseId: idStr }]
                                });
                            }
                        }

                        if (entity) {
                            const dbId = entity._id ? entity._id.toString() : null;
                            const fbId = entity.uid || entity.firebaseId;
                            if (dbId && !rooms.includes(dbId)) rooms.push(dbId);
                            if (fbId && !rooms.includes(fbId)) rooms.push(fbId);
                        }
                    } catch (e) {
                        console.error('Error resolving entity rooms:', e);
                    }
                    return rooms;
                };

                const senderRooms = await getTargetRooms(senderId);
                const receiverRooms = await getTargetRooms(receiverId);

                // Build unique target rooms
                const targetRooms = new Set();
                senderRooms.forEach(r => { if (r) targetRooms.add(String(r)); });
                receiverRooms.forEach(r => { if (r) targetRooms.add(String(r)); });
                if (bId) {
                    targetRooms.add(String(bId));
                    targetRooms.add(`tracking_${String(bId)}`);
                }

                const msgPayload = {
                    _id: newMessage._id,
                    senderId: String(senderId),
                    receiverId: String(receiverId),
                    message,
                    senderRole: senderRole || 'unknown',
                    senderName,
                    bookingId: bId ? String(bId) : null,
                    timestamp: newMessage.createdAt
                };

                // Emit to every resolved room
                targetRooms.forEach(room => {
                    io.to(room).emit("receive_message", msgPayload);
                });
                // Also ensure socket that emitted gets the event back
                socket.emit("receive_message", msgPayload);

                // Push notification fallback for background/closed app
                try {
                    const { notifyDriver, notifyUser } = require('../utils/notificationService');
                    if (senderRole === 'user' && receiverId) {
                        notifyDriver(receiverId, {
                            title: `New message from ${senderName || 'Passenger'}`,
                            body: message,
                            data: {
                                type: 'CHAT_MESSAGE',
                                senderId: String(senderId),
                                receiverId: String(receiverId),
                                bookingId: bId ? String(bId) : ''
                            }
                        });
                    } else if (senderRole === 'driver' && receiverId) {
                        notifyUser(receiverId, {
                            title: `New message from ${senderName || 'Driver'}`,
                            body: message,
                            data: {
                                type: 'CHAT_MESSAGE',
                                senderId: String(senderId),
                                receiverId: String(receiverId),
                                bookingId: bId ? String(bId) : ''
                            }
                        });
                    }
                } catch (notifErr) {
                    console.error("Error sending push notification for chat message:", notifErr);
                }

                // Confirmation back to sender
                socket.emit("message_sent", {
                    status: "success",
                    messageId: newMessage._id,
                    timestamp: newMessage.createdAt
                });

            } catch (error) {
                console.error("Error saving/sending message:", error);
                socket.emit("message_error", { error: "Failed to send message" });
            }
        });

        // Edit Message
        socket.on("edit_message", async ({ messageId, newMessage, receiverId }) => {
            try {
                const msg = await Message.findByIdAndUpdate(messageId, { message: newMessage, isEdited: true }, { new: true });
                if (msg) {
                    const targetRooms = [receiverId, msg.senderId, msg.bookingId].filter(Boolean);
                    targetRooms.forEach(r => {
                        io.to(String(r)).emit("message_edited", {
                            messageId,
                            newMessage,
                            receiverId,
                            senderId: msg.senderId
                        });
                    });
                }
            } catch (error) { console.error("Edit error:", error); }
        });

        // Delete Message
        socket.on("delete_message", async ({ messageId, receiverId }) => {
            try {
                const msg = await Message.findByIdAndUpdate(messageId, { isDeleted: true, message: "This message was deleted" }, { new: true });
                if (msg) {
                    const targetRooms = [receiverId, msg.senderId, msg.bookingId].filter(Boolean);
                    targetRooms.forEach(r => {
                        io.to(String(r)).emit("message_deleted", {
                            messageId,
                            receiverId,
                            senderId: msg.senderId
                        });
                    });
                }
            } catch (error) { console.error("Delete error:", error); }
        });

        // Fetch Chat History
        socket.on("fetch_history", async (data) => {
            const { userId1, userId2 } = data || {};
            const bId = data?.bookingId || data?.rideId;

            try {
                const User = require('../models/User');
                const Driver = require('../models/Driver');
                const mongoose = require('mongoose');

                const getIds = async (id) => {
                    const ids = [];
                    if (!id) return ids;
                    const idStr = String(id).trim();
                    if (!idStr || idStr === 'undefined' || idStr === 'null') return ids;
                    ids.push(idStr);
                    
                    let entity = null;
                    try {
                        if (mongoose.Types.ObjectId.isValid(idStr)) {
                            entity = await User.findById(idStr);
                        }
                        if (!entity) {
                            entity = await User.findOne({ uid: idStr });
                        }
                        if (!entity) {
                            if (mongoose.Types.ObjectId.isValid(idStr)) {
                                entity = await Driver.findById(idStr);
                            }
                            if (!entity) {
                                entity = await Driver.findOne({
                                    $or: [{ uid: idStr }, { firebaseId: idStr }]
                                });
                            }
                        }

                        if (entity) {
                            const dbId = entity._id ? entity._id.toString() : null;
                            const fbId = entity.uid || entity.firebaseId;
                            if (dbId && !ids.includes(dbId)) ids.push(dbId);
                            if (fbId && !ids.includes(fbId)) ids.push(fbId);
                        }
                    } catch (e) {}
                    return ids;
                };

                const ids1 = await getIds(userId1);
                const ids2 = await getIds(userId2);

                const queryConditions = [];
                if (ids1.length > 0 && ids2.length > 0) {
                    queryConditions.push({ senderId: { $in: ids1 }, receiverId: { $in: ids2 } });
                    queryConditions.push({ senderId: { $in: ids2 }, receiverId: { $in: ids1 } });
                }
                if (bId) {
                    queryConditions.push({ bookingId: String(bId) });
                }

                if (queryConditions.length === 0) {
                    socket.emit("chat_history", []);
                    return;
                }

                const history = await Message.find({ $or: queryConditions }).sort({ createdAt: 1 });
                socket.emit("chat_history", history);
            } catch (error) {
                console.error("Error fetching history:", error);
            }
        });

        // Driver Location Updates
        socket.on("update_location", (data) => {
            const { rideId, userId, latitude, longitude, heading } = data || {};
            if (!rideId) return;

            const lat = Number(latitude);
            const lng = Number(longitude);
            if (isNaN(lat) || isNaN(lng) || (lat === 0 && lng === 0)) return;

            const updatePayload = {
                rideId: String(rideId),
                latitude: lat,
                longitude: lng,
                heading: heading != null ? Number(heading) : 0,
                timestamp: new Date()
            };

            // Broadcast to ride room, tracking room, and userId room
            io.to(String(rideId)).emit("driver_location_update", updatePayload);
            io.to(`tracking_${String(rideId)}`).emit("driver_location_update", updatePayload);
            if (userId) {
                io.to(String(userId)).emit("driver_location_update", updatePayload);
            }
        });

        socket.on("disconnect", () => {
            console.log("User disconnected:", socket.id);
        });
    });

    return io;
};

module.exports = initSocket;
