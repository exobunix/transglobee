const mongoose = require('mongoose');
const dns = require('dns');
try {
    dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
} catch (e) {
    console.warn('DNS server override failed:', e.message);
}

let cachedConnection = null;
let connectionPromise = null;

const connectDB = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            console.error('CRITICAL ERROR: MONGODB_URI environment variable is missing!');
            throw new Error('MONGODB_URI environment variable is missing');
        }

        if (cachedConnection && mongoose.connection.readyState === 1) {
            return cachedConnection;
        }

        if (!connectionPromise) {
            mongoose.set('bufferCommands', false);
            connectionPromise = mongoose.connect(process.env.MONGODB_URI, {
                serverSelectionTimeoutMS: 15000,
                socketTimeoutMS: 15000,
            });
        }

        const conn = await connectionPromise;
        cachedConnection = conn;
        console.log(`MongoDB Connected: ${conn.connection.host}`);
        return conn;
    } catch (error) {
        connectionPromise = null;
        console.error(`Database Connection Error: ${error.message}`);
        throw error;
    }
};

module.exports = connectDB;
