import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme.dart';
import '../../../models/user_model.dart';

class LocationInputSection extends StatelessWidget {
  final TextEditingController pickupSearchController;
  final TextEditingController dropoffSearchController;
  final FocusNode pickupFocusNode;
  final FocusNode dropoffFocusNode;
  final DateTime selectedDate;
  final String selectedTime;
  final bool showSuggestions;
  final List<Map<String, dynamic>> searchResults;
  final bool activeSearchingPickup;
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;
  final UserRoute? selectedRoute;

  final VoidCallback onSwapLocations;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final Function(String query) onSearchChanged;
  final Function(Map<String, dynamic> suggestion, bool isPickup) onSuggestionTapped;

  const LocationInputSection({
    super.key,
    required this.pickupSearchController,
    required this.dropoffSearchController,
    required this.pickupFocusNode,
    required this.dropoffFocusNode,
    required this.selectedDate,
    required this.selectedTime,
    required this.showSuggestions,
    required this.searchResults,
    required this.activeSearchingPickup,
    required this.pickup,
    required this.dropoff,
    required this.selectedRoute,
    required this.onSwapLocations,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onSearchChanged,
    required this.onSuggestionTapped,
  });

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildSearchFieldRedesigned({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isPickup,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPickup ? Icons.my_location : Icons.location_on,
            color: const Color(0xFF0F5A3B),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: selectedRoute != null,
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    fillColor: Colors.transparent,
                  ),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context, bool isPickup) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, size: 20),
            title: Text(
              suggestion['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              suggestion['address'],
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSuggestionTapped(suggestion, isPickup),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSearchFieldRedesigned(
                      controller: pickupSearchController,
                      focusNode: pickupFocusNode,
                      label: 'Pickup Location',
                      hint: 'Search Pickup Location',
                      isPickup: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSwapLocations,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F5A3B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSearchFieldRedesigned(
                controller: dropoffSearchController,
                focusNode: dropoffFocusNode,
                label: 'Drop Location',
                hint: 'Search Drop Location',
                isPickup: false,
              ),
            ],
          ),
          if (showSuggestions && searchResults.isNotEmpty)
            _buildSuggestionsList(context, activeSearchingPickup),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSelectDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF0F5A3B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Date',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onSelectTime,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF0F5A3B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Time',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                selectedTime,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
