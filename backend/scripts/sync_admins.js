const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const AdminSignup = require('../models/adminSignup');
require('dotenv').config();

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  const hash = await bcrypt.hash('Transglobe@9967', 10);

  // Permanent admin: trasnglobeadmin@gmail.com and transglobeadmin@gmail.com
  await AdminSignup.updateMany(
    { email: { $in: ['trasnglobeadmin@gmail.com', 'transglobeadmin@gmail.com'] } },
    { $set: { password: hash, plainPassword: 'Transglobe@9967', isPermanentAdmin: true, name: 'Transglobe SuperAdmin' } }
  );

  // Active working admin: admin@transglobe.com
  await AdminSignup.updateMany(
    { email: 'admin@transglobe.com' },
    { $set: { password: hash, plainPassword: 'Transglobe@9967', isPermanentAdmin: false, name: 'Transglobe Admin' } }
  );

  const updated = await AdminSignup.find({ email: { $in: ['trasnglobeadmin@gmail.com', 'transglobeadmin@gmail.com', 'admin@transglobe.com'] } });
  console.log('Updated accounts:');
  updated.forEach(u => console.log({ email: u.email, isPermanentAdmin: u.isPermanentAdmin, plainPassword: u.plainPassword }));
  process.exit(0);
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
