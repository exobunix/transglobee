const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const Route = require('../models/Route');

const vicroraDestinations = [
    "Vicrora - 1 (46/25), Faridabad",
    "Vicrora - 2 (118), Faridabad",
    "Vicrora - 4 (1136), Faridabad",
    "Vicrora - 5 (290), Faridabad",
    "Vicrora - 6 (1049), Faridabad",
    "Vicrora - 8 (1146), Faridabad"
];

// Helper to generate 6 vicrora routes for a given model and source
function genRoutes(model, source, destinations = vicroraDestinations) {
    return destinations.map(dest => ({
        model,
        source,
        destination: dest
    }));
}

const truckRoutesData = [
    // --- Pickup (66 routes: 11 sources x 6 destinations) ---
    ...genRoutes("Pickup", "Delhi Airport"),
    ...genRoutes("Pickup", "Delhi, Railway Station"),
    ...genRoutes("Pickup", "Maruti, Gurgaon"),
    ...genRoutes("Pickup", "Maruti, Manesar"),
    ...genRoutes("Pickup", "Maruti, Kharkhonda"),
    ...genRoutes("Pickup", "Faridabad, Local"),
    ...genRoutes("Pickup", "Noida"),
    ...genRoutes("Pickup", "Tapukara"),
    ...genRoutes("Pickup", "Sohna"),
    ...genRoutes("Pickup", "Bawal"),
    ...genRoutes("Pickup", "Neemrana"),

    // --- 14 ft Canter (36 routes: 6 sources x 6 destinations) ---
    ...genRoutes("14 ft Canter", "Maruti, Gurgaon"),
    ...genRoutes("14 ft Canter", "Maruti, Manesar"),
    ...genRoutes("14 ft Canter", "Maruti, Kharkhonda"),
    ...genRoutes("14 ft Canter", "Tapukara"),
    ...genRoutes("14 ft Canter", "Bawal"),
    ...genRoutes("14 ft Canter", "Neemrana"),

    // --- 22 ft Canter (36 routes: 6 sources x 6 destinations) ---
    ...genRoutes("22 ft Canter", "Maruti, Gurgaon"),
    ...genRoutes("22 ft Canter", "Maruti, Manesar"),
    ...genRoutes("22 ft Canter", "Maruti, Kharkhonda"),
    ...genRoutes("22 ft Canter", "Tapukara"),
    ...genRoutes("22 ft Canter", "Bawal"),
    ...genRoutes("22 ft Canter", "Neemrana")
];

async function seedTruckRoutes() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected successfully!');

        let createdCount = 0;
        let updatedCount = 0;

        for (const item of truckRoutesData) {
            const routeName = `${item.source} to ${item.destination} (${item.model})`;
            
            const existing = await Route.findOne({
                source: item.source,
                destination: item.destination,
                $or: [
                    { vehicleModel: item.model },
                    { vehicleType: item.model }
                ]
            });

            if (existing) {
                existing.name = routeName;
                existing.vehicleType = 'truck';
                existing.vehicleModel = item.model;
                existing.startLocation = item.source;
                existing.endLocation = item.destination;
                existing.isActive = true;
                await existing.save();
                updatedCount++;
            } else {
                await Route.create({
                    name: routeName,
                    source: item.source,
                    destination: item.destination,
                    startLocation: item.source,
                    endLocation: item.destination,
                    vehicleType: 'truck',
                    vehicleModel: item.model,
                    isActive: true
                });
                createdCount++;
            }
        }

        console.log(`\nTruck Seeding completed!`);
        console.log(`- Created: ${createdCount} routes`);
        console.log(`- Updated: ${updatedCount} routes`);
        console.log(`- TotalProcessed: ${truckRoutesData.length} routes`);

        const totalTruckRoutes = await Route.countDocuments({ vehicleType: 'truck' });
        console.log(`- Total 'truck' Routes in Database: ${totalTruckRoutes}`);
        
        const totalAllRoutes = await Route.countDocuments({});
        console.log(`- Total All Routes in Database: ${totalAllRoutes}`);

    } catch (err) {
        console.error('Error seeding truck routes:', err);
    } finally {
        await mongoose.disconnect();
        process.exit();
    }
}

seedTruckRoutes();
