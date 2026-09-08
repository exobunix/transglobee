/**
 * Centralized Request Logger Middleware
 * Logs every request with method, path, status, duration, and user info.
 * Also catches and logs unhandled errors centrally.
 */

const requestLogger = (req, res, next) => {
    const start = Date.now();
    const timestamp = new Date().toISOString();

    res.on('finish', () => {
        const duration = Date.now() - start;
        const userId = req.user?.uid || req.user?.id || '-';
        const role = req.user?.role || '-';
        const status = res.statusCode;
        const statusLabel = status >= 500 ? 'ERROR' : status >= 400 ? 'WARN' : 'INFO';

        const logLine = `[${timestamp}] [${statusLabel}] ${req.method} ${req.originalUrl} | ${status} | ${duration}ms | user:${userId} role:${role} | ip:${req.ip}`;

        if (status >= 500) console.error(logLine);
        else if (status >= 400) console.warn(logLine);
        else console.log(logLine);
    });

    next();
};

/**
 * Centralized error handler (place last in app.use chain)
 */
const centralErrorHandler = (err, req, res, next) => {
    const timestamp = new Date().toISOString();
    const userId = req.user?.uid || '-';

    console.error(`[${timestamp}] [CRASH] ${req.method} ${req.originalUrl} | user:${userId} | ${err.stack || err.message}`);

    const status = err.status || err.statusCode || 500;
    res.status(status).json({
        success: false,
        message: process.env.NODE_ENV === 'production' ? 'Internal server error.' : err.message,
        ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
    });
};

module.exports = { requestLogger, centralErrorHandler };
