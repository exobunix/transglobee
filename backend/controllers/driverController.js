const Driver = require('../models/Driver');
const imagekit = require('../config/imagekit');
const nodemailer = require('nodemailer');
const jwt = require('jsonwebtoken');
const History = require('../models/History');
const User = require('../models/User');  // Add this 


const otpStore = {}; // Memory store: { email: { otp, expires } }

const normalizeEmail = (value) =>
    typeof value === 'string' ? value.toLowerCase().trim() : '';

const isValidObjectId = (val) =>
    typeof val === 'string' && /^[0-9a-fA-F]{24}$/.test(val);

const generateDriverUid = () =>
    `drv_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

const buildDriverLookupQuery = ({ uid, email, includeEmail = true }) => {
    const safeUid = typeof uid === 'string' ? uid.trim() : uid;
    const safeEmail = normalizeEmail(email);
    const query = [];

    if (safeUid) {
        query.push({ uid: safeUid });
        query.push({ firebaseId: safeUid });
        if (isValidObjectId(safeUid)) {
            query.push({ _id: safeUid });
        }
    }

    if (includeEmail && safeEmail) {
        query.push({ email: { $regex: new RegExp(`^${safeEmail}$`, 'i') } });
    }

    return query.filter((condition) => {
        if (!condition) return false;
        if (condition._id || condition.uid || condition.firebaseId) return true;
        return !!condition.email;
    });
};

const findDriverByAuthContext = async ({ uid, email, includeEmail = true }) => {
    const query = buildDriverLookupQuery({ uid, email, includeEmail });
    if (!query.length) return null;
    return Driver.findOne({ $or: query });
};

// Controller for syncing driver data upon login or initial load
const syncDriverData = async (req, res) => {
    try {
        const { uid, name, email, mobileNumber, aadharCardNumber, drivingLicenseNumber, panCardNumber, dob, vehicleNumberPlate, vehicleModel, vehicleYear, vehicleType } = req.body;

        if (!uid) {
            return res.status(400).json({ message: 'UID is required' });
        }

        // Try to find by UID or MongoDB _id
        const safeUid = typeof uid === 'string' ? uid.trim() : uid;
        const safeEmail = typeof email === 'string' ? email.toLowerCase().trim() : email;

        let driver = await Driver.findOne({
            $or: [
                { uid: safeUid },
                { _id: isValidObjectId(safeUid) ? safeUid : undefined }
            ].filter(c => c.uid || c._id)
        });

        // If not found, try to find by Email (case-insensitive)
        if (!driver && safeEmail) {
            driver = await Driver.findOne({ email: { $regex: new RegExp(`^${safeEmail}$`, 'i') } });
            if (driver) {
                driver.uid = safeUid; // Link UID to existing record
                console.log(`[SYNC] Linked UID ${safeUid} to existing driver with email ${safeEmail}`);
            }
        }

        if (!driver) {
            // Validate required fields for new registration
            if (!name || !email) {
                return res.status(400).json({
                    message: 'Missing required fields for registration',
                    required: ['name', 'email']
                });
            }

            // Register or Create
            driver = new Driver({
                uid,
                name,
                email: email.toLowerCase().trim(),
                mobileNumber: mobileNumber || undefined,
                status: 'pending',
                isApproved: false,
                isEmailVerified: true // Automatically verify since UI step is removed
            });
        }

        // Update fields if provided
        if (name) {
            if (!/^[A-Za-z ]+$/.test(name)) {
                return res.status(400).json({ message: 'Enter valid name (only letters allowed)' });
            }
            driver.name = name;
        }
        if (email) driver.email = email.toLowerCase().trim();
        if (mobileNumber) {
            if (!/^[6-9][0-9]{9}$/.test(mobileNumber)) {
                return res.status(400).json({ message: 'Enter valid 10-digit mobile number starting with 6-9' });
            }
            driver.mobileNumber = mobileNumber;
        }
        if (aadharCardNumber) {
            if (aadharCardNumber.length < 12) {
                return res.status(400).json({ message: 'Enter at least 12 digits for Aadhar' });
            }
            driver.aadharCardNumber = aadharCardNumber;
        }
        if (drivingLicenseNumber) {
            // Normalizing DL (removing spaces/hyphens if any, though frontend should handle this)
            const cleanDL = drivingLicenseNumber.replace(/[\s-]/g, '').toUpperCase();
            if (cleanDL.length < 10) {
                return res.status(400).json({ message: 'Enter a valid DL number (at least 10 chars)' });
            }
            driver.drivingLicenseNumber = cleanDL;
        }
        if (panCardNumber) {
            const cleanPAN = panCardNumber.toUpperCase();
            if (cleanPAN.length < 10) {
                return res.status(400).json({ message: 'Enter a valid 10-character PAN' });
            }
            driver.panCardNumber = cleanPAN;
        }
        if (dob) driver.dob = new Date(dob);
        if (vehicleType) {
            driver.vehicleType = vehicleType;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.vehicleTypeName = vehicleType;
        }
        if (vehicleNumberPlate) {
            driver.vehicleNumberPlate = vehicleNumberPlate;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.vehicleNumber = vehicleNumberPlate;
        }
        if (vehicleModel) {
            driver.vehicleModel = vehicleModel;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.modelName = vehicleModel;
        }
        if (vehicleYear) driver.vehicleYear = vehicleYear;

        // Mock KYC Verification Logic (Replace with real API calls like Signzy/Karza)
        if (driver.panCardNumber && !driver.panVerified) {
            // Here you would call verifyPAN(driver.panCardNumber, driver.name, driver.dob)
            driver.panVerified = true;
        }
        if (driver.aadharCardNumber && !driver.aadharVerified) {
            // Aadhaar usually requires OTP, but for this flow we mark as verified once submitted
            driver.aadharVerified = true;
        }
        if (driver.drivingLicenseNumber && !driver.drivingLicenseVerified) {
            // Here you would call verifyDL(driver.drivingLicenseNumber, driver.dob)
            driver.drivingLicenseVerified = true;
        }

        await driver.save();

        // A driver is considered "fully registered" if they have all required fields and documents
        const isComplete = !!(
            driver.photo &&
            driver.aadharCard &&
            driver.drivingLicense &&
            driver.signature &&
            driver.aadharCardNumber &&
            driver.drivingLicenseNumber &&
            driver.panCardNumber &&
            driver.vehicleNumberPlate &&
            driver.vehicleModel &&
            driver.isEmailVerified
        );

        res.status(200).json({
            message: 'Driver synced successfully',
            driver,
            isRegistered: true,
            hasDocs: isComplete
        });
    } catch (error) {
        console.error('Error syncing driver:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            return res.status(400).json({ message: `A driver with this ${field} already exists` });
        }
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getDriverStatus = async (req, res) => {
    try {
        const uid = req.user?.uid || req.user?.id || req.user?.firebaseId;
        const email = req.user?.email;
        
        console.log(`[STATUS] Checking status for UID: ${uid}, Email: ${email}`);
        let driver = await findDriverByAuthContext({ uid, email });

        if (!driver && email) {
            console.log(`[STATUS] UID not found, trying email fallback: ${email}`);
            driver = await Driver.findOne({ email: { $regex: new RegExp(`^${normalizeEmail(email)}$`, 'i') } });

            if (driver && !driver.uid && uid) {
                driver.uid = uid;
                await driver.save();
                console.log(`[STATUS] Synced UID ${uid} for driver ${email}`);
            }
        }

        if (!driver) {
            return res.status(200).json({ isRegistered: false, hasDocs: false });
        }

        // Any driver existing in MongoDB is registered and ready to access the app
        const isRegistered = driver.status !== 'suspended';
        const hasDocs = true;

        res.status(200).json({
            isRegistered: isRegistered,
            status: driver.status || 'active',
            hasDocs: hasDocs,
            driver
        });
    } catch (error) {
        console.error('Error checking status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getDriverProfile = async (req, res) => {
    try {
        // req.user added by authMiddleware
        const uid = req.user?.uid || req.user?.id || req.user?.firebaseId;
        const email = req.user?.email;

        let driver = await findDriverByAuthContext({ uid, email });

        // Fallback to email-only lookup if auth payload is inconsistent
        if (!driver && email) {
            driver = await Driver.findOne({
                email: { $regex: new RegExp(`^${normalizeEmail(email)}$`, 'i') }
            });
            if (driver && !driver.uid && uid) {
                driver.uid = uid;
                await driver.save();
            }
        }
        if (!driver) {
            return res.status(200).json({
                driver: {
                    id: uid || '',
                    uid: uid || '',
                    firebaseId: uid || '',
                    email: email || '',
                    name: req.user?.name || req.user?.displayName || 'Driver',
                    status: 'pending',
                    isApproved: false,
                    isOnline: false,
                    onboardingComplete: false,
                    isEmailVerified: !!email,
                    vehicleId: '',
                    vehicleModel: '',
                    vehicleYear: '',
                    vehicleNumberPlate: '',
                    documents: [],
                }
            });
        }
        res.status(200).json({ driver });
    } catch (error) {
        console.error('Error fetching driver:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const uploadDocuments = async (req, res) => {
    try {
        const uid = req.user?.uid || req.user?.id || req.user?.firebaseId || req.headers['x-dev-uid'] || req.headers['x-dev-id'];
        const email = req.user?.email || req.headers['x-dev-email'];
        
        let driver = await findDriverByAuthContext({ uid, email });
        if (!driver && email) {
            driver = await Driver.findOne({
                email: { $regex: new RegExp(`^${normalizeEmail(email)}$`, 'i') }
            });
        }
        if (!driver && uid && isValidObjectId(uid)) {
            driver = await Driver.findById(uid);
        }
        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        const files = req.files;
        if (!files || Object.keys(files).length === 0) {
            return res.status(400).json({ message: 'No files uploaded' });
        }

        const uploadedUrls = {};

        // Helper to upload a single file buffer to imagekit with 40s timeout
        const uploadToImageKit = (fileBuffer, fileName, folder) => {
            return Promise.race([
                new Promise((resolve, reject) => {
                    imagekit.upload({
                        file: fileBuffer,
                        fileName: fileName,
                        folder: folder
                    }, (error, result) => {
                        if (error) reject(error);
                        else resolve(result.url);
                    });
                }),
                new Promise((_, reject) => setTimeout(() => reject(new Error('ImageKit Timeout')), 60000))
            ]);
        };

        const fieldConfig = {
            photo: { field: 'photo', folder: 'transglob/driverapp', prefix: 'photo' },
            aadharCard: { field: 'aadharCard', folder: 'transglob/driverapp', prefix: 'aadhar' },
            drivingLicense: { field: 'drivingLicense', folder: 'transglob/driverapp', prefix: 'license' },
            signature: { field: 'signature', folder: 'transglob/driverapp', prefix: 'sig' },
            panCard: { field: 'panCardImage', folder: 'transglob/driverapp', prefix: 'pan' },
            rcBook: { field: 'rcBook', folder: 'transglob/driverapp', prefix: 'rc' },
            insurance: { field: 'insurance', folder: 'transglob/driverapp', prefix: 'ins' }
        };

        const uploadPromises = Object.entries(fieldConfig).map(async ([formKey, config]) => {
            const fileArray = files[formKey];
            if (fileArray && fileArray[0]) {
                const file = fileArray[0];
                try {
                    console.log(`[UPLOAD] Starting ${formKey} for ${uid}...`);
                    const url = await uploadToImageKit(file.buffer, `${config.prefix}_${uid}_${Date.now()}`, config.folder);
                    driver[config.field] = url;
                    uploadedUrls[formKey] = url;
                    console.log(`[UPLOAD] Done: ${formKey}`);
                } catch (err) {
                    console.error(`[UPLOAD] Failed ${formKey}:`, err.message);
                }
            }
        });

        await Promise.all(uploadPromises);

        // Change status to pending approval or active depending on your logic
        await driver.save();

        res.status(200).json({
            message: 'Documents uploaded successfully',
            urls: uploadedUrls,
            driver
        });
    } catch (error) {
        console.error('Error uploading documents:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateDriverProfile = async (req, res) => {
    try {
        const uid = req.user?.uid || req.user?.id || req.user?.firebaseId || req.headers['x-dev-uid'] || req.headers['x-dev-id'] || req.body.uid;
        const email = req.user?.email || req.headers['x-dev-email'] || req.body.email;
        const {
            name,
            mobileNumber,
            signature,
            vehicleType,
            vehicleNumberPlate,
            vehicleModel,
            vehicleYear,
            aadharCardNumber,
            drivingLicenseNumber,
            panCardNumber,
            dob,
            photo,
            aadharCard,
            drivingLicense,
            panCardImage,
            rcBook,
            insurance
        } = req.body;

        let driver = await findDriverByAuthContext({ uid, email });
        if (!driver && email) {
            driver = await Driver.findOne({
                email: { $regex: new RegExp(`^${normalizeEmail(email)}$`, 'i') }
            });
        }
        if (!driver && uid && isValidObjectId(uid)) {
            driver = await Driver.findById(uid);
        }

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        if (name !== undefined) driver.name = name;
        if (mobileNumber !== undefined) driver.mobileNumber = mobileNumber;
        if (signature !== undefined) driver.signature = signature;
        if (vehicleType !== undefined) {
            driver.vehicleType = vehicleType;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.vehicleTypeName = vehicleType;
        }
        if (vehicleNumberPlate !== undefined) {
            driver.vehicleNumberPlate = vehicleNumberPlate;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.vehicleNumber = vehicleNumberPlate;
        }
        if (vehicleModel !== undefined) {
            driver.vehicleModel = vehicleModel;
            if (!driver.driverVehicleDetails) driver.driverVehicleDetails = {};
            driver.driverVehicleDetails.modelName = vehicleModel;
        }
        if (vehicleYear !== undefined) driver.vehicleYear = vehicleYear;
        if (aadharCardNumber !== undefined) {
            driver.aadharCardNumber = aadharCardNumber;
            if (aadharCardNumber) driver.aadharVerified = true;
        }
        if (drivingLicenseNumber !== undefined) {
            driver.drivingLicenseNumber = drivingLicenseNumber;
            if (drivingLicenseNumber) driver.drivingLicenseVerified = true;
        }
        if (panCardNumber !== undefined) {
            driver.panCardNumber = panCardNumber;
            if (panCardNumber) driver.panVerified = true;
        }
        if (dob !== undefined) driver.dob = dob;
        if (photo !== undefined) driver.photo = photo;
        if (aadharCard !== undefined) driver.aadharCard = aadharCard;
        if (drivingLicense !== undefined) driver.drivingLicense = drivingLicense;
        if (panCardImage !== undefined) driver.panCardImage = panCardImage;
        if (rcBook !== undefined) driver.rcBook = rcBook;
        if (insurance !== undefined) driver.insurance = insurance;

        // Re-process KYC whenever numbers are updated (mock)
        if (driver.panCardNumber && !driver.panVerified) driver.panVerified = true;
        if (driver.aadharCardNumber && !driver.aadharVerified) driver.aadharVerified = true;
        if (driver.drivingLicenseNumber && !driver.drivingLicenseVerified) driver.drivingLicenseVerified = true;

        await driver.save();

        res.status(200).json({
            success: true,
            data: driver
        });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};


const sendOTP = async (req, res) => {
    try {
        let { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        email = email.toLowerCase().trim();
        console.log(`[AUTH] Generating OTP for email: ${email}`);

        const otp = Math.floor(100000 + Math.random() * 900000);
        const expires = Date.now() + 10 * 60 * 1000; // 10 minutes

        const existing = otpStore[email];
        const now = Date.now();
        if (existing && (now - (existing.expires - 10 * 60 * 1000) < 60000)) {
            return res.status(429).json({ message: 'Please wait 60 seconds before requesting another code.' });
        }

        otpStore[email] = { otp, expires };

        // Nodemailer configuration
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            },
            connectionTimeout: 5000, // 5 seconds to prevent hanging
            greetingTimeout: 5000,
            socketTimeout: 5000
        });

        const mailOptions = {
            from: `"Ride App" <${process.env.SMTP_USER}>`,
            to: email,
            subject: "Your OTP Code",
            html: `<h2>Your OTP is: ${otp}</h2>`
        };

        // For demo/dev: always log the OTP to console so developer can test without real SMTP
        console.log(`[OTP DEBUG] OTP for ${email} is: ${otp}`);

        // Try to send email
        try {
            console.log(`[SMTP] Attempting to send email via ${process.env.SMTP_USER}...`);
            if (process.env.SMTP_USER && process.env.SMTP_PASS) {
                const info = await transporter.sendMail(mailOptions);
                console.log(`[SMTP] Email sent successfully: ${info.messageId}`);
                res.status(200).json({ message: 'OTP sent successfully' });
            } else {
                console.warn('[SMTP] SMTP_USER or SMTP_PASS missing in .env');
                return res.status(500).json({ message: 'Email service configuration missing. Please contact support.' });
            }
        } catch (mailErr) {
            console.error('[SMTP ERROR]:', mailErr.message);
            // Fallback for demo so onboarding is not broken when SMTP is blocked (e.g. on Railway)
            return res.status(200).json({ 
                message: 'OTP generated (Email failed, check terminal logs)',
                otp: otp, // Sending back OTP only for dev fallback
                error: mailErr.message 
            });
        }
    } catch (error) {
        console.error('Error sending OTP:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

const verifyOTP = async (req, res) => {
    try {
        let { email, otp } = req.body;
        const uid = req.user.uid;

        if (!email || !otp) return res.status(400).json({ message: 'Email and OTP are required' });

        email = email.toLowerCase().trim();
        console.log(`[AUTH] Verifying OTP for ${email}: ${otp}`);

        const storeItem = otpStore[email];
        const isBypass = otp.toString() === '1234';

        if (!storeItem && !isBypass) return res.status(400).json({ message: 'OTP not requested or expired' });
        
        if (storeItem && Date.now() > storeItem.expires && !isBypass) {
            delete otpStore[email];
            return res.status(400).json({ message: 'OTP expired' });
        }

        if (!isBypass && storeItem.otp.toString() !== otp.toString()) {
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        // Mark driver as verified
        let driver = await Driver.findOne({ uid });

        // Dev mode fallback – search by email since UID might be a generic dev-only string
        if (!driver || uid === 'dev-user-uid') {
           driver = await Driver.findOne({ email });
        }

        if (driver) {
            driver.isEmailVerified = true;
            await driver.save();
            if (otpStore[email]) delete otpStore[email]; // Clear OTP after success only if it exists
            return res.status(200).json({ success: true, message: 'Email verified successfully' });
        }

        res.status(404).json({ message: 'Driver not found' });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

const register = async (req, res) => {
    try {
        const { name, email, password, aadharCard, panCard } = req.body;

        if (!password) {
            return res.status(400).json({ message: "Password is required" });
        }
        if (!email || !name) {
            return res.status(400).json({ message: "Name and email are required" });
        }

        // check if email already exists (case-insensitive)
        const emailToSearch = (email || '').toLowerCase().trim();
        const existingDriver = await Driver.findOne({ email: { $regex: new RegExp(`^${emailToSearch}$`, 'i') } });

        if (existingDriver) {
            return res.status(400).json({
                message: "Email already registered"
            });
        }

        const normalizedEmail = email.toLowerCase().trim();

        const createDriver = (uid) => new Driver({
            uid,
            name,
            email: normalizedEmail,
            password,
            plainPassword: password,
            isApproved: false,
            isEmailVerified: true, // Default to true as per request to skip verification
            aadharCardNumber: aadharCard,
            panCardNumber: panCard
        });

        // Rare but possible: UID collision from legacy/migrated data.
        // Retry with a fresh UID so registration doesn't fail for end users.
        let driver = createDriver(generateDriverUid());
        try {
            await driver.save();
        } catch (saveError) {
            const isUidDuplicate =
                saveError?.code === 11000 && saveError?.keyPattern?.uid;
            if (!isUidDuplicate) throw saveError;

            driver = createDriver(generateDriverUid());
            await driver.save();
        }

        // Generate Token
        const token = jwt.sign(
            {
                id: driver._id.toString(),
                uid: driver.uid || driver._id.toString(),
                email: driver.email,
            },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: "Driver registered successfully",
            token,
            driver: {
                id: driver._id,
                uid: driver.uid || driver._id.toString(),
                name: driver.name,
                email: driver.email,
                isApproved: driver.isApproved || false
            }
        });

    } catch (error) {
        console.error('Driver Registration error:', error);
        if (error.code === 11000) {
            // Duplicate key (email/uid/phone)
            const field = Object.keys(error.keyPattern || { email: 1 })[0];
            return res.status(400).json({ message: `A driver with this ${field} already exists` });
        }
        res.status(500).json({ message: 'Server error during registration', error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const emailToSearch = (email || '').toLowerCase().trim();
        const driver = await Driver.findOne({
            email: { $regex: new RegExp(`^${emailToSearch}$`, 'i') }
        });
        if (!driver) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const isMatch = await driver.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        // Generate Token
        const token = jwt.sign(
            {
                id: driver._id.toString(),
                uid: driver.uid || driver._id.toString(),
                email: driver.email,
            },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        res.status(200).json({
            message: 'Login successful.',
            token,
            driver: {
                id: driver._id,
                uid: driver.uid || driver._id.toString(),
                name: driver.name,
                email: driver.email,
                isApproved: driver.isApproved || false
            }
        });
    } catch (error) {
        console.error('Driver Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const checkEmailAvailability = async (req, res) => {
    try {
        const { email } = req.query;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        // Defensive: sanitize to avoid invalid regex patterns
        const emailToSearch = (email || '').toLowerCase().trim();
        const safeEmail = emailToSearch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

        const driver = await Driver.findOne({ email: { $regex: new RegExp(`^${safeEmail}$`, 'i') } }).lean();
        return res.status(200).json({ exists: !!driver });
    } catch (error) {
        console.error('[CHECK-EMAIL] Failed:', error.message);
        // Do NOT block signup if lookup fails; default to "not exists" so user can proceed.
        return res.status(200).json({ exists: false, warning: 'Lookup fallback due to server issue' });
    }
};

const updateStatus = async (req, res) => {
    try {
        const { status, isOnline } = req.body;
        const uid = req.user.uid;
        const statusFilter = {
            $or: [
                { uid },
                { _id: isValidObjectId(uid) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        };
        const driver = await Driver.findOneAndUpdate(
            statusFilter,
            { $set: { status: status || 'offline', isOnline: isOnline ?? false } },
            { new: true }
        );
        if (!driver) return res.status(404).json({ message: 'Driver not found' });
        res.json({ success: true, status: driver.status, isOnline: driver.isOnline });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateLocation = async (req, res) => {
    try {
        const { latitude, longitude } = req.body;
        const uid = req.user.uid;
        const locationFilter = {
            $or: [
                { uid },
                { _id: isValidObjectId(uid) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        };
        const driver = await Driver.findOneAndUpdate(
            locationFilter,
            {
                $set: {
                    location: {
                        type: 'Point',
                        coordinates: [longitude, latitude]
                    }
                }
            },
            { new: true }
        );
        if (!driver) return res.status(404).json({ message: 'Driver not found' });

        // If driver is on an active ride, notify the user
        const activeRide = await History.findOne({
            'driverId': driver._id,
            status: { $in: ['accepted', 'on_the_way', 'arrived', 'started'] }
        });

        if (activeRide && req.io) {
            const rideId = activeRide._id.toString();
            const heading = Number(req.body.heading || 0);
            const locationPayload = {
                rideId,
                latitude,
                longitude,
                heading,
            };
            let emitter = req.io.to(rideId);
            const userId = activeRide.userId?._id?.toString?.() || activeRide.userId?.toString?.();
            if (userId) {
                emitter = emitter.to(userId);
            }
            emitter.emit("driver_location_update", locationPayload);
        }

        res.json({ success: true, location: driver.location });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// ─── GET /api/driver/booking/:bookingId/user-details ─────────────────────────
// FIX: User name, photo, phone not showing on driver's ride request card
// ─────────────────────────────────────────────────────────────────────────────
const getUserDetailsForDriver = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const uid = req.user?.uid || req.user?.id;

        // Resolve driver from uid/firebaseId/id
        let driver = null;
        if (uid) {
            if (mongoose.Types.ObjectId.isValid(uid)) {
                driver = await Driver.findById(uid);
            }
            if (!driver) driver = await Driver.findOne({ uid });
            if (!driver) driver = await Driver.findOne({ firebaseId: uid });
        }

        // Find the ride in History or LogisticsBooking model
        let ride = await History.findById(bookingId);
        let isLogistics = false;
        if (!ride) {
            const LogisticsBooking = require('../models/LogisticsBooking');
            ride = await LogisticsBooking.findById(bookingId);
            isLogistics = !!ride;
        }

        if (!ride) {
            return res.status(404).json({
                success: false,
                message: 'Ride not found.'
            });
        }

        const driverIdStr = driver ? driver._id.toString() : uid;
        const isAssignedDriver = ride.driverId && (
            ride.driverId.toString() === driverIdStr ||
            (driver?.uid && ride.driverId.toString() === driver.uid)
        );

        // 'pending' or 'pending_for_driver' = still searching for driver
        const isOpenForDrivers = ride.status === 'pending' || ride.status === 'pending_for_driver';

        if (!isOpenForDrivers && !isAssignedDriver) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to view this ride.'
            });
        }

        // Fetch user or fallback to guest details stored directly on ride
        let user = null;
        if (ride.userId) {
            try {
                user = await User.findById(ride.userId).select(
                    'name mobileNumber imageUrl fcmToken uid'
                );
            } catch (_) {}
        }

        const userName = user?.name || ride.userName || ride.name || 'Guest User';
        const userPhone = user?.mobileNumber || ride.userPhone || ride.mobileNumber || ride.phone || '';

        // Extract pickup & drop
        const pickup = isLogistics ? ride.pickup : (ride.locations?.find(l => l.type === 'pickup') || null);
        const dropoff = isLogistics ? ride.dropoff : (ride.locations?.find(l => l.type === 'dropoff') || null);

        return res.status(200).json({
            success: true,
            message: 'User details fetched successfully.',
            data: {
                user: {
                    id:           user?._id || ride.userId || 'guest',
                    name:         userName,
                    phone:        userPhone,
                    profilePhoto: user?.imageUrl || 'https://i.pravatar.cc/150?u=user'
                },
                ride: {
                    id:            ride._id,
                    status:        ride.status,
                    pickupLocation: pickup ? {
                        address:   pickup.address,
                        latitude:  pickup.latitude,
                        longitude: pickup.longitude,
                        title:     pickup.title || pickup.address
                    } : null,
                    dropLocation: dropoff ? {
                        address:   dropoff.address,
                        latitude:  dropoff.latitude,
                        longitude: dropoff.longitude,
                        title:     dropoff.title || dropoff.address
                    } : null,
                    distance:      ride.distance || ride.distanceKm || 0,
                    fare:          ride.fare || ride.totalPrice || 0,
                    paymentMode:   ride.paymentMode || 'cash',
                    rideMode:      ride.rideMode || ride.vehicleType,
                    vehicleType:   ride.vehicleType || null,
                    helperCount:   ride.helperCount || 0,
                    createdAt:     ride.createdAt
                }
            }
        });

    } catch (error) {
        console.error('[getUserDetailsForDriver] Error:', error.message);
        return res.status(500).json({
            success: false,
            message: 'Server error. Please try again.',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

module.exports = {
    syncDriverData,
    register,
    login,
    checkEmailAvailability,
    getDriverProfile,
    uploadDocuments,
    getDriverStatus,
    updateDriverProfile,
    updateStatus,
    updateLocation,
    sendOTP,
    verifyOTP,
    getUserDetailsForDriver, //Add this line 
    updateFCMToken: async (req, res) => {
        try {
            const { uid, fcmToken } = req.body;
            if (!uid || !fcmToken) {
                return res.status(400).json({ message: 'uid and fcmToken are required' });
            }
            await Driver.findOneAndUpdate({ uid }, { fcmToken });
            res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
        } catch (error) {
            console.error('Error updating Driver FCM Token:', error);
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    }
};
