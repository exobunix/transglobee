const blacklist = new Map();

const add = (token, ttlMs = 24 * 60 * 60 * 1000) => {
    if (!token) return;
    blacklist.set(token, Date.now() + ttlMs);
};

const has = (token) => {
    const expiresAt = blacklist.get(token);
    if (!expiresAt) return false;
    if (Date.now() > expiresAt) {
        blacklist.delete(token);
        return false;
    }
    return true;
};

module.exports = { add, has };
