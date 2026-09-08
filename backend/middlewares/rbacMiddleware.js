/**
 * RBAC (Role-Based Access Control) Middleware
 * Supports roles: user, driver, corporate, admin, moderator, supervisor, superadmin
 *
 * Usage:
 *   router.get('/route', requireRole('admin', 'supervisor'), handler);
 *   router.get('/route', requireRole('driver'), handler);
 */

const requireRole = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, message: 'Unauthorized: no authenticated user.' });
        }

        const userRole = (req.user.role || '').toLowerCase();

        // superadmin bypasses all role checks
        if (userRole === 'superadmin') return next();

        if (!allowedRoles.map(r => r.toLowerCase()).includes(userRole)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Required role(s): ${allowedRoles.join(', ')}. Your role: ${userRole || 'none'}.`,
            });
        }

        next();
    };
};

/**
 * Supervisor or Admin gate — allows both admin and supervisor
 */
const requireSupervisorOrAdmin = requireRole('admin', 'supervisor', 'superadmin', 'moderator');

/**
 * Admin-only gate
 */
const requireAdmin = requireRole('admin', 'superadmin');

/**
 * Corporate-only gate
 */
const requireCorporate = requireRole('corporate');

/**
 * Driver-only gate
 */
const requireDriver = requireRole('driver');

/**
 * Any authenticated user (user, corporate, driver)
 */
const requireUser = requireRole('user', 'corporate', 'driver', 'admin', 'supervisor', 'superadmin', 'moderator');

module.exports = {
    requireRole,
    requireAdmin,
    requireSupervisorOrAdmin,
    requireCorporate,
    requireDriver,
    requireUser,
};
