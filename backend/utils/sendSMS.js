const twilio = require("twilio");
require('dotenv').config();

const sendSMS = async (to, message) => {
    try {
        if (!process.env.TWILIO_SID || !process.env.TWILIO_AUTH_TOKEN || !process.env.TWILIO_PHONE) {
            console.warn("Twilio credentials not found. SMS skipped.");
            return;
        }

        let formattedNumber = to;
        if (formattedNumber && !formattedNumber.startsWith('+')) {
            formattedNumber = '+91' + formattedNumber; // Default to India country code
        }

        const client = twilio(
            process.env.TWILIO_SID,
            process.env.TWILIO_AUTH_TOKEN
        );

        await client.messages.create({
            body: message,
            from: process.env.TWILIO_PHONE,
            to: formattedNumber
        });
        console.log("SMS sent successfully to", formattedNumber);
    } catch (error) {
        console.error("Error sending SMS:", error);
    }
};

module.exports = sendSMS;
