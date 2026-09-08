const admin = require('../config/firebase');
const jwt = require('jsonwebtoken');
const sessionBlacklist = require('../utils/sessionBlacklist');

console.log("!!! AUTH MIDDLEWARE LOADED !!!");

const isExplicitDevBypassEnabled = () =>
    process.env.NODE_ENV !== 'production' &&
    process.env.ALLOW_DEV_AUTH_BYPASS === 'true';

// ─── Attach role from DB (User or Driver) ────────────────
const attachRoleFromDB = async (id) => {
    try {
        const User = require('../models/User');
        const Driver = require('../models/Driver');

        // 1. Try to find User by Firebase UID
        let dbUser = await User.findOne({ uid: id });
        
        // 2. Fallback to MongoDB _id if id looks like an ObjectId (24 chars)
        if (!dbUser && id && id.length === 24) {
            dbUser = await User.findById(id);
        }
        
        if (dbUser) return { dbUser, role: dbUser.role || 'user', collection: 'user' };

        // 3. Try to find Driver by Firebase UID/firebaseId
        let dbDriver = await Driver.findOne({ $or: [{ uid: id }, { firebaseId: id }] });
        
        // 4. Fallback to MongoDB _id for Driver
        if (!dbDriver && id && id.length === 24) {
            dbDriver = await Driver.findById(id);
        }
        
        if (dbDriver) return { dbUser: dbDriver, role: 'driver', collection: 'driver' };
    } catch (e) {
        console.warn('[AUTH] DB role lookup failed:', e.message);
    }
    return { dbUser: null, role: 'user', collection: null };
};

// ─── Track device & session info ─────────────────────────
const trackDevice = async (uid, req, collection) => {
    try {
        const deviceInfo = {
            model: req.headers['x-device-model'] || 'Unknown',
            platform: req.headers['x-device-platform'] || req.headers['user-agent'] || 'Unknown',
            version: req.headers['x-app-version'] || '0',
        };
        const now = new Date();

        if (collection === 'user') {
            const User = require('../models/User');
            await User.updateOne({ uid }, { $set: { deviceInfo, lastActive: now, lastLoginAt: now } });
        } else if (collection === 'driver') {
            const Driver = require('../models/Driver');
            await Driver.updateOne(
                { $or: [{ uid }, { firebaseId: uid }] },
                { $set: { deviceInfo, lastLoginAt: now } }
            );
        }
    } catch (e) {
        // Non-critical — don't block request
        console.warn('[AUTH] Device tracking failed:', e.message);
    }
};

const verifyToken = async (req, res, next) => {
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) {
        token = token.split(' ')[1];
    }

    // Normalize obvious "empty" tokens coming from some clients
    if (token === 'null' || token === 'undefined' || token === '') {
        token = null;
    }

    // ─── Dev / Web Bypass (always allow known bypass tokens) ────────────────
    const normalizedToken = (token || '').toString().toLowerCase().trim();
    const devBypassTokens = [
        'dev-token-bypass',
        'dev-token',
        'demo-token-for-testing',
        'test-token'
    ];
    const isDevToken = devBypassTokens.includes(normalizedToken);

    const allowDevBypass = process.env.NODE_ENV !== 'production' || isExplicitDevBypassEnabled();

    if (allowDevBypass && isDevToken) {
        const devUid = req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid';
        const devEmail = req.headers['x-dev-email'] || `${devUid}@dev.local`;
        const devRole =
            req.headers['x-dev-role'] ||
            (req.originalUrl && req.originalUrl.includes('/driver') ? 'driver' : 'user');

        req.user = { uid: devUid, email: devEmail, role: devRole, isDevBypass: true };
        console.log(`[AUTH-DEV] Bypass accepted for UID ${devUid} on ${req.originalUrl}`);
        return next();
    }

    if (!token) {
        return res.status(401).json({ message: 'No token provided' });
    }

    if (sessionBlacklist.has(token)) {
        return res.status(401).json({ success: false, message: 'Session expired. Please log in again.' });
    }

    if (normalizedToken.includes('dev-token-bypass') && allowDevBypass) {
        console.log(`[AUTH-DEBUG] >>> Dev Bypass Triggered (legacy flag)`);
        const devUid = req.headers['x-dev-uid'] || req.headers['x-dev-id'];
        req.user = { uid: devUid || 'dev-user-uid', email: 'dev@example.com', role: 'driver' };
        return next();
    }

    try {
        let uid = null;
        let decoded = null;

        // 1. Try Firebase Token (project-bound)
        try {
            decoded = await admin.auth().verifyIdToken(token);
            uid = decoded.uid;
            req.user = decoded;
        } catch (firebaseErr) {
            console.log('[AUTH] Firebase verify failed, trying permissive decode and local JWT...');

            // 1a. Permissive decode for mismatched Firebase projects (e.g., web Google sign-in)
            try {
                const loose = jwt.decode(token);
                if (loose && (loose.user_id || loose.sub)) {
                    uid = loose.user_id || loose.sub;
                    req.user = {
                        uid,
                        email: loose.email,
                        name: loose.name,
                        isGoogleAuth: true,
                        firebaseProject: loose.aud || loose.iss
                    };
                    console.warn('[AUTH] Accepted unverified Firebase token (project mismatch) for uid:', uid);
                }
            } catch (e) {
                // ignore
            }
        }

        // 2. Try Local JWT
        if (!uid) {
            try {
                const localDecoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
                uid = localDecoded.uid || localDecoded.id;
                req.user = {
                    uid,
                    email: localDecoded.email,
                    role: localDecoded.role,
                    ...localDecoded,
                };
            } catch (jwtErr) {
                if (allowDevBypass) {
                    console.warn('[AUTH-DEV] Explicit development auth bypass enabled.');
                    req.user = {
                        uid: req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid',
                        email: 'dev@example.com',
                        role: 'driver',
                    };
                    return next();
                }
                return res.status(401).json({ message: 'Unauthorized', error: 'Invalid token' });
            }
        }

        // 3. Attach role from DB + track device (non-blocking)
        if (uid) {
            const { dbUser, role, collection } = await attachRoleFromDB(uid);
            if (dbUser) {
                req.user.role = role;
                req.user.dbUser = dbUser;
                // Ensure id field is consistently available for controllers
                req.user.id = dbUser._id.toString();
                if (!req.user.uid) req.user.uid = dbUser.uid || dbUser._id.toString();
            }
            // Fire and forget — don't await
            trackDevice(uid, req, collection).catch(() => {});
        }

        return next();
    } catch (error) {
        console.error('Core auth error:', error);
        res.status(500).json({ message: 'Auth logic error' });
    }
};

