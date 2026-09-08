import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/cab_detail/controllers/cab_detail_controller.dart';
import 'segment_card_item_view.dart';

class SupervisorRoadmapCardView extends StatelessWidget {
  final CabDetailController controller;
  final DarkThemeProvider themeChange;

  const SupervisorRoadmapCardView({
    super.key,
    required this.controller,
    required this.themeChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = themeChange.isDarkTheme();
    final cardBgColor = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
    final borderColor = isDark ? AppThemData.greyShade800 : AppThemData.greyShade100;

    return ContainerCustom(
      child: Card(
        color: cardBgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alt_route, color: AppThemData.primary500),
                      const SizedBox(width: 8),
                      TextCustom(title: "Roadmap Builder".tr, fontSize: 16, fontFamily: AppThemeData.bold),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => controller.addSegment(),
                    icon: Icon(Icons.add, color: AppThemData.primary500),
                    label: Text("Add Segment".tr, style: TextStyle(color: AppThemData.primary500, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segment list
              Obx(() {
                if (controller.segments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        "No segments yet. Tap + Add Segment to start.".tr,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ),
                  );
                }
                return Column(
                  children: List.generate(controller.segments.length, (index) {
                    return SegmentCardItemView(
                      key: ValueKey('segment_$index'),
                      segment: controller.segments[index],
                      index: index,
                      controller: controller,
                      themeChange: themeChange,
                    );
                  }),
                );
              }),

              const SizedBox(height: 16),

              // Save Roadmap button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSavingRoadmap.value ? null : () => controller.saveRoadmap(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C4DE6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: controller.isSavingRoadmap.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_outlined, color: Colors.white),
                            const SizedBox(width: 8),
                            Text("Save Roadmap".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                )),
              ),
              const SizedBox(height: 10),

              // Approve & Send to drivers button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() {
                  final bool canApprove = controller.isRoadmapSaved.value && !controller.isApprovingRoadmap.value;
                  return ElevatedButton(
                    onPressed: canApprove ? () => controller.approveRoadmap() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canApprove ? const Color(0xFF28A745) : Colors.grey.shade400,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: controller.isApprovingRoadmap.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_outlined, color: Colors.white),
                              const SizedBox(width: 8),
                              Text("Approve & send to drivers".tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
