const Notification = require('../models/Notification');
const User = require('../models/User');
const Driver = require('../models/Driver');

const getUserId = (req) => req.user?.uid || req.user?.id || req.query.userId || req.body.userId;

exports.listNotifications = async (req, res) => {
    try {
        const page = Math.max(Number(req.query.page || 1), 1);
        const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 100);
        const filter = { userId: getUserId(req) };
        const [notifications, total] = await Promise.all([
            Notification.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
            Notification.countDocuments(filter),
        ]);
        return res.json({ success: true, notifications, total, page, limit });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.markRead = async (req, res) => {
    try {
        const ids = req.body.ids || req.body.notificationIds || [];
        const filter = ids.length ? { _id: { $in: ids }, userId: getUserId(req) } : { userId: getUserId(req), isRead: false };
        await Notification.updateMany(filter, { isRead: true, readAt: new Date() });
        return res.json({ success: true, message: 'Notifications marked as read.' });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

exports.broadcast = async (req, res) => {
    try {
        const { title, body, type = 'broadcast', target = 'users', data = {} } = req.body;
        if (!title) return res.status(400).json({ success: false, message: 'title is required.' });

        let recipients = [];
        if (target === 'drivers') {
            recipients = await Driver.find().select('_id uid role');
        } else if (target === 'all') {
            const [users, drivers] = await Promise.all([
                User.find().select('_id uid role'),
                Driver.find().select('_id uid role'),
            ]);
            recipients = [...users, ...drivers];
        } else {
            recipients = await User.find().select('_id uid role');
        }

        const docs = recipients.map((recipient) => ({
            userId: recipient.uid || recipient._id.toString(),
            role: recipient.role || (target === 'drivers' ? 'driver' : 'user'),
            title,
            body,
            type,
            data,
        }));

        if (docs.length) await Notification.insertMany(docs, { ordered: false });
        if (req.io) req.io.emit('notification:broadcast', { title, body, type, data });

        return res.status(201).json({ success: true, message: 'Broadcast queued.', sentCount: docs.length });
    } catch (err) {
        return res.status(500).json({ success: false, message: err.message });
    }
};

/************************************************ new api added*******************************/ 


// ─── GET /api/notifications/all ──────────────────────────────────────────────
// Supervisor/Admin sees ALL notifications they broadcasted
// ─────────────────────────────────────────────────────────────────────────────
exports.listAllNotifications = async (req, res) => {
    try {
        const page  = Math.max(Number(req.query.page  || 1),  1);
        const limit = Math.min(Math.max(Number(req.query.limit || 20), 1), 100);

        // Optional filters
        const filter = {};
        if (req.query.type)   filter.type   = req.query.type;
        if (req.query.role)   filter.role   = req.query.role;
        if (req.query.isRead) filter.isRead = req.query.isRead === 'true';

        const [notifications, total] = await Promise.all([
            Notification.find(filter)
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            Notification.countDocuments(filter)
        ]);

        return res.status(200).json({
            success: true,
            notifications,
            total,
            page,
            limit
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ─── GET /api/notifications/unread-count ─────────────────────────────────────
// Returns count of unread notifications — used for badge on bell icon
// ─────────────────────────────────────────────────────────────────────────────
exports.unreadCount = async (req, res) => {
    try {
        const count = await Notification.countDocuments({
            userId: getUserId(req),
            isRead: false
        });

        return res.status(200).json({
            success: true,
            unreadCount: count
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ─── DELETE /api/notifications/:id ───────────────────────────────────────────
// Delete a single notification by ID
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteNotification = async (req, res) => {
    try {
        const userId = getUserId(req);
        const userRole = req.user?.role;

        // Supervisor/Admin can delete any notification
        // Regular user/driver can only delete their own
        const filter = ['admin', 'supervisor', 'superadmin', 'moderator'].includes(userRole)
            ? { _id: req.params.id }
            : { _id: req.params.id, userId };

        const notification = await Notification.findOneAndDelete(filter);

        if (!notification) {
            return res.status(404).json({
                success: false,
                message: 'Notification not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Notification deleted successfully.'
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ─── DELETE /api/notifications ───────────────────────────────────────────────
// Clear ALL notifications for the logged in user
// ─────────────────────────────────────────────────────────────────────────────
exports.clearAll = async (req, res) => {
    try {
        const result = await Notification.deleteMany({
            userId: getUserId(req)
        });

        return res.status(200).json({
            success: true,
            message: 'All notifications cleared.',
            deletedCount: result.deletedCount
        });

    } catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
};


