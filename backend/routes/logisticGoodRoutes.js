const express = require('express');
const router = express.Router();
const multer = require('multer');
const LogisticGood = require('../models/LogisticGood');
const imagekit = require('../config/imagekit');

// Use memory storage — file buffer sent to ImageKit
const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) cb(null, true);
        else cb(new Error('Only image files are allowed'), false);
    }
});

// Helper: upload buffer to ImageKit
const uploadToImageKit = (buffer, fileName, folder) => {
    return new Promise((resolve, reject) => {
        imagekit.upload({
            file: buffer,
            fileName: fileName,
            folder: folder
        }, (error, result) => {
            if (error) reject(error);
            else resolve(result.url);
        });
    });
};

// POST /api/logistic-goods — Create a single logistic good
router.post('/', upload.single('image'), async (req, res) => {
    try {
        const { userId, itemName, type, length, height, width, imageUrl: bodyImageUrl } = req.body;

        if (!userId || !itemName || !type) {
            return res.status(400).json({ message: 'userId, itemName, and type are required.' });
        }

        let imageUrl = bodyImageUrl;

        if (req.file) {
            imageUrl = await uploadToImageKit(
                req.file.buffer,
                `item_${userId}_${Date.now()}`,
                'transglob/driverapp'
            );
        }

        const newGood = new LogisticGood({
            userId,
            itemName,
            type,
            length: parseFloat(length) || 0,
            height: parseFloat(height) || 0,
            width: parseFloat(width) || 0,
            image: imageUrl
        });

        const saved = await newGood.save();
        res.status(201).json(saved);
    } catch (err) {
        console.error('Error saving logistic good:', err);
        res.status(500).json({ message: err.message });
    }
});

// POST /api/logistic-goods/upload-image — Standalone image upload
router.post('/upload-image', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No image file provided' });
        }

        const userId = req.body.userId || 'guest';
        const url = await uploadToImageKit(
            req.file.buffer,
            `item_img_${userId}_${Date.now()}`,
            'transglob/driverapp'
        );

        res.json({ url });
    } catch (err) {
        console.error('Error uploading to ImageKit:', err);
        res.status(500).json({ message: err.message });
    }
});

// GET /api/logistic-goods/:userId — Get all items for a user
router.get('/:userId', async (req, res) => {
    try {
        const goods = await LogisticGood.find({ userId: req.params.userId })
            .sort({ createdAt: -1 });
        res.json(goods);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// GET /api/logistic-goods/detail/:id — Single item detail
router.get('/detail/:id', async (req, res) => {
    try {
        const good = await LogisticGood.findById(req.params.id);
        if (!good) return res.status(404).json({ message: 'Item not found' });
        res.json(good);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
