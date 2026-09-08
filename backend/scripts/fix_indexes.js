require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const Driver = require('./models/Driver');

const fixIndexes = async () => {
    try {
        await connectDB();

        console.log('Syncing indexes...');
        // Drop all indexes except _id
        await Driver.collection.dropIndexes();
        console.log('Dropped all existing indexes.');

        // Re-create indexes based on current Mongoose schema
        await Driver.createIndexes();
        console.log('Recreated indexes successfully!');

        process.exit(0);
    } catch (error) {
        console.error('Error fixing indexes:', error);
        process.exit(1);
    }
};

fixIndexes();
