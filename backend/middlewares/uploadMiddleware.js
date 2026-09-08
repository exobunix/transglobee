const multer = require('multer');

// Configure multer to store files in memory as buffers
const storage = multer.memoryStorage();
const upload = multer({ storage });

module.exports = upload;
