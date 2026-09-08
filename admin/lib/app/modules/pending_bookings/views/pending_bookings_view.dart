// // ignore_for_file: deprecated_member_use
// import 'package:admin/app/models/booking_model.dart';
// import 'package:admin/app/modules/pending_bookings/controllers/pending_bookings_controller.dart';
// import 'package:admin/app/utils/app_colors.dart';
// import 'package:admin/app/utils/app_them_data.dart';
// import 'package:admin/app/utils/dark_theme_provider.dart';
// import 'package:admin/widget/text_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';

// class PendingBookingsView extends StatelessWidget {
//   const PendingBookingsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return GetBuilder<PendingBookingsController>(
//       init: PendingBookingsController(),
//       builder: (controller) {
//         final isDark = themeChange.isDarkTheme();
//         return Scaffold(
//           backgroundColor:
//               isDark ? AppThemData.greyShade950 : AppThemData.greyShade50,
//           body: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Header ──────────────────────────────────────────────────
//               Container(
//                 color: isDark
//                     ? AppThemData.greyShade900
//                     : AppThemData.primaryWhite,
//                 padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         TextCustom(
//                           title: 'Pending Bookings'.tr,
//                           fontSize: 22,
//                           fontFamily: AppThemeData.bold,
//                         ),
//                         // Refresh button
//                         Obx(() => controller.isActionLoading.value
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(
//                                     strokeWidth: 2),
//                               )
//                             : IconButton(
//                                 tooltip: 'Refresh',
//                                 icon: Icon(
//                                   Icons.refresh_rounded,
//                                   color: AppThemData.primary500,
//                                 ),
//                                 onPressed: controller.refreshCurrent,
//                               )),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // ── Tab Bar ─────────────────────────────────────────
//                     TabBar(
//                       controller: controller.tabController,
//                       labelColor: AppThemData.primary500,
//                       unselectedLabelColor: Colors.grey,
//                       indicatorColor: AppThemData.primary500,
//                       indicatorWeight: 3,
//                       labelStyle: const TextStyle(
//                           fontWeight: FontWeight.w700, fontSize: 14),
//                       unselectedLabelStyle:
//                           const TextStyle(fontSize: 14),
//                       tabs: [
//                         Obx(() => Tab(
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Icon(Icons.directions_bus_rounded,
//                                       size: 18),
//                                   const SizedBox(width: 6),
//                                   const Text('Shuttle'),
//                                   const SizedBox(width: 6),
//                                   _CountBadge(
//                                       count: controller
//                                           .shuttleBookings.length,
//                                       isDark: isDark),
//                                 ],
//                               ),
//                             )),
//                         Obx(() => Tab(
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Icon(Icons.local_shipping_rounded,
//                                       size: 18),
//                                   const SizedBox(width: 6),
//                                   const Text('Logistics'),
//                                   const SizedBox(width: 6),
//                                   _CountBadge(
//                                       count: controller
//                                           .logisticsBookings.length,
//                                       isDark: isDark),
//                                 ],
//                               ),
//                             )),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // ── Tab Content ──────────────────────────────────────────────
//               Expanded(
//                 child: TabBarView(
//                   controller: controller.tabController,
//                   children: [
//                     // Tab 1: Shuttle
//                     Obx(() => controller.isLoadingShuttle.value
//                         ? const Center(child: CircularProgressIndicator())
//                         : controller.shuttleBookings.isEmpty
//                             ? _EmptyState(
//                                 icon: Icons.directions_bus_outlined,
//                                 message: 'No pending shuttle bookings',
//                                 isDark: isDark,
//                               )
//                             : _BookingList(
//                                 bookings: controller.shuttleBookings,
//                                 isDark: isDark,
//                                 controller: controller,
//                                 context: context,
//                               )),

//                     // Tab 2: Logistics
//                     Obx(() => controller.isLoadingLogistics.value
//                         ? const Center(child: CircularProgressIndicator())
//                         : controller.logisticsBookings.isEmpty
//                             ? _EmptyState(
//                                 icon: Icons.local_shipping_outlined,
//                                 message: 'No pending logistics bookings',
//                                 isDark: isDark,
//                               )
//                             : _BookingList(
//                                 bookings: controller.logisticsBookings,
//                                 isDark: isDark,
//                                 controller: controller,
//                                 context: context,
//                               )),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // ─── Count Badge ────────────────────────────────────────────────────────────

// class _CountBadge extends StatelessWidget {
//   final int count;
//   final bool isDark;
//   const _CountBadge({required this.count, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     if (count == 0) return const SizedBox.shrink();
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//       decoration: BoxDecoration(
//         color: Colors.red.shade600.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         '$count',
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: Colors.red.shade600,
//         ),
//       ),
//     );
//   }
// }

// // ─── Booking List ────────────────────────────────────────────────────────────

// class _BookingList extends StatelessWidget {
//   final List<BookingModel> bookings;
//   final bool isDark;
//   final PendingBookingsController controller;
//   final BuildContext context;

//   const _BookingList({
//     required this.bookings,
//     required this.isDark,
//     required this.controller,
//     required this.context,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(20),
//       itemCount: bookings.length,
//       itemBuilder: (ctx, i) =>
//           _BookingCard(booking: bookings[i], isDark: isDark, controller: controller),
//     );
//   }
// }

// // ─── Booking Card ────────────────────────────────────────────────────────────

// class _BookingCard extends StatelessWidget {
//   final BookingModel booking;
//   final bool isDark;
//   final PendingBookingsController controller;

//   const _BookingCard({
//     required this.booking,
//     required this.isDark,
//     required this.controller,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final customerName = (booking.customerName ?? 'N/A').toUpperCase();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 20),
//       decoration: BoxDecoration(
//         color: isDark ? AppThemData.greyShade900 : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isDark ? AppThemData.greyShade800 : Colors.grey.shade200,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Name and Status Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 customerName,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: isDark ? Colors.white : Colors.black87,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xffFFF3E0),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   controller.statusLabel(booking.bookingStatus).toUpperCase(),
//                   style: const TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w800,
//                     color: Color(0xffE65100),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Pickup Address Row
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Icon(
//                 Icons.location_on,
//                 color: Colors.green,
//                 size: 18,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   booking.pickUpLocationAddress ?? 'Pickup N/A',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: isDark ? Colors.white70 : Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Dropoff Address Row
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Icon(
//                 Icons.flag,
//                 color: Colors.red,
//                 size: 18,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   booking.dropLocationAddress ?? 'Drop N/A',
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: isDark ? Colors.white70 : Colors.grey.shade600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Manage Booking Button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xff0D6EFD), // beautiful blue
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 elevation: 0,
//               ),
//               icon: const Icon(Icons.assignment_outlined, size: 18),
//               label: const Text(
//                 'MANAGE BOOKING',
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//               onPressed: () => _showManageOptionsDialog(context, booking, isDark),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showManageOptionsDialog(BuildContext context, BookingModel booking, bool isDark) {
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor: isDark ? AppThemData.greyShade900 : Colors.white,
//         child: Container(
//           width: 360,
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Manage Booking',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(ctx),
//                   ),
//                 ],
//               ),
//               const Divider(),
//               const SizedBox(height: 10),
              
//               // Option 1: Accept
//               _DialogOption(
//                 icon: Icons.check_circle_outline,
//                 label: 'Accept Booking',
//                 color: Colors.green,
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   _showAcceptConfirm(context, booking);
//                 },
//               ),
//               const SizedBox(height: 8),

//               // Option 2: Assign Driver
//               _DialogOption(
//                 icon: Icons.person_pin_circle_outlined,
//                 label: 'Assign Driver',
//                 color: Colors.purple,
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   _showAssignDriverDialog(context, booking, isDark);
//                 },
//               ),
//               const SizedBox(height: 8),

//               // Option 3: Override Price / View Details
//               _DialogOption(
//                 icon: Icons.info_outline,
//                 label: 'View Details & Override Price',
//                 color: Colors.blue,
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   _showDetailDialog(context, booking, isDark);
//                 },
//               ),
//               const SizedBox(height: 8),

//               // Option 4: Reject
//               _DialogOption(
//                 icon: Icons.cancel_outlined,
//                 label: 'Reject Booking',
//                 color: Colors.red,
//                 onTap: () {
//                   Navigator.pop(ctx);
//                   _showRejectDialog(context, booking, isDark);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Detail Dialog ──────────────────────────────────────────────────────────

//   void _showDetailDialog(
//       BuildContext context, BookingModel booking, bool isDark) {
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor:
//             isDark ? AppThemData.greyShade900 : Colors.white,
//         child: Container(
//           width: 520,
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Booking Details',
//                     style: TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.w800),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(ctx),
//                   ),
//                 ],
//               ),
//               const Divider(),
//               const SizedBox(height: 8),
//               _DetailRow(label: 'Booking ID',
//                   value: booking.id ?? 'N/A', isDark: isDark),
//               _DetailRow(label: 'Customer',
//                   value: booking.customerName ?? 'N/A', isDark: isDark),
//               _DetailRow(label: 'Customer ID',
//                   value: booking.customerId ?? 'N/A', isDark: isDark),
//               _DetailRow(label: 'Pickup',
//                   value: booking.pickUpLocationAddress ?? 'N/A',
//                   isDark: isDark),
//               _DetailRow(label: 'Drop',
//                   value: booking.dropLocationAddress ?? 'N/A',
//                   isDark: isDark),
//               _DetailRow(label: 'Distance',
//                   value:
//                       '${booking.distance?.distance ?? 0} km',
//                   isDark: isDark),
//               _DetailRow(label: 'Total Price',
//                   value: '₹${booking.subTotal ?? 0}', isDark: isDark),
//               _DetailRow(label: 'Payment',
//                   value: booking.paymentType ?? 'N/A', isDark: isDark),
//               _DetailRow(label: 'Status',
//                   value: controller.statusLabel(booking.bookingStatus),
//                   isDark: isDark),
//               if (booking.driverId != null &&
//                   booking.driverId!.isNotEmpty)
//                 _DetailRow(label: 'Driver ID',
//                     value: booking.driverId!, isDark: isDark),
//               const SizedBox(height: 16),
//               // Price Override section
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: AppThemData.primary500.withOpacity(0.06),
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                       color: AppThemData.primary500.withOpacity(0.2)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Override Price',
//                         style: TextStyle(
//                             fontWeight: FontWeight.w700, fontSize: 13)),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: controller.priceController
//                               ..text = booking.subTotal ?? '',
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               hintText: 'Enter new price',
//                               prefixText: '₹ ',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               contentPadding:
//                                   const EdgeInsets.symmetric(
//                                       horizontal: 12, vertical: 10),
//                               isDense: true,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppThemData.primary500,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 12),
//                           ),
//                           onPressed: () {
//                             final newPrice =
//                                 controller.priceController.text.trim();
//                             if (newPrice.isNotEmpty) {
//                               Navigator.pop(ctx);
//                               controller.overridePrice(booking, newPrice);
//                             }
//                           },
//                           child: const Text('Update',
//                               style: TextStyle(color: Colors.white)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Accept Confirm Dialog ──────────────────────────────────────────────────

//   void _showAcceptConfirm(BuildContext context, BookingModel booking) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Accept Booking'),
//         content: const Text(
//             'Are you sure you want to accept this booking?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8)),
//             ),
//             onPressed: () {
//               Navigator.pop(ctx);
//               controller.acceptBooking(booking);
//             },
//             child: const Text('Accept',
//                 style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Reject Dialog ──────────────────────────────────────────────────────────

//   void _showRejectDialog(
//       BuildContext context, BookingModel booking, bool isDark) {
//     controller.rejectReasonController.clear();
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor:
//             isDark ? AppThemData.greyShade900 : Colors.white,
//         child: Container(
//           width: 420,
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Reject Booking',
//                   style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.w800)),
//               const SizedBox(height: 4),
//               Text(
//                 'Please provide a reason for rejection.',
//                 style:
//                     TextStyle(fontSize: 13, color: Colors.grey.shade500),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: controller.rejectReasonController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: 'e.g. No driver available in this area',
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                   contentPadding: const EdgeInsets.all(12),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(ctx),
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                     ),
//                     onPressed: () {
//                       final reason = controller
//                           .rejectReasonController.text
//                           .trim();
//                       Navigator.pop(ctx);
//                       controller.rejectBooking(booking, reason);
//                     },
//                     child: const Text('Reject',
//                         style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Assign Driver Dialog ───────────────────────────────────────────────────

//   void _showAssignDriverDialog(
//       BuildContext context, BookingModel booking, bool isDark) {
//     controller.fetchAvailableDrivers();
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         backgroundColor:
//             isDark ? AppThemData.greyShade900 : Colors.white,
//         child: Container(
//           width: 460,
//           constraints: BoxConstraints(
//               maxHeight: MediaQuery.of(context).size.height * 0.7),
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text('Assign Driver',
//                       style: TextStyle(
//                           fontSize: 18, fontWeight: FontWeight.w800)),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(ctx),
//                   ),
//                 ],
//               ),
//               const Divider(),
//               Obx(() {
//                 if (controller.isLoadingDrivers.value) {
//                   return const Padding(
//                     padding: EdgeInsets.all(24),
//                     child: Center(child: CircularProgressIndicator()),
//                   );
//                 }
//                 if (controller.availableDrivers.isEmpty) {
//                   return Padding(
//                     padding: const EdgeInsets.all(24),
//                     child: Center(
//                       child: Column(
//                         children: [
//                           Icon(Icons.person_off_outlined,
//                               size: 48,
//                               color: Colors.grey.shade400),
//                           const SizedBox(height: 8),
//                           Text('No drivers available',
//                               style: TextStyle(
//                                   color: Colors.grey.shade500)),
//                         ],
//                       ),
//                     ),
//                   );
//                 }
//                 return Flexible(
//                   child: ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: controller.availableDrivers.length,
//                     itemBuilder: (_, i) {
//                       final driver = controller.availableDrivers[i];
//                       final dId = driver['_id']?.toString() ??
//                           driver['id']?.toString() ??
//                           '';
//                       final dName =
//                           driver['fullName']?.toString() ??
//                               driver['name']?.toString() ??
//                               'Driver';
//                       final dPhone =
//                           driver['phoneNumber']?.toString() ?? '';
//                       return ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         leading: CircleAvatar(
//                           backgroundColor:
//                               AppThemData.primary500.withOpacity(0.12),
//                           child: Text(
//                             dName.isNotEmpty
//                                 ? dName[0].toUpperCase()
//                                 : 'D',
//                             style: TextStyle(
//                                 color: AppThemData.primary500,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         title: Text(dName,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 14)),
//                         subtitle: dPhone.isNotEmpty
//                             ? Text(dPhone,
//                                 style: const TextStyle(fontSize: 12))
//                             : null,
//                         trailing: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppThemData.primary500,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8)),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 14, vertical: 8),
//                           ),
//                           onPressed: () {
//                             Navigator.pop(ctx);
//                             controller.assignDriver(
//                                 booking, dId, dName);
//                           },
//                           child: const Text('Assign',
//                               style: TextStyle(
//                                   color: Colors.white, fontSize: 13)),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               }),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─── Status Chip ────────────────────────────────────────────────────────────

// class _StatusChip extends StatelessWidget {
//   final String status;
//   const _StatusChip({required this.status});

//   Color get _color {
//     switch (status) {
//       case 'PENDING':
//         return Colors.orange;
//       case 'ACCEPTED':
//         return Colors.green;
//       case 'REJECTED':
//         return Colors.red;
//       case 'COMPLETED':
//         return Colors.blue;
//       case 'CANCELLED':
//         return Colors.grey;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: _color.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: _color,
//         ),
//       ),
//     );
//   }
// }

// // ─── Action Button ───────────────────────────────────────────────────────────

// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final bool isDark;
//   final VoidCallback onTap;

//   const _ActionButton({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.isDark,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: color.withOpacity(0.2)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 18, color: color),
//             const SizedBox(height: 3),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Detail Row ──────────────────────────────────────────────────────────────

// class _DetailRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isDark;

//   const _DetailRow({
//     required this.label,
//     required this.value,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.white60 : Colors.black54,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: isDark ? Colors.white : Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Empty State ─────────────────────────────────────────────────────────────

// class _EmptyState extends StatelessWidget {
//   final IconData icon;
//   final String message;
//   final bool isDark;

//   const _EmptyState({
//     required this.icon,
//     required this.message,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               color: AppThemData.primary500.withOpacity(0.08),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon,
//                 size: 40, color: AppThemData.primary500.withOpacity(0.5)),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: isDark ? Colors.white54 : Colors.black38,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             'All pending bookings will appear here',
//             style: TextStyle(
//                 fontSize: 13,
//                 color: isDark ? Colors.white38 : Colors.black26),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DialogOption extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;

//   const _DialogOption({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(
//           border: Border.all(color: color.withOpacity(0.3)),
//           color: color.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(width: 12),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
