const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../.env') });

const Route = require('../models/Route');

const carRoutesData = [
    // --- Dzire (37) ---
    { model: "Dzire", source: "Delhi Airport", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Gurgaon Railway Station", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Gurgaon Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Greater Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Manesar Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Kharkhonda Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Local 4 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Local 8 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Local 12 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Dzire", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" },
    { model: "Dzire", source: "Pune Airport", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Guest House, Pune", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Khed, Hotel", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Mahindra, Pune", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Local 6 Hours", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Mahindra, Nashik", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Victora - 10, Pune", destination: "Victora - 11, Pune" },
    { model: "Dzire", source: "Maruti, Mahsana", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Guest House, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Hotel, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Ahemdabad, Airport", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Mehsana, Railway Station", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Victora - 12, Sanand", destination: "Victora - 7, Bechraji" },
    { model: "Dzire", source: "Victora - 7, Bechraji", destination: "Victora - 12, Sanand" },
    { model: "Dzire", source: "Tata, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Dzire", source: "Guest House, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Dzire", source: "Sanand, Railway Station", destination: "Victora - 12, Sanand" },
    { model: "Dzire", source: "Local, Sanand", destination: "Victora - 12, Sanand" },

    // --- Triber (29) ---
    { model: "Triber", source: "Delhi Airport", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Gurgaon Railway Station", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Gurgaon Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Greater Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Manesar Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Kharkhonda Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Local 4 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Local 8 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Local 12 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Triber", source: "Pune Airport", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Guest House, Pune", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Khed, Hotel", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Mahindra, Pune", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Local 6 Hours", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Mahindra, Nashik", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Victora - 10, Pune", destination: "Victora - 11, Pune" },
    { model: "Triber", source: "Maruti, Mahsana", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Guest House, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Hotel, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Ahemdabad, Airport", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Mehsana, Railway Station", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Victora - 12, Sanand", destination: "Victora - 7, Bechraji" },
    { model: "Triber", source: "Victora - 7, Bechraji", destination: "Victora - 12, Sanand" },
    { model: "Triber", source: "Tata, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Triber", source: "Guest House, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Triber", source: "Sanand, Railway Station", destination: "Victora - 12, Sanand" },
    { model: "Triber", source: "Ahemdabad, Airport", destination: "Victora - 12, Sanand" },
    { model: "Triber", source: "Local, Sanand", destination: "Victora - 12, Sanand" },

    // --- Ertiga (38) ---
    { model: "Ertiga", source: "Delhi Airport", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Gurgaon Railway Station", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Gurgaon Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Greater Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Manesar Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Kharkhonda Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Local 4 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Local 8 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Local 12 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Ertiga", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" },
    { model: "Ertiga", source: "Pune Airport", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Guest House, Pune", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Khed, Hotel", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Mahindra, Pune", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Local 6 Hours", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Mahindra, Nashik", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Victora - 10, Pune", destination: "Victora - 11, Pune" },
    { model: "Ertiga", source: "Maruti, Mahsana", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Guest House, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Hotel, Mehsana", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Ahemdabad, Airport", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Mehsana, Railway Station", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Victora - 12, Sanand", destination: "Victora - 7, Bechraji" },
    { model: "Ertiga", source: "Victora - 7, Bechraji", destination: "Victora - 12, Sanand" },
    { model: "Ertiga", source: "Tata, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Ertiga", source: "Guest House, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Ertiga", source: "Sanand, Railway Station", destination: "Victora - 12, Sanand" },
    { model: "Ertiga", source: "Ahemdabad, Airport", destination: "Victora - 12, Sanand" },
    { model: "Ertiga", source: "Local, Sanand", destination: "Victora - 12, Sanand" },

    // --- Kia Carens (11) ---
    { model: "Kia Carens", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" },
    { model: "Kia Carens", source: "Delhi Airport", destination: "Vicrora - 8, Faridabad" },
    { model: "Kia Carens", source: "Gurgaon Maruti", destination: "Vicrora - 8, Faridabad" },

    // --- Innova (28) ---
    { model: "Innova", source: "Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Radisson, Greater Noida", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Manesar Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Kharkhonda Maruti", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Local 4 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Local 8 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Local 12 Hours", destination: "Vicrora - 8, Faridabad" },
    { model: "Innova", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" },
    { model: "Innova", source: "Pune Airport", destination: "Victora - 11, Pune" },
    { model: "Innova", source: "Mahindra, Pune", destination: "Victora - 11, Pune" },
    { model: "Innova", source: "Local 6 Hours", destination: "Victora - 11, Pune" },
    { model: "Innova", source: "Mahindra, Nashik", destination: "Victora - 11, Pune" },
    { model: "Innova", source: "Victora - 10, Pune", destination: "Victora - 11, Pune" },
    { model: "Innova", source: "Maruti, Mahsana", destination: "Victora - 7, Bechraji" },
    { model: "Innova", source: "Ahemdabad, Airport", destination: "Victora - 7, Bechraji" },
    { model: "Innova", source: "Victora - 12, Sanand", destination: "Victora - 7, Bechraji" },
    { model: "Innova", source: "Victora - 7, Bechraji", destination: "Victora - 12, Sanand" },
    { model: "Innova", source: "Tata, Sanand", destination: "Victora - 12, Sanand" },
    { model: "Innova", source: "Ahemdabad, Airport", destination: "Victora - 12, Sanand" },
    { model: "Innova", source: "Local, Sanand", destination: "Victora - 12, Sanand" },

    // --- Innova Hycross (9) ---
    { model: "Innova Hycross", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Innova Hycross", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" },

    // --- Kia Carnival (9) ---
    { model: "Kia Carnival", source: "Delhi Airport", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Gurgaon Railway Station", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Noida Airport", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Local 4 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Local 8 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Local 12 Hours", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Delhi Local", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Jaipur", destination: "Radisson, Greater Noida" },
    { model: "Kia Carnival", source: "Juna Mahal, Ranthambore", destination: "Radisson, Greater Noida" }
];

async function seedRoutes() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected successfully!');

        let createdCount = 0;
        let updatedCount = 0;

        for (const item of carRoutesData) {
            const routeName = `${item.source} to ${item.destination} (${item.model})`;
            
            // Match by source, destination AND vehicleModel (or old vehicleType == item.model)
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
                existing.vehicleType = 'car';
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
                    vehicleType: 'car',
                    vehicleModel: item.model,
                    isActive: true
                });
                createdCount++;
            }
        }

        console.log(`\nSeeding completed!`);
        console.log(`- Created: ${createdCount} routes`);
        console.log(`- Updated: ${updatedCount} routes`);
        console.log(`- TotalProcessed: ${carRoutesData.length} routes`);

        const totalCarRoutes = await Route.countDocuments({ vehicleType: 'car' });
        console.log(`- Total 'car' Routes in Database: ${totalCarRoutes}`);

    } catch (err) {
        console.error('Error seeding routes:', err);
    } finally {
        await mongoose.disconnect();
        process.exit();
    }
}

seedRoutes();
