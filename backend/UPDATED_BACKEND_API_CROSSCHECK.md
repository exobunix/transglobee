# Transglobe Backend API Cross-check

Date: 2026-05-08
Source review:
- PRD: `download.pdf`
- Claude pending API PDF: `transglobe pending api.pdf`
- API handover: `Transglobes_Backend_API_Documentation.docx`
- Backend code: `backend/routes`, `backend/controllers`, `backend/models`

Note: `transglobe pending api.pdf` appears to be image/scanned pages. Text extraction only returned page markers, so this cross-check uses the PRD, DOCX handover, Markdown guide, and live backend code.

## Implemented and Verified Routes

### Auth and User

| Method | Endpoint | Status |
| --- | --- | --- |
| POST | `/api/auth/send-otp` | Implemented |
| POST | `/api/auth/verify-otp` | Implemented as same handler as send/register phone |
| POST | `/api/auth/refresh` | Stub response |
| POST | `/api/auth/logout` | Stub response |
| GET | `/api/auth/profile` | Implemented |
| PUT | `/api/auth/profile` | Implemented |
| GET | `/api/user/profile` | Implemented |
| PUT | `/api/user/profile` | Implemented |
| POST | `/api/user/fcm-token` | Implemented |

### Rides

| Method | Endpoint | Status |
| --- | --- | --- |
| GET | `/api/rides/vehicles` | Implemented |
| GET | `/api/rides/ride-types` | Implemented |
| POST | `/api/rides/book` | Implemented |
| GET | `/api/rides/history` | Implemented |
| GET | `/api/rides/:rideId` | Implemented |
| POST | `/api/rides/:rideId/cancel` | Implemented |
| PUT | `/api/rides/:rideId/modify` | Implemented |
| GET | `/api/rides/:rideId/track` | Implemented |
| POST | `/api/rides/:rideId/rate` | Implemented |
| PUT | `/api/rides/rides/:rideId/assign` | Implemented |
| PUT | `/api/rides/rides/:rideId/status` | Implemented |
| PUT | `/api/rides/rides/:rideId/verify-otp` | Implemented |

Gap: PRD route `/api/rides/estimate` is not implemented as a dedicated endpoint. Pricing calculation exists under admin pricing APIs.

### Logistics

| Method | Endpoint | Status |
| --- | --- | --- |
| POST | `/api/logistics/estimate` | Implemented |
| POST | `/api/logistics/book` | Implemented |
| GET | `/api/logistics/history` | Implemented |
| GET | `/api/logistics/goods-types` | Implemented |
| GET | `/api/logistics/:id` | Implemented |
| GET | `/api/logistics/:id/track` | Implemented |
| POST | `/api/logistics/:id/cancel` | Implemented |
| POST | `/api/logistics/:id/accept-roadmap` | Implemented |
| GET | `/api/logistics-bookings` | Implemented |
| GET | `/api/logistics-bookings/:id` | Implemented |
| PATCH | `/api/logistics-bookings/:id/status` | Implemented |
| POST | `/api/logistics-bookings/:id/assign` | Implemented |
| PATCH | `/api/logistics-bookings/:id/roadmap` | Implemented |
| POST | `/api/logistics-bookings/:id/segment/:segmentId/assign` | Implemented |

### Driver

| Method | Endpoint | Status |
| --- | --- | --- |
| POST | `/api/driver/register` | Implemented |
| POST | `/api/driver/login` | Implemented |
| GET | `/api/driver/profile` | Implemented |
| PUT | `/api/driver/profile/update` | Implemented |
| POST | `/api/driver/upload` | Implemented |
| PUT | `/api/driver/status` | Implemented |
| PUT | `/api/driver/location` | Implemented |
| GET | `/api/driver/pending-bookings` | Implemented |
| GET | `/api/driver/earnings` | Added |
| GET | `/api/driver/earnings/history` | Added |
| GET | `/api/driver/wallet` | Added from pending API PDF |
| POST | `/api/driver/payout` | Added from pending API PDF |

Gap: PRD job aliases such as `/api/driver/jobs/:id/accept` are not exposed. Existing accept/reject paths are `/api/booking/:id/accept` and `/api/booking/:id/reject`.

### Corporate

| Method | Endpoint | Status |
| --- | --- | --- |
| POST | `/api/corporate/login` | Implemented |
| POST | `/api/corporate/google-sync` | Implemented |
| GET | `/api/corporate/profile` | Implemented |
| GET | `/api/corporate/bookings` | Implemented |
| POST | `/api/corporate/bookings/bulk` | Added |
| POST | `/api/corporate/bulk-bookings` | Added |
| GET | `/api/corporate/credit` | Added |
| PUT | `/api/corporate/credit` | Added |
| PUT | `/api/corporate/:id/credit` | Added |
| GET | `/api/corporate/bulk-bookings/template` | Added from pending API PDF |
| GET | `/api/corporate/invoice/:bookingId` | Added PDF invoice generation |
| GET | `/api/corporate/credit-status` | Added from pending API PDF |
| GET | `/api/corporate/dashboard` | Added from pending API PDF |

