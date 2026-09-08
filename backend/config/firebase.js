const admin = require('firebase-admin');

// Ensure that newlines in the private key are handled properly
let privateKey = process.env.FIREBASE_PRIVATE_KEY;

if (privateKey) {
    // 1. Remove surrounding whitespace and any quotes
    privateKey = privateKey.trim();
    
    // Handle cases where the key might be wrapped in quotes by the env loader
    if ((privateKey.startsWith('"') && privateKey.endsWith('"')) || 
        (privateKey.startsWith("'") && privateKey.endsWith("'"))) {
        privateKey = privateKey.slice(1, -1);
    }

    // 2. Normalize newlines: handle literal \n sequences
    privateKey = privateKey.split('\\n').join('\n');

    // 3. Remove any stray backslashes that might have been introduced during copying/pasting 
    // (e.g., as line escape characters)
    // ONLY do this if they are not part of legitimate PEM headers/footers
    if (privateKey.includes('-----BEGIN PRIVATE KEY-----')) {
        const parts = privateKey.split('-----');
        if (parts.length >= 5) {
            let content = parts[2].trim();
            // Remove ALL backslashes and whitespace from the base64 content
            content = content.replace(/\\/g, '').replace(/\s+/g, '');
            
            // Re-normalize to standard 64-char lines
            const wrappedContent = content.match(/.{1,64}/g).join('\n');
            privateKey = `-----BEGIN PRIVATE KEY-----\n${wrappedContent}\n-----END PRIVATE KEY-----`;
        }
    }
}

try {
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                privateKey: privateKey,
            }),
            databaseURL: process.env.FIREBASE_DATABASE_URL
        });
        console.log('Firebase Admin initialized successfully');
    }
} catch (error) {
    console.error('Firebase Admin initialization failed:', error.message);
}

module.exports = admin;
