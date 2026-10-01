const Vehicle = require("../models/Vehicle");
const TransglobeBooking = require("../models/TransglobeBooking");
const { notifyUser } = require("../utils/notificationService");
const Notification = require("../models/Notification");
const sendEmail = require("../utils/sendEmail");
const sendSMS = require("../utils/sendSMS");
const AdminSignup = require("../models/adminSignup");
const User = require("../models/User");

exports.listVehicles = async (req, res) => {
  try {
    const userId = req.user.id || req.user.uid;
    console.log("[DEBUG listVehicles] req.user:", req.user);
    console.log("[DEBUG listVehicles] userId resolved to:", userId);
    const user = await User.findById(userId) || await User.findOne({ uid: userId });
    
    console.log("[DEBUG listVehicles] Found user:", user ? { _id: user._id, name: user.name, assignedRoutes: user.assignedRoutes } : null);

    if (!user) {
        console.log("[DEBUG listVehicles] User not found in DB!");
        return res.status(404).json({ success: false, message: "User not found." });
    }

    const filter = {
      status: "active",
      isEnabled: true,
    };

    if (user.assignedRoutes && user.assignedRoutes.length > 0) {
      filter.routes = { $in: user.assignedRoutes }; // Filter by assigned routes if they exist
    }

    // Filter by vehicle type
    if (req.query.type && ["car", "bus", "truck"].includes(req.query.type)) {
      filter.vehicleType = req.query.type;
    }

    console.log("[DEBUG listVehicles] Query filter:", filter);

    const vehicles = await Vehicle.find(filter)
      .populate(
        "routes",
        "name source destination stops distance estimatedDuration",
      )
      .select("-documents -driverId -currentLocation")
      .sort({ createdAt: -1 });

    console.log("[DEBUG listVehicles] Found vehicles count:", vehicles.length);
    if (vehicles.length > 0) {
      console.log("[DEBUG listVehicles] First vehicle routes:", vehicles[0].routes);
    }

    const formattedVehicles = vehicles.map(v => {
      const vObj = v.toObject ? v.toObject() : v;
      if (!vObj.departureTimings || vObj.departureTimings.length === 0) {
        vObj.departureTimings = ["07:30 AM", "09:00 AM", "11:30 AM", "02:00 PM", "05:00 PM", "07:30 PM"];
      }
      if (!vObj.passengerCapacity || vObj.passengerCapacity <= 0) {
        vObj.passengerCapacity = 24;
      }
      if (!vObj.pricePerSeat && vObj.pricing?.pricePerSeat) {
        vObj.pricePerSeat = vObj.pricing.pricePerSeat;
      } else if (!vObj.pricePerSeat && vObj.pricing?.fixedPrice) {
        vObj.pricePerSeat = vObj.pricing.fixedPrice;
      }
      return vObj;
    });

    return res.status(200).json({
      success: true,
      total: formattedVehicles.length,
      data: formattedVehicles,
    });
  } catch (error) {
    console.error("[DEBUG listVehicles] Error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

function isTimePastInIST(dateStr, timeStr) {
  if (!dateStr || !timeStr) return false;
  try {
    const nowUtc = new Date().getTime();
    // IST offset: +5:30 -> 330 minutes
    const istNow = new Date(nowUtc + (5.5 * 60 * 60 * 1000));
    
    const [year, month, day] = dateStr.split('-').map(Number);
    const match = timeStr.trim().match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
    if (!match) return false;
    
    let hours = parseInt(match[1], 10);
    const minutes = parseInt(match[2], 10);
    const period = match[3].toUpperCase();
    if (period === 'PM' && hours < 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;
    
    const istTodayStr = `${istNow.getUTCFullYear()}-${String(istNow.getUTCMonth() + 1).padStart(2, '0')}-${String(istNow.getUTCDate()).padStart(2, '0')}`;
    
    if (dateStr < istTodayStr) return true;
    if (dateStr > istTodayStr) return false;
    
    // Same day: compare hour & minute
    const nowHours = istNow.getUTCHours();
    const nowMinutes = istNow.getUTCMinutes();
    
    if (hours < nowHours) return true;
    if (hours === nowHours && minutes <= nowMinutes) return true;
    return false;
  } catch (e) {
    return false;
  }
}

function generateSeatLayout(capacity = 24) {
  const cap = Math.max(Number(capacity) || 20, 4);
  const rows = [];
  let seatsAssigned = 0;
  let rowNum = 1;

  while (seatsAssigned < cap) {
    const remaining = cap - seatsAssigned;
    if (remaining === 5) {
      rows.push({
        rowNumber: rowNum,
        isBackRow: true,
        left: [`${rowNum}A`, `${rowNum}B`],
        center: [`${rowNum}C`],
        right: [`${rowNum}D`, `${rowNum}E`]
      });
      seatsAssigned += 5;
    } else if (remaining < 4) {
      const left = [];
      const right = [];
      if (remaining >= 1) left.push(`${rowNum}A`);
      if (remaining >= 2) left.push(`${rowNum}B`);
      if (remaining >= 3) right.push(`${rowNum}C`);
      rows.push({
        rowNumber: rowNum,
        isBackRow: false,
        left,
        right
      });
      seatsAssigned += remaining;
    } else {
      rows.push({
        rowNumber: rowNum,
        isBackRow: false,
        left: [`${rowNum}A`, `${rowNum}B`],
        right: [`${rowNum}C`, `${rowNum}D`]
      });
      seatsAssigned += 4;
    }
    rowNum++;
  }

  const allSeatNumbers = [];
  rows.forEach(r => {
    if (r.left) allSeatNumbers.push(...r.left);
    if (r.center) allSeatNumbers.push(...r.center);
    if (r.right) allSeatNumbers.push(...r.right);
  });

  return {
    totalSeats: allSeatNumbers.length,
    rows,
    allSeatNumbers
  };
}

// ─── GET /api/transglobe/bus/booked-seats ─────────────────────────────────────
// Returns list of seat numbers already booked for a vehicle / route on a specific date & time
// ─────────────────────────────────────────────────────────────────────────────
exports.getBookedSeats = async (req, res) => {
  try {
    const { vehicleId, routeId, date, time } = req.query;
    if (!date || !time) {
      return res.status(400).json({
        success: false,
        message: "date and time query parameters are required.",
      });
    }

    const LogisticsBooking = require("../models/LogisticsBooking");
    const ShuttleBooking = require("../models/ShuttleBooking");

    const query = {
      status: { $nin: ["cancelled", "rejected"] },
      $or: [
        { travelDate: date, departureTime: time },
        { date: date, departureTime: time }
      ]
    };

    const targetConditions = [];
    if (vehicleId) {
      targetConditions.push({ vehicleId: vehicleId });
    }
    if (routeId) {
      targetConditions.push({ routeId: routeId });
    }
    if (targetConditions.length > 0) {
      query.$and = [{ $or: targetConditions }];
    }

    const [logisticsBookings, shuttleBookings] = await Promise.all([
      LogisticsBooking.find(query).select("selectedSeats").lean(),
      ShuttleBooking.find(query).select("selectedSeats").lean()
    ]);

    const bookedSeatsSet = new Set();
    logisticsBookings.forEach(b => {
      if (Array.isArray(b.selectedSeats)) {
        b.selectedSeats.forEach(s => bookedSeatsSet.add(s));
      }
    });
    shuttleBookings.forEach(b => {
      if (Array.isArray(b.selectedSeats)) {
        b.selectedSeats.forEach(s => bookedSeatsSet.add(s));
      }
    });

    let capacity = 24;
    if (vehicleId) {
      const v = await Vehicle.findById(vehicleId).select('passengerCapacity');
      if (v && v.passengerCapacity > 0) {
        capacity = v.passengerCapacity;
      }
    }

    const seatLayout = generateSeatLayout(capacity);
    const isPast = isTimePastInIST(date, time);

    return res.status(200).json({
      success: true,
      date,
      time,
      isPast,
      totalCapacity: capacity,
      seatLayout,
      bookedSeats: Array.from(bookedSeatsSet),
    });
  } catch (error) {
    console.error("[getBookedSeats] Error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─── GET /api/transglobe/vehicles/:id ────────────────────────────────────────
// User sees full details of a single vehicle
// ─────────────────────────────────────────────────────────────────────────────
exports.getVehicleDetail = async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({
      _id: req.params.id,
      status: "active",
      isEnabled: true,
    }).populate(
      "routes",
      "name source destination stops distance estimatedDuration",
    );

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: "Vehicle not found or not available.",
      });
    }

    const vObj = vehicle.toObject ? vehicle.toObject() : vehicle;
    if (!vObj.pricePerSeat && vObj.pricing?.pricePerSeat) {
      vObj.pricePerSeat = vObj.pricing.pricePerSeat;
    } else if (!vObj.pricePerSeat && vObj.pricing?.fixedPrice) {
      vObj.pricePerSeat = vObj.pricing.fixedPrice;
    }

    return res.status(200).json({
      success: true,
      data: vObj,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// PROTECTED APIs — Login required
// ─────────────────────────────────────────────────────────────────────────────

// ─── POST /api/transglobe/bookings/create ────────────────────────────────────
// User creates a new transport booking
// ─────────────────────────────────────────────────────────────────────────────
exports.createBooking = async (req, res) => {
  try {
    const {
      vehicleId,
      pickupLocation,
      dropLocation,
      travelDate,
      travelTime,
      numberOfPassengers,
      purpose,
      specialInstructions,
      distance,
      paymentMethod,
    } = req.body;

    // Validate required fields
    if (
      !vehicleId ||
      !pickupLocation ||
      !dropLocation ||
      !travelDate ||
      !travelTime
    ) {
      return res.status(400).json({
        success: false,
        message:
          "vehicleId, pickupLocation, dropLocation, travelDate and travelTime are required.",
      });
    }

    // Get user ID from token
    const userId = req.user?.id || req.user?.uid || req.user?._id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User not authenticated.",
      });
    }

    // Check vehicle exists and is available
    const vehicle = await Vehicle.findOne({
      _id: vehicleId,
      status: "active",
      isEnabled: true,
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: "Vehicle not found or not available for booking.",
      });
    }

    // Calculate estimated fare
    const distanceKm = distance || 0;
    const pricePerKm = vehicle.pricing?.pricePerKm || 0;
    const driverCharge = vehicle.pricing?.driverCharge || 0;
    const convenienceCharge = vehicle.pricing?.convenienceCharges || 0;

    let estimatedFare = 0;
    if (vehicle.pricing?.isFixedPrice) {
      estimatedFare = vehicle.pricing.fixedPrice;
    } else {
      estimatedFare =
        pricePerKm * distanceKm + driverCharge + convenienceCharge;
    }

    // Create booking
    const booking = new TransglobeBooking({
      userId,
      vehicleId,
      vehicleType: vehicle.vehicleType,
      pickupLocation,
      dropLocation,
      travelDate: new Date(travelDate),
      travelTime,
      numberOfPassengers: numberOfPassengers || 1,
      purpose: purpose || "",
      specialInstructions: specialInstructions || "",
      distance: distanceKm,
      estimatedFare,
      pricingBreakdown: {
        pricePerKm: vehicle.pricing?.pricePerKm || 0,
        driverCharge: vehicle.pricing?.driverCharge || 0,
        tollTax: vehicle.pricing?.tollTax || 0,
        nightCharges: vehicle.pricing?.nightCharges || 0,
        waitingCharges: vehicle.pricing?.waitingCharges || 0,
        parkingCharges: vehicle.pricing?.parkingCharges || 0,
        loadingUnloadingCharges: vehicle.pricing?.loadingUnloadingCharges || 0,
        convenienceCharges: vehicle.pricing?.convenienceCharges || 0,
        stateTax: vehicle.pricing?.stateTax || 0,
      },
      paymentMethod: paymentMethod || "cash",
      status: "pending",
    });

    await booking.save();

    // ─── Notify Admin — New Corporate Booking Created ────────────────────────────
    try {
      // 1. Save notification in DB for admin
      await Notification.create({
        userId: "admin",
        role: "admin",
        title: "🚗 New Booking Request",
        body: `New ${vehicle.vehicleType} booking from ${booking.pickupLocation} to ${booking.dropLocation}`,
        type: "new_booking",
        data: {
          bookingId: booking._id.toString(),
          vehicleType: booking.vehicleType,
          userId: userId.toString(),
        },
      });

      // 2. Send email to all admins
      const admins = await AdminSignup.find({
        role: { $in: ["admin", "superadmin"] },
      }).select("email name");

      for (const admin of admins) {
        await sendEmail(
          admin.email,
          "🚗 New Transglobe Booking Request",
          `Hi ${admin.name},\n\nA new booking has been created:\n\nVehicle: ${vehicle.vehicleName} (${vehicle.vehicleType})\nPickup: ${booking.pickupLocation}\nDrop: ${booking.dropLocation}\nDate: ${booking.travelDate}\nTime: ${booking.travelTime}\n\nPlease login to admin panel to approve.\n\nTransglobe Team`,
        );
      }
    } catch (notifErr) {
      console.warn("[createBooking] Notification failed:", notifErr.message);
    }

    return res.status(201).json({
      success: true,
      message: "Booking created successfully. Waiting for admin approval.",
      data: {
        bookingId: booking._id,
        vehicleType: booking.vehicleType,
        vehicleName: vehicle.vehicleName,
        pickupLocation: booking.pickupLocation,
        dropLocation: booking.dropLocation,
        travelDate: booking.travelDate,
        travelTime: booking.travelTime,
        estimatedFare: booking.estimatedFare,
        status: booking.status,
      },
    });
  } catch (error) {
    console.error("[createBooking] Error:", error.message);
    return res.status(500).json({
      success: false,
      message: "Server error.",
      error: error.message,
    });
  }
};

// ─── GET /api/transglobe/bookings/my ─────────────────────────────────────────
// User sees their own booking history
// ─────────────────────────────────────────────────────────────────────────────
exports.getMyBookings = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?.uid || req.user?._id;

    const bookings = await TransglobeBooking.find({ userId })
      .populate("vehicleId", "vehicleName vehicleType photos numberPlate")
      .populate("driverId", "name mobileNumber")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      total: bookings.length,
      data: bookings,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─── GET /api/transglobe/bookings/:id ────────────────────────────────────────
// User sees single booking detail
// ─────────────────────────────────────────────────────────────────────────────
exports.getBookingById = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?.uid || req.user?._id;

    const booking = await TransglobeBooking.findOne({
      _id: req.params.id,
      userId, // user can only see their own booking
    })
      .populate(
        "vehicleId",
        "vehicleName vehicleType photos numberPlate brand model pricing",
      )
      .populate(
        "driverId",
        "name mobileNumber photo vehicleModel vehicleNumberPlate",
      );

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found.",
      });
    }

    return res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─── POST /api/transglobe/bookings/:id/cancel ────────────────────────────────
