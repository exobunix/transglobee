import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/services/shared_preferences/app_preference.dart';
import 'package:admin/app/constant/api_constant.dart';
import 'package:admin/app/utils/http_client.dart' as http;
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';

class SegmentCardItemView extends StatefulWidget {
  final RoadmapSegment segment;
  final int index;
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SegmentCardItemView({
    super.key,
    required this.segment,
    required this.index,
    required this.controller,
    required this.themeChange,
  });

  @override
  State<SegmentCardItemView> createState() => _SegmentCardItemViewState();
}

class _SegmentCardItemViewState extends State<SegmentCardItemView> {
  bool get _isComplete {
    final seg = widget.segment;
    return seg.fromController.text.trim().isNotEmpty &&
        seg.toController.text.trim().isNotEmpty &&
        seg.dateController.text.trim().isNotEmpty &&
        seg.timeController.text.trim().isNotEmpty &&
        seg.priceController.text.trim().isNotEmpty &&
        (double.tryParse(seg.priceController.text.trim()) ?? 0) > 0;
  }
  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeChange.isDarkTheme();
    final cardBg = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
    final borderColor = isDark ? AppThemData.greyShade800 : AppThemData.greyShade200;
    final fieldFill = isDark ? AppThemData.greyShade950 : AppThemData.greyShade50;

    final seg = widget.segment;
    final label = "Seg ${widget.index + 1}";
    final nextLabel = "Seg ${widget.index + 2}";
    final complete = _isComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: complete ? AppThemData.primary500.withOpacity(0.5) : borderColor,
          width: complete ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppThemData.greyShade950 : AppThemData.greyShade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: complete ? AppThemData.primary500 : Colors.grey.shade400,
                  child: Text(
                    "${widget.index + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Segment ${widget.index + 1}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  if (seg.assignedDriverName.value.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            seg.assignedDriverName.value,
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Tooltip(
                  message: complete ? "Assign Driver" : "Fill all segment fields first",
                  child: IconButton(
                    icon: Icon(
                      Icons.person_add_outlined,
                      size: 20,
                      color: complete ? AppThemData.primary500 : Colors.grey.shade400,
                    ),
                    onPressed: complete ? _showAssignDriverDialog : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: "Remove Segment",
                  onPressed: () => widget.controller.removeSegment(widget.index),
                ),
              ],
            ),
          ),

          // Fields
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: seg.fromController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "From Location ($label)",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true, fillColor: fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: seg.toController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "To Location ($nextLabel)",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true, fillColor: fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                Obx(() {
                  const modeItems = ["Road", "Rail", "Air", "Sea"];
                  final selected = modeItems.contains(seg.mode.value) ? seg.mode.value : modeItems.first;
                  return DropdownButtonFormField<String>(
                    value: selected,
                    decoration: InputDecoration(
                      labelText: "Mode",
                      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true, fillColor: fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    items: modeItems.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) { if (val != null) seg.mode.value = val; },
                  );
                }),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: seg.selectedDate.value ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            seg.selectedDate.value = picked;
                            seg.dateController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            setState(() {});
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: seg.dateController,
                            decoration: InputDecoration(
                              hintText: "Est. Date",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppThemData.primary500),
                              filled: true, fillColor: fieldFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: seg.selectedTime.value ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            seg.selectedTime.value = picked;
                            seg.timeController.text =
                                "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                            setState(() {});
                          }
                        },
                        child: IgnorePointer(
                          child: TextField(
                            controller: seg.timeController,
                            decoration: InputDecoration(
                              hintText: "Est. Time",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                              prefixIcon: Icon(Icons.access_time_outlined, size: 18, color: AppThemData.primary500),
                              filled: true, fillColor: fieldFill,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: seg.priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: "Segment Price (₹)",
                    labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    filled: true, fillColor: fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),

                if (!complete) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      Text(
                        "Fill all fields to enable driver assignment",
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignDriverDialog() async {
    final token = await AppSharedPreference.getString('adminToken');
    final uri = Uri.parse("${ApiConstant.adminDrivers}?status=active&limit=50");

    List<Map<String, dynamic>> drivers = [];
    try {
      final res = await http.get(uri, headers: ApiConstant.headers(token: token));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['drivers'] ?? json['data'] ?? [];
        if (list is List) {
          drivers = list.map<Map<String, dynamic>>((d) => Map<String, dynamic>.from(d)).toList();
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.person_search_outlined, size: 22),
                      const SizedBox(width: 8),
                      const Text("Assign Driver to Segment",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (drivers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text("No online drivers found.", style: TextStyle(color: Colors.grey))),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: drivers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx2, i) {
                        final d = drivers[i];
                        final name = d['fullName'] ?? d['name'] ?? 'Unknown';
                        final phone = d['phoneNumber'] ?? d['phone'] ?? '';
                        final id = d['_id'] ?? d['id'] ?? '';
                        final vehicle = d['vehicleType'] ?? d['vehicle']?['type'] ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppThemData.primary500.withOpacity(0.15),
                            child: Icon(Icons.drive_eta, color: AppThemData.primary500),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("$phone${vehicle.isNotEmpty ? ' • $vehicle' : ''}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              widget.segment.assignedDriverId.value = id;
                              widget.segment.assignedDriverName.value = name;
                              if (mounted) setState(() {});
                              Get.snackbar(
                                "Driver Assigned",
                                "$name assigned to Segment ${widget.index + 1}",
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemData.primary500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text("Assign", style: TextStyle(color: Colors.white)),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
