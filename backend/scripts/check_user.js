const mongoose = require('mongoose');
const Vehicle = require('../models/Vehicle');

const run = async () => {
    try {
        const uri = 'mongodb+srv://projectpatelpulse_db_user:transglobepassword@transglobledb.l61dbqe.mongodb.net/transglobledb';
        await mongoose.connect(uri);
        console.log('Connected to MongoDB');
        
        const vehicle = await Vehicle.findOne({ vehicleName: 'Tata Ultra Truck' });
        if (vehicle) {
            console.log('Tata Ultra Truck found:', JSON.stringify(vehicle, null, 2));
        } else {
            console.log('Tata Ultra Truck not found in Vehicle collection.');
            // Search case insensitively or with regex
            const vehicles = await Vehicle.find({ vehicleName: /tata/i });
            console.log('Tata vehicles:', JSON.stringify(vehicles, null, 2));
        }
    } catch (e) {
        console.error(e);
    } finally {
        await mongoose.disconnect();
    }
};

run();