const optionalVerifyToken = async (req, res, next) => {
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) {
        token = token.split(' ')[1];
    }

    if (token === 'null' || token === 'undefined' || token === '') {
        token = null;
    }

    if (!token) {
        req.user = null;
        return next();
    }

    const normalizedToken = token.toString().toLowerCase().trim();
    const devBypassTokens = [
        'dev-token-bypass',
        'dev-token',
        'demo-token-for-testing',
        'test-token'
    ];
    const isDevToken = devBypassTokens.includes(normalizedToken);
    const allowDevBypass = process.env.NODE_ENV !== 'production' || isExplicitDevBypassEnabled();

    if (allowDevBypass && isDevToken) {
        const devUid = req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid';
        const devEmail = req.headers['x-dev-email'] || `${devUid}@dev.local`;
        const devRole =
            req.headers['x-dev-role'] ||
            (req.originalUrl && req.originalUrl.includes('/driver') ? 'driver' : 'user');

        req.user = { uid: devUid, email: devEmail, role: devRole, isDevBypass: true };
        return next();
    }

    if (sessionBlacklist.has(token)) {
        return res.status(401).json({ success: false, message: 'Session expired. Please log in again.' });
    }

    try {
        let uid = null;
        let decoded = null;

        try {
            decoded = await admin.auth().verifyIdToken(token);
            uid = decoded.uid;
            req.user = decoded;
        } catch (firebaseErr) {
            try {
                const loose = jwt.decode(token);
                if (loose && (loose.user_id || loose.sub)) {
                    uid = loose.user_id || loose.sub;
                    req.user = {
                        uid,
                        email: loose.email,
                        name: loose.name,
                        isGoogleAuth: true,
                        firebaseProject: loose.aud || loose.iss
                    };
                }
            } catch (e) {}
        }

        if (!uid) {
            try {
                const localDecoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
                uid = localDecoded.uid || localDecoded.id;
                req.user = {
                    uid,
                    email: localDecoded.email,
                    role: localDecoded.role,
                    ...localDecoded,
                };
            } catch (jwtErr) {
                // If token is invalid/expired but it's optional, treat as guest
                req.user = null;
                return next();
            }
        }

        if (uid) {
            const { dbUser, role, collection } = await attachRoleFromDB(uid);
            if (dbUser) {
                req.user.role = role;
                req.user.dbUser = dbUser;
                req.user.id = dbUser._id.toString();
                if (!req.user.uid) req.user.uid = dbUser.uid || dbUser._id.toString();
            }
            trackDevice(uid, req, collection).catch(() => {});
        }

        return next();
    } catch (error) {
        req.user = null;
        return next();
    }
};

module.exports = { verifyToken, optionalVerifyToken };

