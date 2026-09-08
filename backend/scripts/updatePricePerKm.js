const mongoose = require('mongoose');
const LogisticsVehicle = require('./models/LogisticsVehicle');
require('dotenv').config();

async function updateVehicles() {
    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/ola_uber');
        console.log('Connected to DB');
        
        await LogisticsVehicle.updateMany(
            { pricePerKm: { $exists: false } },
            { $set: { pricePerKm: 10 } }
        );
        
        console.log('Updated vehicles with default pricePerKm');
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

updateVehicles();