// User cancels their booking
// ─────────────────────────────────────────────────────────────────────────────
exports.cancelBooking = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?.uid || req.user?._id;
    const { cancelReason } = req.body;

    const booking = await TransglobeBooking.findOne({
      _id: req.params.id,
      userId,
    });

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found.",
      });
    }

    // Only allow cancel if not completed or already cancelled
    if (["completed", "cancelled"].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot cancel. Booking is already ${booking.status}.`,
      });
    }

    booking.status = "cancelled";
    booking.cancelReason = cancelReason || "";
    await booking.save();

    return res.status(200).json({
      success: true,
      message: "Booking cancelled successfully.",
      data: {
        bookingId: booking._id,
        status: booking.status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN APIs — Admin manages bookings
// ─────────────────────────────────────────────────────────────────────────────

// ─── GET /api/admin/transglobe/bookings ──────────────────────────────────────
// Admin sees all transglobe bookings
// ─────────────────────────────────────────────────────────────────────────────
// exports.adminGetAllBookings = async (req, res) => {
//     try {
//         const filter = {};

//         if (req.query.status)      filter.status      = req.query.status;
//         if (req.query.vehicleType) filter.vehicleType = req.query.vehicleType;

//         const bookings = await TransglobeBooking.find(filter)
//             .populate('userId',    'name email mobileNumber companyName')
//             .populate('vehicleId', 'vehicleName vehicleType numberPlate')
//             .populate('driverId',  'name mobileNumber')
//             .sort({ createdAt: -1 });

//         return res.status(200).json({
//             success: true,
//             total:   bookings.length,
//             data:    bookings
//         });

//     } catch (error) {
//         return res.status(500).json({
//             success: false,
//             message: error.message
//         });
//     }
// };
exports.adminGetAllBookings = async (req, res) => {
  try {
    const filter = {};

    // Filter by status
    if (req.query.status) filter.status = req.query.status;

    // Filter by vehicle type
    if (req.query.vehicleType) filter.vehicleType = req.query.vehicleType;

    // ✅ NEW — Filter by date
    if (req.query.date) {
      const startOfDay = new Date(req.query.date);
      startOfDay.setHours(0, 0, 0, 0);

      const endOfDay = new Date(req.query.date);
      endOfDay.setHours(23, 59, 59, 999);

      filter.travelDate = {
        $gte: startOfDay,
        $lte: endOfDay,
      };
    }

    // Filter by payment status
    if (req.query.paymentStatus) {
      filter.paymentStatus = req.query.paymentStatus;
    }

    const bookings = await TransglobeBooking.find(filter)
      .populate("userId", "name email mobileNumber companyName")
      .populate("vehicleId", "vehicleName vehicleType numberPlate")
      .populate("driverId", "name mobileNumber")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      total: bookings.length,
      data: bookings,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─── PUT /api/admin/transglobe/bookings/:id/status ───────────────────────────
// Admin updates booking status
// ─────────────────────────────────────────────────────────────────────────────
exports.adminUpdateBookingStatus = async (req, res) => {
  try {
    const { status, driverId, adminNotes } = req.body;

    const allowed = [
      "pending",
      "approved",
      "assigned",
      "in_progress",
      "completed",
      "cancelled",
    ];
    if (!allowed.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Allowed: ${allowed.join(", ")}`,
      });
    }

    const booking = await TransglobeBooking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found.",
      });
    }

    booking.status = status;
    if (driverId) booking.driverId = driverId;
    if (adminNotes) booking.adminNotes = adminNotes;

    await booking.save();

    // ─── Notify User — Booking Status Changed ────────────────────────────────────
    try {
      // Get user details for SMS + email
      const user = await User.findById(booking.userId).select(
        "name email mobileNumber fcmToken uid",
      );

      if (user) {
        let title = "";
        let body = "";
        let emailSubject = "";
        let emailBody = "";
        let smsMessage = "";

        if (status === "approved") {
          title = "✅ Booking Approved!";
          body = `Your ${booking.vehicleType} booking has been approved. Travel date: ${booking.travelDate.toDateString()}`;
          emailSubject = "✅ Your Transglobe Booking is Approved";
          emailBody = `Hi ${user.name},\n\nGreat news! Your booking has been approved.\n\nVehicle Type: ${booking.vehicleType}\nPickup: ${booking.pickupLocation}\nDrop: ${booking.dropLocation}\nDate: ${booking.travelDate.toDateString()}\nTime: ${booking.travelTime}\nFare: ₹${booking.estimatedFare}\n\nThank you for choosing Transglobe!`;
          smsMessage = `Transglobe: Your ${booking.vehicleType} booking is APPROVED. Travel date: ${booking.travelDate.toDateString()}. For help call us.`;
        } else if (status === "cancelled") {
          title = "❌ Booking Cancelled";
          body = `Your ${booking.vehicleType} booking has been cancelled.`;
          emailSubject = "❌ Your Transglobe Booking is Cancelled";
          emailBody = `Hi ${user.name},\n\nUnfortunately your booking has been cancelled.\n\nVehicle Type: ${booking.vehicleType}\nPickup: ${booking.pickupLocation}\nDrop: ${booking.dropLocation}\nDate: ${booking.travelDate.toDateString()}\n\nFor queries please contact us.\n\nTransglobe Team`;
          smsMessage = `Transglobe: Your ${booking.vehicleType} booking has been CANCELLED. For help contact us.`;
        } else if (status === "assigned") {
          title = "🚗 Driver Assigned!";
          body = `A driver has been assigned to your booking.`;
          emailSubject = "🚗 Driver Assigned for Your Transglobe Booking";
          emailBody = `Hi ${user.name},\n\nA driver has been assigned to your booking.\n\nVehicle Type: ${booking.vehicleType}\nPickup: ${booking.pickupLocation}\nDrop: ${booking.dropLocation}\nDate: ${booking.travelDate.toDateString()}\n\nTransglobe Team`;
          smsMessage = `Transglobe: Driver assigned for your ${booking.vehicleType} booking on ${booking.travelDate.toDateString()}.`;
        } else if (status === "completed") {
          title = "🎉 Trip Completed!";
          body = `Your trip is completed. Thank you for choosing Transglobe!`;
          emailSubject = "🎉 Trip Completed - Thank you!";
          emailBody = `Hi ${user.name},\n\nYour trip has been completed successfully!\n\nVehicle Type: ${booking.vehicleType}\nPickup: ${booking.pickupLocation}\nDrop: ${booking.dropLocation}\nFare: ₹${booking.estimatedFare}\n\nThank you for choosing Transglobe!`;
          smsMessage = `Transglobe: Your trip is completed. Fare: Rs.${booking.estimatedFare}. Thank you!`;
        }

        if (title) {
          // 1. Save notification in DB
          await Notification.create({
            userId: booking.userId.toString(),
            role: "user",
            title,
            body,
            type: "booking_update",
            data: {
              bookingId: booking._id.toString(),
              status,
            },
          });

          // 2. Push notification
          await notifyUser(booking.userId.toString(), {
            title,
            body,
            data: { bookingId: booking._id.toString(), type: "booking_update" },
          });

          // 3. Email notification
          if (user.email) {
            await sendEmail(user.email, emailSubject, emailBody);
          }

          // 4. SMS notification
          if (user.mobileNumber) {
            await sendSMS(user.mobileNumber, smsMessage);
          }
        }
      }
    } catch (notifErr) {
      console.warn(
        "[adminUpdateBookingStatus] Notification failed:",
        notifErr.message,
      );
    }

    return res.status(200).json({
      success: true,
      message: `Booking status updated to ${status}.`,
      data: booking,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ─── PUT /api/transglobe/admin/bookings/:id/payment ──────────────────────────
// Admin updates payment status of a booking
// ─────────────────────────────────────────────────────────────────────────────
exports.adminUpdatePaymentStatus = async (req, res) => {
  try {
    const { paymentStatus, paymentMethod } = req.body;

    // Validate
    if (!paymentStatus) {
      return res.status(400).json({
        success: false,
        message: "paymentStatus is required.",
      });
    }

    if (!["unpaid", "paid"].includes(paymentStatus)) {
      return res.status(400).json({
        success: false,
        message: "paymentStatus must be unpaid or paid.",
      });
    }

    const booking = await TransglobeBooking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: "Booking not found.",
      });
    }

    // Update payment status
    booking.paymentStatus = paymentStatus;
    if (paymentMethod) booking.paymentMethod = paymentMethod;

    // If paid — auto complete booking if in_progress
    if (paymentStatus === "paid" && booking.status === "in_progress") {
      booking.status = "completed";
    }

    await booking.save();

    return res.status(200).json({
      success: true,
      message: `Payment status updated to ${paymentStatus}.`,
      data: {
        bookingId: booking._id,
        paymentStatus: booking.paymentStatus,
        paymentMethod: booking.paymentMethod,
        status: booking.status,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
