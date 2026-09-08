const Vehicle = require('../models/Vehicle');
const Route   = require('../models/Route');

// ─── POST /api/admin/vehicles/add ────────────────────────────────────────────
// Admin adds a new vehicle (car/bus/truck)
// ─────────────────────────────────────────────────────────────────────────────
exports.addVehicle = async (req, res) => {
    try {
        const {
            vehicleType,
            vehicleName,
            brand,
            model,
            year,
            numberPlate,
            passengerCapacity,
            luggageCapacity,
            truckLoadCapacity,
            driverId,
            pricing,
            status,
            vehicleImage
        } = req.body;

        // Validate required fields
        if (!vehicleType || !vehicleName || !numberPlate) {
            return res.status(400).json({
                success: false,
                message: 'vehicleType, vehicleName and numberPlate are required.'
            });
        }

        if (!['car', 'bus', 'truck'].includes(vehicleType)) {
            return res.status(400).json({
                success: false,
                message: 'vehicleType must be car, bus or truck.'
            });
        }

        // Check duplicate number plate
        const existing = await Vehicle.findOne({ numberPlate });
        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Vehicle with this number plate already exists.'
            });
        }

        const vehicle = new Vehicle({
            vehicleType,
            vehicleName,
            brand:             brand             || '',
            model:             model             || '',
            year:              year              || '',
            numberPlate,
            passengerCapacity: passengerCapacity || 0,
            luggageCapacity:   luggageCapacity   || 0,
            truckLoadCapacity: truckLoadCapacity || 0,
            driverId:          driverId          || null,
            pricing:           pricing           || {},
            status:            status            || 'active',
            isEnabled:         true,
            vehicleImage:      vehicleImage      || '',
            photos:            vehicleImage      ? [vehicleImage] : []
        });

        await vehicle.save();

        return res.status(201).json({
            success: true,
            message: 'Vehicle added successfully.',
            data: vehicle
        });

    } catch (error) {
        console.error('[addVehicle] Error:', error.message);
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                message: 'Number plate already exists.'
            });
        }
        return res.status(500).json({
            success: false,
            message: 'Server error.',
            error: error.message
        });
    }
};

// ─── GET /api/admin/vehicles ──────────────────────────────────────────────────
// Get all vehicles with optional filter by type
// ─────────────────────────────────────────────────────────────────────────────
exports.getAllVehicles = async (req, res) => {
    try {
        const filter = {};

        // Filter by type: ?type=car or ?type=bus or ?type=truck
        if (req.query.type) filter.vehicleType = req.query.type;
        if (req.query.status) filter.status     = req.query.status;
        if (req.query.isEnabled !== undefined) {
            filter.isEnabled = req.query.isEnabled === 'true';
        }

        const vehicles = await Vehicle.find(filter)
            .populate('driverId', 'name mobileNumber email')
            .populate('routes', 'name source destination')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            total: vehicles.length,
            data: vehicles
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── GET /api/admin/vehicles/:id ─────────────────────────────────────────────
// Get single vehicle details
// ─────────────────────────────────────────────────────────────────────────────
exports.getVehicleById = async (req, res) => {
    try {
        const vehicle = await Vehicle.findById(req.params.id)
            .populate('driverId', 'name mobileNumber email')
            .populate('routes', 'name source destination stops distance');

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        return res.status(200).json({
            success: true,
            data: vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── PUT /api/admin/vehicles/:id ─────────────────────────────────────────────
// Edit vehicle details
// ─────────────────────────────────────────────────────────────────────────────
exports.updateVehicle = async (req, res) => {
    try {
        if (req.body.vehicleImage !== undefined) {
            req.body.photos = req.body.vehicleImage ? [req.body.vehicleImage] : [];
        }
        const vehicle = await Vehicle.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true, runValidators: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Vehicle updated successfully.',
            data: vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── DELETE /api/admin/vehicles/:id ──────────────────────────────────────────
// Delete a vehicle
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteVehicle = async (req, res) => {
    try {
        const vehicle = await Vehicle.findByIdAndDelete(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Vehicle deleted successfully.'
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── PUT /api/admin/vehicles/:id/toggle ──────────────────────────────────────
// Enable or Disable a vehicle
// ─────────────────────────────────────────────────────────────────────────────
exports.toggleVehicle = async (req, res) => {
    try {
        const vehicle = await Vehicle.findById(req.params.id);

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        vehicle.isEnabled = !vehicle.isEnabled;
        await vehicle.save();

        return res.status(200).json({
            success: true,
            message: `Vehicle ${vehicle.isEnabled ? 'enabled' : 'disabled'} successfully.`,
            isEnabled: vehicle.isEnabled
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── PUT /api/admin/vehicles/:id/status ──────────────────────────────────────
// Update vehicle status: active / inactive / maintenance
// ─────────────────────────────────────────────────────────────────────────────
exports.updateVehicleStatus = async (req, res) => {
    try {
        const { status } = req.body;

        if (!['active', 'inactive', 'maintenance'].includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Status must be active, inactive or maintenance.'
            });
        }

        const vehicle = await Vehicle.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: `Vehicle status updated to ${status}.`,
            data: vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── POST /api/admin/vehicles/:id/assign-route ───────────────────────────────
// Assign a route to a vehicle
// ─────────────────────────────────────────────────────────────────────────────
exports.assignRoute = async (req, res) => {
    try {
        const { routeId } = req.body;

        if (!routeId) {
            return res.status(400).json({
                success: false,
                message: 'routeId is required.'
            });
        }

        // Check route exists
        const route = await Route.findById(routeId);
        if (!route) {
            return res.status(404).json({
                success: false,
                message: 'Route not found.'
            });
        }

        const vehicle = await Vehicle.findById(req.params.id);
        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        // Don't add duplicate route
        if (vehicle.routes.includes(routeId)) {
            return res.status(400).json({
                success: false,
                message: 'Route already assigned to this vehicle.'
            });
        }

        vehicle.routes.push(routeId);
        await vehicle.save();

        return res.status(200).json({
            success: true,
            message: 'Route assigned to vehicle successfully.',
            data: vehicle
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── PUT /api/admin/vehicles/:id/pricing ─────────────────────────────────────
// Update vehicle pricing configuration
// ─────────────────────────────────────────────────────────────────────────────
exports.updatePricing = async (req, res) => {
    try {
        const vehicle = await Vehicle.findByIdAndUpdate(
            req.params.id,
            { $set: { pricing: req.body } },
            { new: true }
        );

        if (!vehicle) {
            return res.status(404).json({
                success: false,
                message: 'Vehicle not found.'
            });
        }

        return res.status(200).json({
            success: true,
            message: 'Pricing updated successfully.',
            data: vehicle.pricing
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ─── GET /api/admin/vehicles/:id/bookings ────────────────────────────────────
// Get booking history for a vehicle
// ─────────────────────────────────────────────────────────────────────────────
exports.getVehicleBookings = async (req, res) => {
    try {
        const Booking = require('../models/Booking');
        const bookings = await Booking.find({ vehicleId: req.params.id })
            .populate('userId', 'name email mobileNumber')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            total: bookings.length,
            data: bookings
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message
        });
    }
};