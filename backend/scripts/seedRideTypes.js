const mongoose = require('mongoose');
require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const RideType = require('./models/RideType');

const seedRideTypes = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // Clear current docs
        await RideType.deleteMany({});

        const rides = [
            {
                name: 'Auto',
                description: 'Get an auto at your doorstep',
                icon: 'auto',
                baseFare: 30,
                pricePerKm: 12,
                waitingTime: 'Now'
            },
            {
                name: 'Mini',
                description: 'Comfy hatchbacks at pocket-friendly fares',
                icon: 'mini',
                baseFare: 50,
                pricePerKm: 15,
                waitingTime: '7 min'
            },
            {
                name: 'Bike',
                description: 'Zip through traffic at affordable fares',
                icon: 'bike',
                baseFare: 20,
                pricePerKm: 8,
                waitingTime: '2 min'
            },
            {
                name: 'Prime Sedan',
                description: 'Sedans with free wifi and top drivers',
                icon: 'sedan',
                baseFare: 70,
                pricePerKm: 18,
                waitingTime: '3 min'
            },
            {
                name: 'Prime SUV',
                description: 'SUVs with free wifi and top drivers',
                icon: 'suv',
                baseFare: 100,
                pricePerKm: 25,
                waitingTime: '3 min'
            }
        ];

        await RideType.insertMany(rides);
        console.log('RideTypes Seeded successfully');
        process.exit();
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

seedRideTypes();
