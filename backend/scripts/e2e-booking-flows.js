#!/usr/bin/env node

/**
 * Booking flow verifier for TRSNGLOBE.
 *
 * Validates end-to-end API behavior for:
 * 1) Car booking
 * 2) Shuttle booking
 * 3) Logistics booking + lifecycle transitions
 *
 * Usage:
 *   BASE_URL=http://localhost:8080 node scripts/e2e-booking-flows.js
 * Optional:
 *   E2E_TOKEN=dev-token-bypass
 *   E2E_UID=e2e-user-uid
 *   E2E_EMAIL=e2e-user@dev.local
 */

const assert = require('node:assert/strict');

const baseUrl = (process.env.BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const apiBase = (process.env.API_BASE || `${baseUrl}/api`).replace(/\/$/, '');
const token = process.env.E2E_TOKEN || process.env.AUTH_TOKEN || 'dev-token-bypass';
const e2eUid = process.env.E2E_UID || 'e2e-user-uid';
const e2eEmail = process.env.E2E_EMAIL || `${e2eUid}@dev.local`;
const e2ePhone = process.env.E2E_PHONE || '9999999999';

function logStep(message) {
    console.log(`[E2E] ${message}`);
}

function buildAuthHeaders() {
    return {
        Authorization: `Bearer ${token}`,
        'X-Dev-Uid': e2eUid,
        'X-Dev-Email': e2eEmail,
        'X-Dev-Role': 'user',
        'Content-Type': 'application/json',
    };
}

async function requestJson(method, path, body = undefined, headers = {}) {
    const response = await fetch(`${apiBase}${path}`, {
        method,
        headers: {
            'Content-Type': 'application/json',
            ...headers,
        },
        body: body ? JSON.stringify(body) : undefined,
    });

    const text = await response.text();
    let parsed = {};
    try {
        parsed = text ? JSON.parse(text) : {};
    } catch {
        parsed = { raw: text };
    }

    if (!response.ok) {
        throw new Error(
            `Request failed: ${method} ${path} -> HTTP ${response.status}\n${JSON.stringify(parsed, null, 2)}`
        );
    }

    return parsed;
}

async function createRideFlow(rideMode, fare) {
    const ridePayload = {
        mobileNumber: e2ePhone,
        locations: {
            pickup: {
                title: 'Noida Sector 62',
                address: 'Noida Sector 62, Uttar Pradesh',
                latitude: 28.6289,
                longitude: 77.3723,
            },
            dropoff: {
                title: 'Connaught Place',
                address: 'Connaught Place, New Delhi',
                latitude: 28.6315,
                longitude: 77.2167,
            },
        },
        rideMode,
        paymentMode: 'cash',
        fare,
        distance: '28.5',
        vehicleType: rideMode === 'shuttle' ? 'Mini Shuttle' : 'Sedan',
    };

    logStep(`Creating ${rideMode.toUpperCase()} booking...`);
    const createRes = await requestJson(
        'POST',
        '/ride/ride-request',
        ridePayload,
        buildAuthHeaders()
    );

    assert.equal(createRes.success, true, `${rideMode} booking creation should succeed`);
    const rideId = createRes?.data?._id;
    assert.ok(rideId, `${rideMode} booking ID should exist`);

    logStep(`Updating ${rideMode.toUpperCase()} booking status to accepted...`);
    const acceptedRes = await requestJson(
        'PUT',
        `/ride/rides/${rideId}/status`,
        { status: 'accepted' },
        buildAuthHeaders()
    );
    assert.equal(acceptedRes.success, true, `${rideMode} accept status should succeed`);

    logStep(`Updating ${rideMode.toUpperCase()} booking status to ongoing...`);
    const ongoingRes = await requestJson(
        'PUT',
        `/ride/rides/${rideId}/status`,
        { status: 'ongoing' },
        buildAuthHeaders()
    );
    assert.equal(ongoingRes.success, true, `${rideMode} ongoing status should succeed`);

    logStep(`Updating ${rideMode.toUpperCase()} booking status to completed...`);
    const completedRes = await requestJson(
        'PUT',
        `/ride/rides/${rideId}/status`,
        { status: 'completed' },
        buildAuthHeaders()
    );
    assert.equal(completedRes.success, true, `${rideMode} completed status should succeed`);

    return rideId;
}

async function createLogisticsFlow() {
    const logisticsPayload = {
        userId: e2eUid,
        userName: 'E2E Logistics User',
        userPhone: e2ePhone,
        pickup: {
            name: 'Noida Warehouse',
            address: 'Sector 63, Noida',
            lat: 28.6217,
            lng: 77.3812,
        },
        dropoff: {
            name: 'Mumbai Hub',
            address: 'Andheri East, Mumbai',
            lat: 19.1136,
            lng: 72.8697,
        },
        distanceKm: 1400,
        vehicleType: 'road',
        vehiclePrice: 18000,
        items: [
            {
                itemName: 'Sofa',
                type: 'Furniture',
                length: 200,
                width: 90,
                height: 110,
                unit: 'cm',
                weight: 80,
                quantity: 1,
            },
        ],
        helperCount: 2,
        helperCost: 1200,
        additionalCharges: 500,
        discountAmount: 0,
        totalPrice: 19700,
        pickupAddress: {
            label: 'Noida Warehouse',
            fullAddress: 'Sector 63, Noida, Uttar Pradesh',
            city: 'Noida',
            pincode: '201301',
            phone: e2ePhone,
            email: e2eEmail,
        },
        receivedAddress: {
            label: 'Mumbai Hub',
            fullAddress: 'Andheri East, Mumbai, Maharashtra',
            city: 'Mumbai',
            pincode: '400059',
            phone: e2ePhone,
            email: e2eEmail,
        },
    };

    logStep('Creating LOGISTICS booking...');
    const createRes = await requestJson('POST', '/logistics-bookings', logisticsPayload);
    assert.equal(createRes.success, true, 'Logistics booking creation should succeed');
    const bookingId = createRes?.bookingId || createRes?.data?._id;
    assert.ok(bookingId, 'Logistics booking ID should exist');

    const transitions = ['confirmed', 'in_transit', 'delivered'];
    for (const status of transitions) {
        logStep(`Updating LOGISTICS booking status to ${status}...`);
        const statusRes = await requestJson(
            'PATCH',
            `/logistics-bookings/${bookingId}/status`,
            { status }
        );
        assert.equal(statusRes.success, true, `Logistics status ${status} should succeed`);
    }

    logStep('Fetching LOGISTICS booking to verify final state...');
    const getRes = await requestJson('GET', `/logistics-bookings/${bookingId}`);
    assert.equal(getRes.success, true, 'Fetch logistics booking should succeed');
    assert.equal(getRes?.data?.status, 'delivered', 'Logistics booking should be delivered');

    return bookingId;
}

async function main() {
    logStep(`Running booking flow verification against ${apiBase}`);

    const carRideId = await createRideFlow('car', 620);
    const shuttleRideId = await createRideFlow('shuttle', 380);
    const logisticsId = await createLogisticsFlow();

    logStep('All booking flows passed.');
    console.log(
        JSON.stringify(
            {
                success: true,
                apiBase,
                flows: {
                    carRideId,
                    shuttleRideId,
                    logisticsId,
                },
            },
            null,
            2
        )
    );
}

main().catch((error) => {
    console.error('[E2E] Booking flow verification failed.');
    console.error(error.message);
    process.exit(1);
});
