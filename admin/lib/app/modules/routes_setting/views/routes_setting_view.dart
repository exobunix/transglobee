import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/routes_setting/controllers/routes_setting_controller.dart';

class RoutesSettingView extends StatelessWidget {
  const RoutesSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<RoutesSettingController>(
      init: RoutesSettingController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextCustom(
                      title: "Manage Routes".tr,
                      fontSize: 22,
                      fontFamily: AppThemeData.bold,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemData.primary500,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        controller.clearForm();
                        showDialog(
                          context: context,
                          builder: (context) => const RouteAddEditDialog(),
                        );
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Add Route".tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : controller.routesList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.route_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  TextCustom(
                                    title: "No routes found. Please add a route.".tr,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.routesList.length,
                              itemBuilder: (context, index) {
                                final route = controller.routesList[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  color: themeChange.isDarkTheme() ? AppThemData.greyShade900 : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppThemData.primary500.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.alt_route, color: AppThemData.primary500, size: 22),
                                    ),
                                    title: TextCustom(
                                      title: route.name ?? 'Unnamed Route',
                                      fontSize: 15,
                                      fontFamily: AppThemeData.bold,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "${route.source ?? 'N/A'}  →  ${route.destination ?? 'N/A'}",
                                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "${route.distance?.toStringAsFixed(1) ?? '0'} km",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                          tooltip: "Edit",
                                          onPressed: () {
                                            controller.fillForm(route);
                                            showDialog(
                                              context: context,
                                              builder: (context) => const RouteAddEditDialog(),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          tooltip: "Delete",
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("Delete Route".tr),
                                                content: Text("Are you sure you want to delete \"${route.name}\"?".tr),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: Text("Cancel".tr),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      controller.deleteRoute(route.id!);
                                                    },
                                                    child: Text("Delete".tr, style: const TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Route Add / Edit Dialog ─────────────────────────────────────────────────

class RouteAddEditDialog extends GetView<RoutesSettingController> {
  const RouteAddEditDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite,
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => TextCustom(
                          title: controller.isEditing.value ? "Edit Route".tr : "Add Route".tr,
                          fontSize: 18,
                          fontFamily: AppThemeData.bold,
                        )),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Route Name
                _buildLabel("Route Name".tr),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller.nameController,
                  decoration: _inputDecoration("e.g. Noida to Delhi", isDark),
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 20),

                // Start & End Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Start Location".tr),
                          const SizedBox(height: 6),
                          _LocationAutocompleteField(
                            controller: controller.sourceController,
                            hintText: "Search start location",
                            isDark: isDark,
                            markerColor: Colors.blue,
                            onChanged: controller.searchSourceLocation,
                            suggestionsObs: controller.sourceSuggestions,
                            isVisibleObs: controller.isSourceSuggestionVisible,
                            onSuggestionSelected: (s) => controller.selectSourcePlace(s),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // End Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("End Location".tr),
                          const SizedBox(height: 6),
                          _LocationAutocompleteField(
                            controller: controller.destinationController,
                            hintText: "Search end location",
                            isDark: isDark,
                            markerColor: Colors.red,
                            onChanged: controller.searchDestLocation,
                            suggestionsObs: controller.destSuggestions,
                            isVisibleObs: controller.isDestSuggestionVisible,
                            onSuggestionSelected: (s) => controller.selectDestPlace(s),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Distance Field (auto-calculated, but editable)
                _buildLabel("Distance (km)".tr),
                const SizedBox(height: 6),
                Obx(() => TextFormField(
                      controller: controller.distanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration("Auto-calculated", isDark).copyWith(
                        suffixIcon: controller.isCalculatingDistance.value
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.straighten, size: 18, color: Colors.green),
                        helperText: "Auto-calculated from locations. You can also edit manually.",
                        helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                    )),
                const SizedBox(height: 20),

                // Map Label + hint
                Row(
                  children: [
                    _buildLabel("Map — Tap to Pin Locations".tr),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "1st tap = Start  •  2nd tap = End",
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Google Map
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GetBuilder<RoutesSettingController>(
                      builder: (c) => GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: c.startLatLng ?? c.defaultLatLng,
                          zoom: 12,
                        ),
                        markers: c.markers,
                        polylines: c.polylines,
                        onTap: c.onMapTap,
                        onMapCreated: (mapController) {
                          c.mapController = mapController;
                        },
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel".tr),
                    ),
                    const SizedBox(width: 12),
                    Obx(() => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemData.primary500,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: controller.isLoading.value ? null : controller.saveRoute,
                          icon: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                          label: Text(
                            "Save Route".tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  InputDecoration _inputDecoration(String hint, bool isDark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppThemData.primary500),
        ),
        filled: true,
        fillColor: isDark ? AppThemData.greyShade800 : Colors.grey.shade50,
      );
}

// ─── Location Autocomplete Field Widget ──────────────────────────────────────

class _LocationAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;
  final Color markerColor;
  final void Function(String) onChanged;
  final RxList suggestionsObs;
  final RxBool isVisibleObs;
  final void Function(PlaceSuggestion) onSuggestionSelected;

  const _LocationAutocompleteField({
    required this.controller,
    required this.hintText,
    required this.isDark,
    required this.markerColor,
    required this.onChanged,
    required this.suggestionsObs,
    required this.isVisibleObs,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: Icon(Icons.location_searching, color: markerColor, size: 18),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          controller.clear();
                          suggestionsObs.clear();
                          isVisibleObs.value = false;
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: markerColor),
                ),
                filled: true,
                fillColor: isDark ? AppThemData.greyShade800 : Colors.grey.shade50,
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
            ),
            if (isVisibleObs.value && suggestionsObs.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? AppThemData.greyShade900 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: suggestionsObs.length,
                  itemBuilder: (context, i) {
                    final s = suggestionsObs[i];
                    return InkWell(
                      onTap: () => onSuggestionSelected(s),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.place_outlined, size: 16, color: markerColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.mainText,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (s.secondaryText.isNotEmpty)
                                    Text(
                                      s.secondaryText,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ));
  }
}




// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../../core/network/dio_provider.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../shared/widgets/place_search_field.dart';
// import '../providers/routes_provider.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

// // --- Riverpod Providers ---

// final serviceCategoriesProvider = FutureProvider<List<dynamic>>((ref) async {
//   final dio = ref.watch(dioProvider);
//   final response = await dio.get('admin/categories');
//   final data = response.data;
//   if (data is Map && data['categories'] is List) {
//     return data['categories'];
//   }
//   return [];
// });



// final shiftsProvider = FutureProvider<List<dynamic>>((ref) async {
//   final dio = ref.watch(dioProvider);
//   final response = await dio.get('admin/shifts');
//   final data = response.data;
//   if (data is Map && data['shifts'] is List) {
//     return data['shifts'];
//   }
//   return [];
// });

// class ServicesRoutesShiftsScreen extends ConsumerStatefulWidget {
//   const ServicesRoutesShiftsScreen({super.key});

//   @override
//   ConsumerState<ServicesRoutesShiftsScreen> createState() =>
//       _ServicesRoutesShiftsScreenState();
// }

// class _ServicesRoutesShiftsScreenState
//     extends ConsumerState<ServicesRoutesShiftsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.pageBackground,
//       appBar: AppBar(
//         backgroundColor: AppTheme.topBarBackground,
//         elevation: 0,
//         title: const Text(
//           'Services, Routes & Shifts',
//           style: TextStyle(
//             color: AppTheme.textPrimaryDark,
//             fontWeight: FontWeight.w900,
//             fontSize: 30,
//           ),
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: AppTheme.primaryColor,
//           unselectedLabelColor: AppTheme.textSecondaryDark,
//           indicatorColor: AppTheme.primaryColor,
//           tabs: const [
//             Tab(icon: Icon(Icons.category_outlined), text: 'Service Categories'),
//             Tab(icon: Icon(Icons.map_outlined), text: 'Routes'),
//             Tab(icon: Icon(Icons.schedule_outlined), text: 'Shifts'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildCategoriesTab(),
//           _buildRoutesTab(),
//           _buildShiftsTab(),
//         ],
//       ),
//     );
//   }

//   // --- TAB 1: SERVICE CATEGORIES ---
//   Widget _buildCategoriesTab() {
//     final categoriesAsync = ref.watch(serviceCategoriesProvider);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppTheme.primaryColor,
//         onPressed: () => _showAddCategoryDialog(context),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: categoriesAsync.when(
//         data: (categories) {
//           if (categories.isEmpty) {
//             return _buildEmptyState(
//               icon: Icons.category_outlined,
//               title: 'No Categories Found',
//               subtitle: 'Create a service category like Cab, Logistics, or Shuttle.',
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(20),
//             itemCount: categories.length,
//             itemBuilder: (context, idx) {
//               final cat = categories[idx] as Map<String, dynamic>;
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: AppTheme.cardBackground,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppTheme.lineSoft),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
//                       radius: 26,
//                       child: const Icon(
//                         Icons.local_taxi_outlined,
//                         color: AppTheme.primaryColor,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             cat['name']?.toString() ?? 'Unnamed Category',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: AppTheme.textPrimaryDark,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Type: ${cat['type']?.toString().toUpperCase() ?? "N/A"}',
//                             style: const TextStyle(
//                               color: AppTheme.textSecondaryDark,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           'Base: ₹${cat['baseFare'] ?? 0}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: AppTheme.textPrimaryDark,
//                           ),
//                         ),
//                         Text(
//                           '₹${cat['ratePerKm'] ?? 0}/km',
//                           style: const TextStyle(
//                             color: AppTheme.textSecondaryDark,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(child: Text('Error: $e')),
//       ),
//     );
//   }

//   void _showAddCategoryDialog(BuildContext context) {
//     final nameCtrl = TextEditingController();
//     final typeCtrl = TextEditingController(text: 'cab');
//     final baseFareCtrl = TextEditingController(text: '50');
//     final ratePerKmCtrl = TextEditingController(text: '15');
//     final ratePerMinCtrl = TextEditingController(text: '2');

//     showDialog(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         title: const Text('Add Service Category'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameCtrl,
//                 decoration: const InputDecoration(labelText: 'Name (e.g. Sedan, Mini)'),
//               ),
//               const SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 value: typeCtrl.text,
//                 items: const [
//                   DropdownMenuItem(value: 'cab', child: Text('Cab')),
//                   DropdownMenuItem(value: 'logistics', child: Text('Logistics')),
//                   DropdownMenuItem(value: 'shuttle', child: Text('Shuttle')),
//                 ],
//                 onChanged: (v) => typeCtrl.text = v ?? 'cab',
//                 decoration: const InputDecoration(labelText: 'Service Type'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: baseFareCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Base Fare (₹)'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: ratePerKmCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Rate Per Km (₹)'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: ratePerMinCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Rate Per Minute (₹)'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogCtx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 final dio = ref.read(dioProvider);
//                 await dio.post('admin/categories', data: {
//                   'name': nameCtrl.text.trim(),
//                   'type': typeCtrl.text.trim(),
//                   'baseFare': double.tryParse(baseFareCtrl.text) ?? 50,
//                   'ratePerKm': double.tryParse(ratePerKmCtrl.text) ?? 15,
//                   'ratePerMinute': double.tryParse(ratePerMinCtrl.text) ?? 2,
//                 });
//                 ref.invalidate(serviceCategoriesProvider);
//                 if (mounted) Navigator.pop(dialogCtx);
//               } catch (e) {
//                 _showErrorSnackBar(e);
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- TAB 2: ROUTES ---
//   Widget _buildRoutesTab() {
//     final routesAsync = ref.watch(routesProvider);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppTheme.primaryColor,
//         onPressed: () => _showRouteFormDialog(context, null),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: routesAsync.when(
//         data: (routes) {
//           if (routes.isEmpty) {
//             return _buildEmptyState(
//               icon: Icons.map_outlined,
//               title: 'No Routes Found',
//               subtitle: 'Define routes connecting stations, cities, or hubs.',
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(20),
//             itemCount: routes.length,
//             itemBuilder: (context, idx) {
//               final route = routes[idx] as Map<String, dynamic>;
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: AppTheme.cardBackground,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppTheme.lineSoft),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: AppTheme.accentColor.withOpacity(0.1),
//                       radius: 26,
//                       child: const Icon(
//                         Icons.route_outlined,
//                         color: AppTheme.accentColor,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             route['name']?.toString() ?? 'Unnamed Route',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: AppTheme.textPrimaryDark,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'From: ${route['startLocation'] ?? "N/A"}  →  To: ${route['endLocation'] ?? "N/A"}',
//                             style: const TextStyle(
//                               color: AppTheme.textSecondaryDark,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (route['distance'] != null) ...[
//                       Text(
//                         '${route['distance']} km',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.primaryColor,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                     ],
//                     IconButton(
//                       icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
//                       onPressed: () => _showRouteFormDialog(context, route),
//                       tooltip: 'Edit Route',
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
//                       onPressed: () => _confirmDeleteRoute(context, route['_id']),
//                       tooltip: 'Delete Route',
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(child: Text('Error: $e')),
//       ),
//     );
//   }

//   void _showRouteFormDialog(BuildContext context, Map<String, dynamic>? route) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogCtx) => _RouteFormDialog(route: route, ref: ref),
//     );
//   }

//   void _confirmDeleteRoute(BuildContext context, String routeId) {
//     showDialog(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         title: const Text('Delete Route'),
//         content: const Text('Are you sure you want to delete this route? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogCtx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
//             onPressed: () async {
//               try {
//                 final dio = ref.read(dioProvider);
//                 await dio.delete('admin/routes/$routeId');
//                 ref.invalidate(routesProvider);
//                 if (mounted) {
//                   Navigator.pop(dialogCtx);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Route deleted successfully'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) Navigator.pop(dialogCtx);
//                 _showErrorSnackBar(e);
//               }
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- TAB 3: SHIFTS ---
//   Widget _buildShiftsTab() {
//     final shiftsAsync = ref.watch(shiftsProvider);

//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppTheme.primaryColor,
//         onPressed: () => _showShiftFormDialog(context, null),
//         child: const Icon(Icons.add, color: Colors.white),
//       ),
//       body: shiftsAsync.when(
//         data: (shifts) {
//           if (shifts.isEmpty) {
//             return _buildEmptyState(
//               icon: Icons.schedule_outlined,
//               title: 'No Shifts Found',
//               subtitle: 'Schedule work shifts and driver schedules.',
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(20),
//             itemCount: shifts.length,
//             itemBuilder: (context, idx) {
//               final shift = shifts[idx] as Map<String, dynamic>;
//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: AppTheme.cardBackground,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: AppTheme.lineSoft),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: AppTheme.success.withOpacity(0.1),
//                       radius: 26,
//                       child: const Icon(
//                         Icons.timer_outlined,
//                         color: AppTheme.success,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             shift['name']?.toString() ?? 'Unnamed Shift',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: AppTheme.textPrimaryDark,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Time: ${shift['startTime'] ?? "N/A"} - ${shift['endTime'] ?? "N/A"}',
//                             style: const TextStyle(
//                               color: AppTheme.textSecondaryDark,
//                               fontSize: 13,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
//                       onPressed: () => _showShiftFormDialog(context, shift),
//                       tooltip: 'Edit Shift',
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
//                       onPressed: () => _confirmDeleteShift(context, shift['_id']),
//                       tooltip: 'Delete Shift',
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(child: Text('Error: $e')),
//       ),
//     );
//   }

//   void _showShiftFormDialog(BuildContext context, Map<String, dynamic>? shift) {
//     final nameCtrl = TextEditingController(text: shift != null ? shift['name']?.toString() : '');
//     final startCtrl = TextEditingController(text: shift != null ? shift['startTime']?.toString() : '09:00 AM');
//     final endCtrl = TextEditingController(text: shift != null ? shift['endTime']?.toString() : '05:00 PM');
//     final title = shift == null ? 'Add Shift' : 'Edit Shift';

//     showDialog(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         title: Text(title),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameCtrl,
//                 style: const TextStyle(color: AppTheme.textPrimaryDark),
//                 decoration: const InputDecoration(labelText: 'Shift Name (e.g. Morning Shift)'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: startCtrl,
//                 style: const TextStyle(color: AppTheme.textPrimaryDark),
//                 decoration: const InputDecoration(labelText: 'Start Time'),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: endCtrl,
//                 style: const TextStyle(color: AppTheme.textPrimaryDark),
//                 decoration: const InputDecoration(labelText: 'End Time'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogCtx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 final dio = ref.read(dioProvider);
//                 final payload = {
//                   'name': nameCtrl.text.trim(),
//                   'startTime': startCtrl.text.trim(),
//                   'endTime': endCtrl.text.trim(),
//                 };
//                 if (shift == null) {
//                   await dio.post('admin/shifts', data: payload);
//                 } else {
//                   await dio.put('admin/shifts/${shift['_id']}', data: payload);
//                 }
//                 ref.invalidate(shiftsProvider);
//                 if (dialogCtx.mounted) Navigator.pop(dialogCtx);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(shift == null ? 'Shift added successfully' : 'Shift updated successfully'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 _showErrorSnackBar(e);
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmDeleteShift(BuildContext context, String shiftId) {
//     showDialog(
//       context: context,
//       builder: (dialogCtx) => AlertDialog(
//         title: const Text('Delete Shift'),
//         content: const Text('Are you sure you want to delete this shift? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogCtx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
//             onPressed: () async {
//               try {
//                 final dio = ref.read(dioProvider);
//                 await dio.delete('admin/shifts/$shiftId');
//                 ref.invalidate(shiftsProvider);
//                 if (mounted) {
//                   Navigator.pop(dialogCtx);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Shift deleted successfully'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 }
//               } catch (e) {
//                 if (mounted) Navigator.pop(dialogCtx);
//                 _showErrorSnackBar(e);
//               }
//             },
//             child: const Text('Delete', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Helper UI Widgets ---
//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//   }) {
//     return Center(
//       child: Container(
//         width: 560,
//         padding: const EdgeInsets.all(24),
//         margin: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: AppTheme.cardBackground,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppTheme.lineSoft),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 56, color: AppTheme.primaryColor),
//             const SizedBox(height: 16),
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//                 color: AppTheme.textPrimaryDark,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: const TextStyle(color: AppTheme.textSecondaryDark),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showErrorSnackBar(Object e) {
//     String msg = e.toString();
//     if (e is DioException) {
//       final data = e.response?.data;
//       if (data is Map && data['message'] != null) {
//         msg = data['message'].toString();
//       }
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }

// class _RouteFormDialog extends StatefulWidget {
//   final Map<String, dynamic>? route;
//   final WidgetRef ref;

//   const _RouteFormDialog({super.key, this.route, required this.ref});

//   @override
//   State<_RouteFormDialog> createState() => _RouteFormDialogState();
// }

// class _RouteFormDialogState extends State<_RouteFormDialog> {
//   final _nameCtrl = TextEditingController();
//   final _startCtrl = TextEditingController();
//   final _endCtrl = TextEditingController();
//   final _distanceCtrl = TextEditingController();

//   double? _startLat;
//   double? _startLng;
//   double? _endLat;
//   double? _endLng;

//   bool _isSaving = false;
//   bool _isLoadingRoute = false;

//   gmaps.GoogleMapController? _mapController;
//   final Set<gmaps.Marker> _markers = {};
//   final Set<gmaps.Polyline> _polylines = {};

//   @override
//   void initState() {
//     super.initState();
//     if (widget.route != null) {
//       final r = widget.route!;
//       _nameCtrl.text = r['name']?.toString() ?? '';
//       _startCtrl.text = r['startLocation']?.toString() ?? '';
//       _endCtrl.text = r['endLocation']?.toString() ?? '';
//       _distanceCtrl.text = r['distance']?.toString() ?? '';
      
//       _startLat = (r['startLat'] as num?)?.toDouble() ?? (r['stops'] != null && r['stops'].isNotEmpty ? (r['stops'].first['coordinates']?['lat'] as num?)?.toDouble() : null);
//       _startLng = (r['startLng'] as num?)?.toDouble() ?? (r['stops'] != null && r['stops'].isNotEmpty ? (r['stops'].first['coordinates']?['lng'] as num?)?.toDouble() : null);
//       _endLat = (r['endLat'] as num?)?.toDouble() ?? (r['stops'] != null && r['stops'].isNotEmpty ? (r['stops'].last['coordinates']?['lat'] as num?)?.toDouble() : null);
//       _endLng = (r['endLng'] as num?)?.toDouble() ?? (r['stops'] != null && r['stops'].isNotEmpty ? (r['stops'].last['coordinates']?['lng'] as num?)?.toDouble() : null);

//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _updateMap();
//         if (_startLat != null && _endLat != null) {
//           _fetchOSRMRoute();
//         }
//       });
//     }
//   }

//   void _updateMap() {
//     if (!mounted) return;
//     setState(() {
//       _markers.clear();
//       if (_startLat != null && _startLng != null) {
//         _markers.add(
//           gmaps.Marker(
//             markerId: const gmaps.MarkerId('start'),
//             position: gmaps.LatLng(_startLat!, _startLng!),
//             infoWindow: const gmaps.InfoWindow(title: 'Start Location'),
//             icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
//           ),
//         );
//       }
//       if (_endLat != null && _endLng != null) {
//         _markers.add(
//           gmaps.Marker(
//             markerId: const gmaps.MarkerId('end'),
//             position: gmaps.LatLng(_endLat!, _endLng!),
//             infoWindow: const gmaps.InfoWindow(title: 'End Location'),
//             icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
//           ),
//         );
//       }
//     });

//     _zoomToFit();
//   }

//   void _zoomToFit() {
//     if (_mapController == null) return;

//     if (_startLat != null && _startLng != null && _endLat != null && _endLng != null) {
//       final bounds = gmaps.LatLngBounds(
//         southwest: gmaps.LatLng(
//           _startLat! < _endLat! ? _startLat! : _endLat!,
//           _startLng! < _endLng! ? _startLng! : _endLng!,
//         ),
//         northeast: gmaps.LatLng(
//           _startLat! > _endLat! ? _startLat! : _endLat!,
//           _startLng! > _endLng! ? _startLng! : _endLng!,
//         ),
//       );
//       _mapController!.animateCamera(gmaps.CameraUpdate.newLatLngBounds(bounds, 50));
//     } else if (_startLat != null && _startLng != null) {
//       _mapController!.animateCamera(
//         gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(_startLat!, _startLng!), 14),
//       );
//     } else if (_endLat != null && _endLng != null) {
//       _mapController!.animateCamera(
//         gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(_endLat!, _endLng!), 14),
//       );
//     }
//   }

//   Future<void> _fetchOSRMRoute() async {
//     if (_startLat == null || _startLng == null || _endLat == null || _endLng == null) return;

//     if (mounted) setState(() => _isLoadingRoute = true);
//     try {
//       final url = 'https://router.project-osrm.org/route/v1/driving/$_startLng,$_startLat;$_endLng,$_endLat?overview=full&geometries=geojson';
//       final response = await Dio().get(url);
//       if (response.statusCode == 200) {
//         final data = response.data;
//         final routes = data['routes'] as List;
//         if (routes.isNotEmpty) {
//           final route = routes[0];
//           final distance = (route['distance'] as num).toDouble() / 1000.0;
//           final geometry = route['geometry']['coordinates'] as List;

//           final points = geometry.map((coord) {
//             return gmaps.LatLng(coord[1].toDouble(), coord[0].toDouble());
//           }).toList();

//           if (mounted) {
//             setState(() {
//               _distanceCtrl.text = distance.toStringAsFixed(1);
//               _polylines.clear();
//               _polylines.add(
//                 gmaps.Polyline(
//                   polylineId: const gmaps.PolylineId('route'),
//                   points: points,
//                   color: AppTheme.primaryColor,
//                   width: 5,
//                 ),
//               );
//             });
//           }
//         }
//       }
//     } catch (e) {
//       debugPrint('Error fetching OSRM route: $e');
//     } finally {
//       if (mounted) setState(() => _isLoadingRoute = false);
//     }
//   }

//   Future<void> _saveRoute() async {
//     final name = _nameCtrl.text.trim();
//     final start = _startCtrl.text.trim();
//     final end = _endCtrl.text.trim();
//     final distance = double.tryParse(_distanceCtrl.text.trim()) ?? 0.0;

//     if (name.isEmpty || start.isEmpty || end.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
//       );
//       return;
//     }

//     if (mounted) setState(() => _isSaving = true);
//     try {
//       final dio = widget.ref.read(dioProvider);
//       final payload = {
//         'name': name,
//         'startLocation': start,
//         'endLocation': end,
//         'startLat': _startLat,
//         'startLng': _startLng,
//         'endLat': _endLat,
//         'endLng': _endLng,
//         'distance': distance,
//         'stops': [
//           if (_startLat != null && _startLng != null)
//             {
//               'name': start,
//               'coordinates': {'lat': _startLat, 'lng': _startLng},
//               'estimatedTimeFromStart': 0,
//             },
//           if (_endLat != null && _endLng != null)
//             {
//               'name': end,
//               'coordinates': {'lat': _endLat, 'lng': _endLng},
//               'estimatedTimeFromStart': 0,
//             }
//         ],
//       };

//       if (widget.route == null) {
//         await dio.post('admin/routes', data: payload);
//       } else {
//         await dio.put('admin/routes/${widget.route!['_id']}', data: payload);
//       }

//       widget.ref.invalidate(routesProvider);
//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(widget.route == null ? 'Route created successfully' : 'Route updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       String errMsg = 'Failed to save route';
//       if (e is DioException && e.response?.data != null) {
//         errMsg = e.response?.data['message'] ?? errMsg;
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errMsg), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final title = widget.route == null ? 'Add Route' : 'Edit Route';
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         width: 600,
//         padding: const EdgeInsets.all(24),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryDark),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _nameCtrl,
//                 style: const TextStyle(color: AppTheme.textPrimaryDark),
//                 decoration: InputDecoration(
//                   labelText: 'Route Name (e.g. Noida to Delhi)',
//                   labelStyle: const TextStyle(color: AppTheme.textSecondaryDark),
//                   filled: true,
//                   fillColor: const Color(0xFFF8FAFC),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               PlaceSearchField(
//                 controller: _startCtrl,
//                 label: 'Start Location / Station',
//                 onPlaceSelected: (address, lat, lng) {
//                   _startLat = lat;
//                   _startLng = lng;
//                   _updateMap();
//                   _fetchOSRMRoute();
//                 },
//               ),
//               const SizedBox(height: 16),
//               PlaceSearchField(
//                 controller: _endCtrl,
//                 label: 'End Location / Station',
//                 onPlaceSelected: (address, lat, lng) {
//                   _endLat = lat;
//                   _endLng = lng;
//                   _updateMap();
//                   _fetchOSRMRoute();
//                 },
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _distanceCtrl,
//                       keyboardType: TextInputType.number,
//                       style: const TextStyle(color: AppTheme.textPrimaryDark),
//                       decoration: InputDecoration(
//                         labelText: 'Distance (km)',
//                         labelStyle: const TextStyle(color: AppTheme.textSecondaryDark),
//                         filled: true,
//                         fillColor: const Color(0xFFF8FAFC),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                         suffixIcon: _isLoadingRoute
//                             ? const Padding(
//                                 padding: EdgeInsets.all(12),
//                                 child: SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child: CircularProgressIndicator(strokeWidth: 2),
//                                 ),
//                               )
//                             : null,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               // Map Visualizer
//               Container(
//                 height: 200,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppTheme.lineSoft),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: gmaps.GoogleMap(
//                   initialCameraPosition: const gmaps.CameraPosition(
//                     target: gmaps.LatLng(28.6139, 77.2090), // Default to New Delhi
//                     zoom: 10,
//                   ),
//                   markers: _markers,
//                   polylines: _polylines,
//                   onMapCreated: (controller) {
//                     _mapController = controller;
//                     _updateMap();
//                   },
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppTheme.primaryColor,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     onPressed: _isSaving ? null : _saveRoute,
//                     child: _isSaving
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                           )
//                         : const Text('Save Route', style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
