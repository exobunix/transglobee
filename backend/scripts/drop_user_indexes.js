// Run this script once to drop old indexes from the users collection
// Usage: node drop_user_indexes.js

require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const mongoose = require('mongoose');
const connectDB = require('./config/db');

async function dropOldIndexes() {
    try {
        await connectDB();

        const db = mongoose.connection.db;
        const collection = db.collection('users');

        // List current indexes
        const indexes = await collection.indexes();
        console.log('Current indexes:', JSON.stringify(indexes, null, 2));

        // Drop all indexes except _id
        await collection.dropIndexes();
        console.log('\n✅ All non-_id indexes dropped successfully!');

        // Recreate indexes based on the User schema (mobileNumber unique, email sparse, etc.)
        const User = require('./models/User');
        await User.createIndexes();
        console.log('✅ Recreated indexes using User schema');

        // List indexes again
        const newIndexes = await collection.indexes();
        console.log('\nNew indexes:', JSON.stringify(newIndexes, null, 2));

        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

dropOldIndexes();
