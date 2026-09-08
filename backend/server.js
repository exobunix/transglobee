require("dotenv").config();
const express = require("express");
const connectDB = require("./config/db");
const http = require("http");
const cors = require('cors');
const initSocket = require("./socket/socketHandler");
const {
  requestLogger,
  centralErrorHandler,
} = require("./middlewares/requestLogger");

const app = express();
app.use(requestLogger); // Moved to top

const requestBuckets = new Map();
let io = null;

const securityHeaders = (req, res, next) => {
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader(
    "Permissions-Policy",
    "geolocation=(), microphone=(), camera=()",
  );
  next();
};

const basicRateLimiter =
  ({ windowMs = 15 * 60 * 1000, maxRequests = 300 } = {}) =>
  (req, res, next) => {
    const key = `${req.ip}:${req.path}`;
    const now = Date.now();
    const bucket = requestBuckets.get(key);

    if (!bucket || now > bucket.resetAt) {
      requestBuckets.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    if (bucket.count >= maxRequests) {
      const retryAfterSeconds = Math.ceil((bucket.resetAt - now) / 1000);
      res.setHeader("Retry-After", retryAfterSeconds);
      return res.status(429).json({
        success: false,
        message: "Too many requests. Please try again later.",
      });
    }

    bucket.count += 1;
    next();
  };

// Trust proxy for Railway/Heroku
app.set("trust proxy", 1);
app.disable("x-powered-by");

// CORS Configuration
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin', 'X-Dev-Uid', 'X-Dev-Id', 'x-dev-uid', 'x-dev-id', 'X-Admin-Fallback-Auth', 'x-admin-fallback-auth', 'X-Request-Intercepted', 'x-request-intercepted']
}));

app.use(securityHeaders);
app.use(basicRateLimiter());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Attach socket.io to request object
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Ensure MongoDB is connected before hitting any API handler that needs it.
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (error) {
    res.status(503).json({
      success: false,
      message: "Database connection unavailable.",
      error: error.message,
    });
  }
});

// Import Routes
const userRoutes = require("./routes/userRoutes");
const driverRoutes = require("./routes/driverRoutes");
const adminRoutes = require("./routes/routeAdmin");
const rideRoutes = require("./routes/rideRoutes");
const mapsRoutes = require("./routes/mapsRoutes");
const typeGoodRoutes = require("./routes/typeGoodRoutes");
const logisticsVehicleRoutes = require("./routes/logisticsVehicleRoutes");
const logisticGoodRoutes = require("./routes/logisticGoodRoutes");
const logisticsBookingRoutes = require("./routes/logisticsBookingRoutes");
const corporateRoutes = require("./routes/corporateRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const authRoutes = require("./routes/authRoutes");
const shuttleRoutes = require("./routes/shuttleRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const supervisorApiRoutes = require("./routes/supervisorRoutes");
const transglobeRoutes = require("./routes/transglobeRoutes"); // ✅ ADD
const pricingRoutes = require("./routes/pricingRoutes");
const ratingController = require("./controllers/ratingController");
const { verifyToken } = require("./middlewares/authMiddleware");
const { updateBilling } = require("./controllers/logisticsBookingController");

// Root & Health Check Routes
app.get("/", (req, res) =>
  res.send("API is running (v1.0.5) with Socket.io..."),
);
app.get("/api/version", (req, res) =>
  res.json({ version: "1.0.5", status: "billing_put_fix" }),
);
app.get("/health", (req, res) =>
  res.status(200).json({ status: "ok", timestamp: new Date() }),
);

// Direct Billing Patch/Put Routes (before other mounting)
app.patch("/api/logistics-bookings/:id/billing", updateBilling);
app.patch("/api/logistics-booking/:id/billing", updateBilling);
app.put("/api/logistics-bookings/:id/billing", updateBilling);
app.put("/api/logistics-booking/:id/billing", updateBilling);
app.patch("/logistics-bookings/:id/billing", updateBilling); // Root level fallback
app.put("/logistics-bookings/:id/billing", updateBilling); // Root level fallback

// Register Routes
app.use("/api/user", userRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/driver", driverRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/ride", rideRoutes);
app.use("/api/rides", rideRoutes);
app.use("/api/maps", mapsRoutes);
app.use("/maps", mapsRoutes);
app.use("/api/supervisor/maps", mapsRoutes);
app.use("/api/typegood", typeGoodRoutes);
app.use("/api/logistics-vehicles", logisticsVehicleRoutes);
app.use("/api/logistic-goods", logisticGoodRoutes);
app.use("/api/corporate", corporateRoutes);
app.use("/api/payment", paymentRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/wallet", paymentRoutes);
app.use("/api/shuttle", shuttleRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/supervisor", supervisorApiRoutes);
app.use("/api/transglobe", transglobeRoutes); // ✅ ADD
app.use("/api/pricing", pricingRoutes);

app.post("/api/ratings", verifyToken, ratingController.submitRating);
app.get("/api/ratings/booking/:bookingId", ratingController.getBookingRatings);
app.get("/api/ratings/driver/:driverId", ratingController.getDriverRatings);
app.get("/api/ratings/user/:userId", ratingController.getUserRatings);

// Bookings & Logistics Routes
app.use("/api/bookings", logisticsBookingRoutes);
app.use("/api/booking", logisticsBookingRoutes);
app.use("/api", logisticsBookingRoutes);

// Catch-all 404 handler for debugging missing routes
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.warn(
    `[404 NOT FOUND] [${timestamp}] ${req.method} ${req.originalUrl || req.url}`,
  );
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.method} ${req.url}`,
    tip: "Check pluralization (bookings vs booking) and base path (/api/...)",
  });
});

// Centralized Error Handler (must be last)
app.use(centralErrorHandler);

if (require.main === module) {
  const server = http.createServer(app);
  io = initSocket(server);

  const PORT = process.env.PORT || 8082;
  server.listen(PORT, "0.0.0.0", () => {
    console.log(`>>> Server is active and listening on port ${PORT}`);
  });
}

module.exports = app;
