const express = require('express');
const router = express.Router();
const LogisticsVehicle = require('../models/LogisticsVehicle');

// Get all logistics vehicles (for admin)
router.get('/all', async (req, res) => {
    try {
        const vehicles = await LogisticsVehicle.find();
        res.json(vehicles);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get active logistics vehicles (for user app)
router.get('/', async (req, res) => {
    try {
        const vehicles = await LogisticsVehicle.find({ isActive: true });
        res.json(vehicles);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create new logistics vehicle
router.post('/', async (req, res) => {
    const vehicle = new LogisticsVehicle(req.body);
    try {
        const newVehicle = await vehicle.save();
        res.status(201).json(newVehicle);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update logistics vehicle
router.put('/:id', async (req, res) => {
    try {
        const vehicle = await LogisticsVehicle.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json(vehicle);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Delete logistics vehicle
router.delete('/:id', async (req, res) => {
    try {
        await LogisticsVehicle.findByIdAndDelete(req.params.id);
        res.json({ message: 'Vehicle deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Seed initial data
router.post('/seed', async (req, res) => {
    try {
        const initialVehicles = [
            {
                name: 'Train',
                capacity: '50 tons',
                basePrice: 5000,
                pricePerKm: 2,
                pricePerPiece: 150,
                imageUrl: 'https://cdn-icons-png.flaticon.com/512/3112/3112932.png',
                isActive: true
            },
            {
                name: 'Flight',
                capacity: '10 tons',
                basePrice: 15000,
                pricePerKm: 50,
                pricePerPiece: 500,
                imageUrl: 'https://cdn-icons-png.flaticon.com/512/3125/3125713.png',
                isActive: true
            },
            {
                name: 'Sea cargo',
                capacity: '500 tons',
                basePrice: 25000,
                pricePerKm: 5,
                pricePerPiece: 300,
                imageUrl: 'https://cdn-icons-png.flaticon.com/512/3125/3125816.png',
                isActive: true
            }
        ];

        for (const v of initialVehicles) {
            await LogisticsVehicle.findOneAndUpdate({ name: v.name }, v, { upsert: true, new: true });
        }
        res.json({ message: 'Logistics vehicles seeded/updated successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
