require('dotenv').config();
const connectDB = require('../config/db');
const AdminSignup = require('../models/adminSignup');
const firebaseAdmin = require('../config/firebase');
const bcrypt = require('bcryptjs');

async function seedAdmin() {
    console.log('Connecting to database...');
    await connectDB();

    const adminEmail = 'admin@transglobe.com';
    const adminPassword = 'admin123456';
    const adminName = 'Transglobe Admin';

    // 1. Seed in MongoDB
    try {
        let existingAdmin = await AdminSignup.findOne({ email: adminEmail });
        if (existingAdmin) {
            console.log('Admin already exists in MongoDB, updating password...');
            const salt = await bcrypt.genSalt(10);
            existingAdmin.password = await bcrypt.hash(adminPassword, salt);
            existingAdmin.plainPassword = adminPassword;
            existingAdmin.role = 'superadmin';
            await existingAdmin.save();
        } else {
            console.log('Creating new Admin in MongoDB...');
            const newAdmin = new AdminSignup({
                name: adminName,
                email: adminEmail,
                password: adminPassword,
                role: 'superadmin',
                plainPassword: adminPassword,
                allowedModules: ['dashboard', 'drivers', 'customers', 'rides', 'settings', 'vehicles']
            });
            await newAdmin.save();
        }
        console.log('✅ MongoDB Admin setup completed.');
    } catch (err) {
        console.error('Error setting up MongoDB Admin:', err);
    }

    // 2. Seed in Firebase Auth & Firestore
    try {
        let firebaseUser;
        try {
            firebaseUser = await firebaseAdmin.auth().getUserByEmail(adminEmail);
            console.log('Admin already exists in Firebase Auth, updating password...');
            await firebaseAdmin.auth().updateUser(firebaseUser.uid, {
                password: adminPassword,
                displayName: adminName
            });
        } catch (authErr) {
            if (authErr.code === 'auth/user-not-found') {
                console.log('Creating Admin in Firebase Auth...');
                firebaseUser = await firebaseAdmin.auth().createUser({
                    email: adminEmail,
                    password: adminPassword,
                    displayName: adminName
                });
            } else {
                throw authErr;
            }
        }

        if (firebaseUser) {
            console.log('Updating Admin record in Firestore...');
            await firebaseAdmin.firestore().collection('admin').doc(firebaseUser.uid).set({
                email: adminEmail,
                name: adminName,
                image: '',
                contactNumber: '9999999999',
                isDemo: false
            }, { merge: true });
            console.log('✅ Firebase Admin setup completed.');
        }
    } catch (firebaseErr) {
        console.error('Error setting up Firebase Admin:', firebaseErr.message);
    }

    console.log('\n=============================================');
    console.log('   🎉 ADMIN CREDENTIALS CREATED / UPDATED   ');
    console.log('=============================================');
    console.log(` 📧 Email:    ${adminEmail}`);
    console.log(` 🔑 Password: ${adminPassword}`);
    console.log('=============================================\n');

    process.exit(0);
}

seedAdmin();