Bulk booking accepts either:
- JSON: `{ "bookings": [...] }`
- Multipart CSV file field named `file`
- Raw CSV string in body field `csv`

### Payments

| Method | Endpoint | Status |
| --- | --- | --- |
| POST | `/api/payments/create-order` | Implemented |
| POST | `/api/payments/initiate` | Added PRD alias |
| POST | `/api/payments/verify` | Implemented |
| POST | `/api/payments/callback` | Added |
| POST | `/api/payments/webhook` | Added alias |
| POST | `/api/payments/refund` | Added |
| GET | `/api/payments/wallet/balance` | Implemented/fixed |
| POST | `/api/payments/wallet/topup` | Added PRD alias |
| POST | `/api/payments/wallet/add` | Existing alias |
| POST | `/api/payments/wallet/deduct` | Implemented/fixed |
| GET | `/api/payments/wallet/history` | Added |
| GET | `/api/payments/driver/earnings/:driverId` | Implemented/fixed |
| GET | `/api/payments/invoice/:bookingId` | Implemented/fixed |

Code fixes:
- Added missing `razorpay` dependency.
- Added `walletBalance` to users.
- Added `metadata` to transactions so gateway ids, refunds, and wallet operations persist.
- Hardened wallet lookup for Firebase UID, Mongo ObjectId, email, or phone.
- Added refund recording and optional Razorpay refund call when payment id and keys are present.

### Admin and Supervisor

| Endpoint Area | Status |
| --- | --- |
| User, driver, vehicle, booking, complaints, reviews, CMS | Implemented under `/api/admin` |
| Analytics dashboard, revenue, driver performance, delay logs | Implemented under `/api/admin/analytics/*` |
| Pricing configs and fare calculation | Implemented under `/api/admin/pricing*` |
| Supervisor goods edit, pricing override, approval, stats | Implemented under `/api/admin/supervisor/*` |
| Dynamic pricing rules | Added under `/api/admin/pricing-rules` |
| Live analytics alias | Added `/api/admin/analytics/live` |
| Admin dashboard alias | Added `/api/admin/dashboard` |
| Broadcast notifications | Added `/api/admin/notifications/broadcast` |
| Corporate admin management | Added `/api/admin/corporate`, `/api/admin/corporate/:corpId` |
| Supervisor PRD namespace | Added `/api/supervisor/*` route namespace |

### Shuttle

| Method | Endpoint | Status |
| --- | --- | --- |
| GET | `/api/shuttle/routes` | Added from pending API PDF |
| GET | `/api/shuttle/routes/:routeId/schedule` | Added from pending API PDF |
| POST | `/api/shuttle/book` | Added from pending API PDF |
| GET | `/api/shuttle/history` | Added from pending API PDF |
| GET | `/api/shuttle/:bookingId` | Added from pending API PDF |
| POST | `/api/shuttle/:bookingId/cancel` | Added from pending API PDF |
| GET | `/api/shuttle/:bookingId/track` | Added from pending API PDF |

### Notifications and Sessions

| Method | Endpoint | Status |
| --- | --- | --- |
| GET | `/api/notifications` | Added from pending API PDF |
| POST | `/api/notifications/read` | Added from pending API PDF |
| POST | `/api/auth/logout` | Updated to blacklist current token in memory |
| POST | `/api/admin/notifications/broadcast` | Added from pending API PDF |

Gap: PRD names `/api/supervisor/*`, `/api/admin/dashboard`, `/api/admin/notifications/broadcast`, `/api/admin/reports/:type`, and full admin corporate management are not exposed as exact routes.

## Remaining PRD Gaps

1. Address book CRUD: only `POST /api/user/location` exists; full `/api/addresses` CRUD is pending.
2. Support tickets: no `/api/support/tickets` module exists.
3. Exact driver job namespace: accept/reject is implemented for logistics bookings, but not under `/api/driver/jobs/*`.
4. Session blacklist is in memory for local executability. Production should replace it with Redis.
5. Payment webhook signature verification uses JSON body. For production Razorpay webhooks, mount a raw-body parser on the webhook route.

## Environment Needed To Run

Required:
- `MONGODB_URI`
- `JWT_SECRET`
- Firebase service account values used by `config/firebase.js`

For payments:
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET` for webhook signature validation

Recommended:
- `COMPANY_GST`
- `COMPANY_ADDRESS`
- `GST_RATE`
- `DRIVER_COMMISSION_RATE`
