require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const User = require('./models/User');

const fixUserIndexes = async () => {
    try {
        await connectDB();

        console.log('Syncing User indexes...');

        // Try to drop the problematic email index
        try {
            await User.collection.dropIndex('email_1');
            console.log('Dropped email_1 index.');
        } catch (e) {
            console.log('Index email_1 not found or already dropped.');
        }

        // Re-create indexes based on current Mongoose schema (which now has sparse: true and NO default)
        await User.createIndexes();
        console.log('Recreated User indexes successfully!');

        process.exit(0);
    } catch (error) {
        console.error('Error fixing User indexes:', error);
        process.exit(1);
    }
};

fixUserIndexes();
