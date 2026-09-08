const express = require('express');
const router = express.Router();
const https = require('https');

const proxyRequest = (url, res) => {
    https.get(url, (apiRes) => {
        let data = '';
        apiRes.on('data', (chunk) => {
            data += chunk;
        });
        apiRes.on('end', () => {
            try {
                res.status(apiRes.statusCode).json(JSON.parse(data));
            } catch (e) {
                res.status(500).json({ error: 'Failed to parse Google Maps response' });
            }
        });
    }).on('error', (err) => {
        res.status(500).json({ error: err.message });
    });
};

const placesNewRequest = ({ method, path, apiKey, body, fieldMask }) =>
    new Promise((resolve, reject) => {
        const payload = body ? JSON.stringify(body) : null;
        const headers = {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
        };
        if (fieldMask) headers['X-Goog-FieldMask'] = fieldMask;
        if (payload) headers['Content-Length'] = Buffer.byteLength(payload);

        const options = {
            hostname: 'places.googleapis.com',
            path: `/v1/${path}`,
            method,
            headers,
        };

        const req = https.request(options, (apiRes) => {
            let data = '';
            apiRes.on('data', (chunk) => {
                data += chunk;
            });
            apiRes.on('end', () => {
                try {
                    const parsed = JSON.parse(data || '{}');
                    if (apiRes.statusCode >= 400) {
                        const err = new Error(
                            parsed.error?.message ||
                                parsed.message ||
                                `Places API error (${apiRes.statusCode})`
                        );
                        err.details = parsed;
                        err.statusCode = apiRes.statusCode;
                        return reject(err);
                    }
                    resolve(parsed);
                } catch (e) {
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        if (payload) req.write(payload);
        req.end();
    });

const parseCountryCodes = (components) => {
    if (!components) return undefined;
    const match = String(components).match(/country:([a-z]{2})/i);
    return match ? [match[1].toLowerCase()] : undefined;
};

const toLegacyAutocomplete = (data) => {
    const predictions = (data.suggestions || [])
        .filter((s) => s.placePrediction)
        .map((s) => {
            const p = s.placePrediction;
            const description = p.text?.text || '';
            const mainText =
                p.structuredFormat?.mainText?.text ||
                description.split(',')[0] ||
                description;
            return {
                description,
                place_id: p.placeId,
                structured_formatting: {
                    main_text: mainText,
                    secondary_text: p.structuredFormat?.secondaryText?.text || '',
                },
            };
        });

    return { predictions, status: 'OK' };
};

const toLegacyDetails = (data) => ({
    result: {
        geometry: {
            location: {
                lat: data.location?.latitude,
                lng: data.location?.longitude,
            },
        },
        formatted_address: data.formattedAddress || data.displayName?.text || '',
    },
    status: 'OK',
});

// Places API (New) — legacy-shaped response for mobile/web clients
router.get('/autocomplete', async (req, res) => {
    const { input, key, components } = req.query;
    if (!input || !key) return res.status(400).json({ error: 'Missing input or key' });

    const body = { input: String(input) };
    const regionCodes = parseCountryCodes(components);
    if (regionCodes) body.includedRegionCodes = regionCodes;

    try {
        const data = await placesNewRequest({
            method: 'POST',
            path: 'places:autocomplete',
            apiKey: key,
            body,
            fieldMask:
                'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
        });
        return res.status(200).json(toLegacyAutocomplete(data));
    } catch (err) {
        return res.status(200).json({
            predictions: [],
            status: 'REQUEST_DENIED',
            error_message: err.message,
        });
    }
});

router.get('/details', async (req, res) => {
    const { place_id, key } = req.query;
    if (!place_id || !key) return res.status(400).json({ error: 'Missing place_id or key' });

    const placeId = String(place_id).replace(/^places\//, '');

    try {
        const data = await placesNewRequest({
            method: 'GET',
            path: `places/${encodeURIComponent(placeId)}`,
            apiKey: key,
            fieldMask: 'location,formattedAddress,displayName',
        });
        return res.status(200).json(toLegacyDetails(data));
    } catch (err) {
        return res.status(200).json({
            status: 'REQUEST_DENIED',
            error_message: err.message,
        });
    }
});

router.get('/geocode', (req, res) => {
    const { latlng, address, key } = req.query;
    if (!key) return res.status(400).json({ error: 'Missing key' });
    if (!latlng && !address) return res.status(400).json({ error: 'Missing latlng or address' });

    let url;
    if (address) {
        url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${key}`;
    } else {
        url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latlng}&key=${key}`;
    }
    proxyRequest(url, res);
});

router.get('/directions', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) {
        return res.status(400).json({ error: 'Missing origin, destination, or key' });
    }

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&key=${key}`;
    proxyRequest(url, res);
});

router.get('/eta', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) {
        return res.status(400).json({ error: 'Missing origin, destination, or key' });
    }

    const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${encodeURIComponent(origin)}&destinations=${encodeURIComponent(destination)}&mode=driving&language=en&key=${key}`;

    https.get(url, (apiRes) => {
        let data = '';
        apiRes.on('data', (chunk) => {
            data += chunk;
        });
        apiRes.on('end', () => {
            try {
                const parsed = JSON.parse(data);
                const element = parsed?.rows?.[0]?.elements?.[0];
                if (!element || element.status !== 'OK') {
                    return res.status(404).json({ error: 'Could not calculate ETA', raw: parsed });
                }
                res.status(200).json({
                    success: true,
                    data: {
                        distanceText: element.distance.text,
                        distanceMeters: element.distance.value,
                        durationText: element.duration.text,
                        durationSeconds: element.duration.value,
                        eta: new Date(Date.now() + element.duration.value * 1000).toISOString(),
                    },
                });
            } catch (e) {
                res.status(500).json({ error: 'Failed to parse ETA response' });
            }
        });
    }).on('error', (err) => res.status(500).json({ error: err.message }));
});

router.get('/route-optimize', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) {
        return res.status(400).json({ error: 'Missing origin, destination, or key' });
    }

    let url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&optimize:true&key=${key}`;
    const { waypoints } = req.query;
    if (waypoints) url += `&waypoints=optimize:true|${encodeURIComponent(waypoints)}`;

    proxyRequest(url, res);
});

router.get('/pincode/:pin', (req, res) => {
    const { pin } = req.params;
    const url = `https://api.postalpincode.in/pincode/${pin}`;
    proxyRequest(url, res);
});

const ratingController = require('../controllers/ratingController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/ratings', verifyToken, ratingController.submitRating);
router.get('/ratings/booking/:bookingId', ratingController.getBookingRatings);
router.get('/ratings/driver/:driverId', ratingController.getDriverRatings);
router.get('/ratings/user/:userId', ratingController.getUserRatings);

module.exports = router;
