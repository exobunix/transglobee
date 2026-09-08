const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const mongoUri = process.env.MONGODB_URI;
console.log('Connecting to:', mongoUri);

mongoose.connect(mongoUri)
  .then(async () => {
    console.log('Connected to DB');
    
    const User = require('../models/User');
    const Vehicle = require('../models/Vehicle');
    const Route = require('../models/Route');
    
    const users = await User.find({});
    console.log('\n--- USERS ---');
    users.forEach(u => {
      console.log(`User: ${u.name || u.username}, ID: ${u._id}, Mobile: ${u.mobileNumber}, Role: ${u.role}, AssignedRoutes:`, u.assignedRoutes);
    });

    const routes = await Route.find({});
    console.log('\n--- ROUTES ---');
    routes.forEach(r => {
      console.log(`Route: ${r.name}, ID: ${r._id}, Source: ${r.source}, Destination: ${r.destination}`);
    });

    const vehicles = await Vehicle.find({});
    console.log('\n--- VEHICLES ---');
    vehicles.forEach(v => {
      console.log(`Vehicle: ${v.vehicleName}, ID: ${v._id}, Plate: ${v.numberPlate}, Type: ${v.vehicleType}, Status: ${v.status}, isEnabled: ${v.isEnabled}, Routes:`, v.routes);
    });

    mongoose.disconnect();
  })
  .catch(err => {
    console.error('Error:', err);
  });
