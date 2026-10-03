const mongoose = require('mongoose');
const fs = require('fs');
const User = require('../models/User');
require('dotenv').config();
const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);

async function run() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        const allUsers = await User.find().lean();
        fs.writeFileSync('./scripts/users_backup.json', JSON.stringify(allUsers, null, 2));
        console.log('Backed up', allUsers.length, 'users to ./scripts/users_backup.json');

        const keepIds = [
            new mongoose.Types.ObjectId('6a8976b36acafc76988d9e16'),
            new mongoose.Types.ObjectId('6a44dd65afc692bb77e4ebeb')
        ];

        const res = await User.deleteMany({ _id: { $nin: keepIds } });
        console.log('Deleted users count:', res.deletedCount);

        const remaining = await User.find({}, 'name email mobileNumber plainPassword role status').lean();
        console.log('Remaining users in DB:', JSON.stringify(remaining, null, 2));

        process.exit(0);
    } catch (err) {
        console.error('Error pruning users:', err);
        process.exit(1);
    }
}

run();
