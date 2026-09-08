const express = require('express');
const router = express.Router();
const TypeGood = require('../models/TypeGood');

// Get all active types of goods
router.get('/', async (req, res) => {
    try {
        const goods = await TypeGood.find({ isActive: true });
        res.json(goods);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Seed some initial data if empty
router.post('/seed', async (req, res) => {
    try {
        const count = await TypeGood.countDocuments();
        if (count === 0) {
            const initialGoods = [
                { name: 'Furniture' },
                { name: 'Electronics' },
                { name: 'Groceries' },
                { name: 'Crockery' },
                { name: 'Textiles' },
                { name: 'Hardware' },
                { name: 'Machinery' },
                { name: 'Others' }
            ];
            await TypeGood.insertMany(initialGoods);
            return res.json({ message: 'Seeded successfully' });
        }
        res.json({ message: 'Already seeded' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
