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

            try {
                // Save to MongoDB
                const newMessage = await Message.create({
                    senderId,
                    receiverId,
                    message,
                    senderRole: senderRole || 'unknown'
                });

                // Resolve all alternate rooms for sender and receiver to ensure delivery
                const User = require('../models/User');
                const Driver = require('../models/Driver');
                const mongoose = require('mongoose');

                const getTargetRooms = async (id) => {
                    const rooms = [id];
                    if (!id) return rooms;
                    
                    let entity = null;
                    if (mongoose.Types.ObjectId.isValid(id)) {
                        entity = await User.findById(id);
                    }
                    if (!entity) {
                        entity = await User.findOne({ uid: id });
                    }
                    if (!entity) {
                        if (mongoose.Types.ObjectId.isValid(id)) {
                            entity = await Driver.findById(id);
                        }
                        if (!entity) {
                            entity = await Driver.findOne({
                                $or: [{ uid: id }, { firebaseId: id }]
                            });
                        }
                    }

                    if (entity) {
                        const dbId = entity._id.toString();
                        const fbId = entity.uid || entity.firebaseId;
                        if (dbId && !rooms.includes(dbId)) rooms.push(dbId);
                        if (fbId && !rooms.includes(fbId)) rooms.push(fbId);
                    }
                    return rooms;
                };

                const senderRooms = await getTargetRooms(senderId);
                const receiverRooms = await getTargetRooms(receiverId);

                // Build emission target
                let emitter = io;
                senderRooms.forEach(r => { emitter = emitter.to(r); });
                receiverRooms.forEach(r => { emitter = emitter.to(r); });

                emitter.emit("receive_message", {
                    _id: newMessage._id,
                    senderId,
                    receiverId,
                    message,
                    senderName,
                    timestamp: newMessage.createdAt
                });

                // Also emit back to sender (for confirmation/multi-device sync)
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
                    // Emit to both to keep all sessions in sync
                    io.to(receiverId).to(msg.senderId).emit("message_edited", {
                        messageId,
                        newMessage,
                        receiverId,
                        senderId: msg.senderId
                    });
                }
            } catch (error) { console.error("Edit error:", error); }
        });

        // Delete Message
        socket.on("delete_message", async ({ messageId, receiverId }) => {
            try {
                const msg = await Message.findByIdAndUpdate(messageId, { isDeleted: true, message: "This message was deleted" }, { new: true });
                if (msg) {
                    // Emit to both to keep all sessions in sync
                    io.to(receiverId).to(msg.senderId).emit("message_deleted", {
                        messageId,
                        receiverId,
                        senderId: msg.senderId
                    });
                }
            } catch (error) { console.error("Delete error:", error); }
        });

        // Fetch Chat History (Optional but useful for UI)
        socket.on("fetch_history", async ({ userId1, userId2 }) => {
            try {
                const User = require('../models/User');
                const Driver = require('../models/Driver');
                const mongoose = require('mongoose');

                const getIds = async (id) => {
                    const ids = [id];
                    if (!id) return ids;
                    
                    let entity = null;
                    if (mongoose.Types.ObjectId.isValid(id)) {
                        entity = await User.findById(id);
                    }
                    if (!entity) {
                        entity = await User.findOne({ uid: id });
                    }
                    if (!entity) {
                        if (mongoose.Types.ObjectId.isValid(id)) {
                            entity = await Driver.findById(id);
                        }
                        if (!entity) {
                            entity = await Driver.findOne({
                                $or: [{ uid: id }, { firebaseId: id }]
                            });
                        }
                    }

                    if (entity) {
                        const dbId = entity._id.toString();
                        const fbId = entity.uid || entity.firebaseId;
                        if (dbId && !ids.includes(dbId)) ids.push(dbId);
                        if (fbId && !ids.includes(fbId)) ids.push(fbId);
                    }
                    return ids;
                };

                const ids1 = await getIds(userId1);
                const ids2 = await getIds(userId2);

                const history = await Message.find({
                    $or: [
                        { senderId: { $in: ids1 }, receiverId: { $in: ids2 } },
                        { senderId: { $in: ids2 }, receiverId: { $in: ids1 } }
                    ]
                }).sort({ createdAt: 1 });

                socket.emit("chat_history", history);
            } catch (error) {
                console.error("Error fetching history:", error);
            }
        });

        // Driver Location Updates
        socket.on("update_location", (data) => {
            const { rideId, userId, latitude, longitude, heading } = data;
            // Emit to the ride-specific room so all participants (user/driver) get it
            io.to(rideId).emit("driver_location_update", {
                rideId,
                latitude,
                longitude,
                heading,
                timestamp: new Date()
            });
        });

        socket.on("disconnect", () => {
            console.log("User disconnected:", socket.id);
        });
    });

    return io;
};

module.exports = initSocket;
