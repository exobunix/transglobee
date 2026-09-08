const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middlewares/authMiddleware');
const { requireSupervisorOrAdmin } = require('../middlewares/rbacMiddleware');
const ctrl = require('../controllers/notificationController');

// ─── User/Driver Routes ───────────────────────────────────────────────────────
router.get('/',             verifyToken, ctrl.listNotifications);
router.post('/read',        verifyToken, ctrl.markRead);
router.get('/unread-count', verifyToken, ctrl.unreadCount);
router.delete('/:id',       verifyToken, ctrl.deleteNotification);
router.delete('/',          verifyToken, ctrl.clearAll);

// ─── Supervisor/Admin Only Routes ────────────────────────────────────────────
router.get(
    '/all',
    verifyToken,
    requireSupervisorOrAdmin,
    ctrl.listAllNotifications        // ✅ See all notifications
);
router.post(
    '/broadcast',
    verifyToken,
    requireSupervisorOrAdmin,
    ctrl.broadcast                   // ✅ Send to all
);

module.exports = router;