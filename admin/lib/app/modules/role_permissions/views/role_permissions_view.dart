import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:admin/app/components/menu_widget.dart';

import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';

import 'package:admin/widget/container_custom.dart';

import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/app/modules/role_permissions/controllers/role_permissions_controller.dart';

class RolePermissionsView extends GetView<RolePermissionsController> {
  const RolePermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.isDarkTheme()
          ? AppThemData.primaryBlack
          : AppThemData.primaryWhite,
      body: Row(
        children: [
          if (ResponsiveWidget.isDesktop(context)) const MenuWidget(),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: themeChange.isDarkTheme()
                      ? AppThemData.greyShade900
                      : AppThemData.primaryWhite,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextCustom(
                        title: "Role & Permissions Management".tr,
                        fontSize: 20,
                        fontFamily: AppThemeData.bold,
                        color: themeChange.isDarkTheme()
                            ? AppThemData.primaryWhite
                            : AppThemData.primaryBlack,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TextCustom(
                              title: "Supervisor Accounts & Permissions",
                              fontSize: 18,
                              fontFamily: AppThemeData.bold,
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(context, null),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text("Add New Supervisor",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemData.primary500,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          if (controller.isLoading.value) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(50),
                              child: CircularProgressIndicator(),
                            ));
                          }

                          if (controller.subAdmins.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: TextCustom(
                                    title: "No Supervisor accounts created yet."),
                              ),
                            );
                          }

                          return ContainerCustom(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: TextCustom(title: "NAME", fontFamily: AppThemeData.bold)),
                                  DataColumn(label: TextCustom(title: "EMAIL", fontFamily: AppThemeData.bold)),
                                  DataColumn(label: TextCustom(title: "ROLE", fontFamily: AppThemeData.bold)),
                                  DataColumn(label: TextCustom(title: "ALLOWED MODULES", fontFamily: AppThemeData.bold)),
                                  DataColumn(label: TextCustom(title: "ACTIONS", fontFamily: AppThemeData.bold)),
                                ],
                                rows: controller.subAdmins
                                    .where((s) => s.role == 'supervisor')
                                    .map((subAdmin) {
                                  final modulesText = (subAdmin.allowedModules == null || subAdmin.allowedModules!.isEmpty)
                                      ? "All / None"
                                      : subAdmin.allowedModules!.join(", ");
                                  return DataRow(cells: [
                                    DataCell(
                                      Text(
                                        subAdmin.name ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                      onTap: () => _showDetailDialog(context, subAdmin),
                                    ),
                                    DataCell(
                                      Text(subAdmin.email ?? '-'),
                                      onTap: () => _showDetailDialog(context, subAdmin),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppThemData.primary500.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (subAdmin.role ?? 'supervisor').toUpperCase(),
                                          style: TextStyle(
                                            color: AppThemData.primary500,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      onTap: () => _showDetailDialog(context, subAdmin),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Text(
                                          modulesText,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      onTap: () => _showDetailDialog(context, subAdmin),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, color: Colors.teal, size: 20),
                                          tooltip: "View Details",
                                          onPressed: () => _showDetailDialog(context, subAdmin),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          tooltip: "Edit Supervisor",
                                          onPressed: () => _showAddEditDialog(context, subAdmin),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          tooltip: "Delete Supervisor",
                                          onPressed: () => _confirmDelete(context, subAdmin),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, SubAdminModel? item) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final isDark = themeChange.isDarkTheme();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final emailCtrl = TextEditingController(text: item?.email ?? '');
    final passwordCtrl = TextEditingController(text: item?.plainPassword ?? '');
    String selectedRole = item?.role ?? 'supervisor';
    final List<String> selectedModules = List<String>.from(item?.allowedModules ?? []);
    bool isImportMode = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final cardBg = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
            final textColor = isDark ? AppThemData.primaryWhite : AppThemData.primaryBlack;
            final subTextColor = isDark ? AppThemData.greyShade400 : AppThemData.greyShade600;
            final inputBg = isDark ? AppThemData.greyShade800 : AppThemData.greyShade100;
            final borderColor = isDark ? AppThemData.greyShade700 : AppThemData.greyShade200;

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 540,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title
                      TextCustom(
                        title: item == null ? "Add New Sub-Admin / Supervisor" : "Edit Account",
                        fontSize: 20,
                        fontFamily: AppThemeData.bold,
                        color: textColor,
                      ),
                      const SizedBox(height: 18),

                      // Toggle Tabs: Create New vs Import User/Driver
                      if (item == null) ...[
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isImportMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !isImportMode ? AppThemData.primary500 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !isImportMode ? AppThemData.primary500 : borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (!isImportMode) const Icon(Icons.check, size: 16, color: Colors.white),
                                    if (!isImportMode) const SizedBox(width: 6),
                                    Text(
                                      "Create New",
                                      style: TextStyle(
                                        color: !isImportMode ? Colors.white : textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => isImportMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isImportMode ? AppThemData.primary500 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isImportMode ? AppThemData.primary500 : borderColor,
                                  ),
                                ),
                                child: Text(
                                  "Import User/Driver",
                                  style: TextStyle(
                                    color: isImportMode ? Colors.white : textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Import Dropdown when in Import Mode
                      if (isImportMode && controller.importableUsers.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ImportableUser>(
                              isExpanded: true,
                              dropdownColor: cardBg,
                              hint: Text("Select User or Driver to import", style: TextStyle(color: subTextColor)),
                              items: controller.importableUsers.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    "${u.name} (${u.type}: ${u.email})",
                                    style: TextStyle(color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (u) {
                                if (u != null) {
                                  setState(() {
                                    nameCtrl.text = u.name ?? '';
                                    emailCtrl.text = u.email ?? '';
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Full Name Input
                      _buildThemeInput(controller: nameCtrl, hintText: "Full Name", isDark: isDark, cardBg: cardBg, inputBg: inputBg, borderColor: borderColor, textColor: textColor, subTextColor: subTextColor),
                      const SizedBox(height: 12),

                      // Email Address Input
                      _buildThemeInput(controller: emailCtrl, hintText: "Email Address", isDark: isDark, cardBg: cardBg, inputBg: inputBg, borderColor: borderColor, textColor: textColor, subTextColor: subTextColor),
                      const SizedBox(height: 12),

                      // Password Input
                      _buildThemeInput(
                        controller: passwordCtrl,
                        hintText: item == null ? "Password" : "New Password (Optional)",
                        isDark: isDark, cardBg: cardBg, inputBg: inputBg, borderColor: borderColor, textColor: textColor, subTextColor: subTextColor,
                      ),
                      const SizedBox(height: 14),

                      // Role Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text("Role", style: TextStyle(color: subTextColor, fontSize: 11)),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedRole,
                                dropdownColor: cardBg,
                                style: TextStyle(color: textColor, fontSize: 15),
                                items: [
                                  DropdownMenuItem(value: 'supervisor', child: Text("Supervisor", style: TextStyle(color: textColor))),
                                  DropdownMenuItem(value: 'admin', child: Text("Sub-Admin", style: TextStyle(color: textColor))),
                                  DropdownMenuItem(value: 'moderator', child: Text("Moderator", style: TextStyle(color: textColor))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedRole = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section Title
                      Text(
                        "MODULE ACCESS PERMISSIONS",
                        style: TextStyle(
                          color: AppThemData.primary500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Permission Chips Wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.availableModules.map((mod) {
                          final bool isChecked = selectedModules.contains(mod['id']);
                          return FilterChip(
                            label: Text(mod['name']!),
                            selected: isChecked,
                            selectedColor: AppThemData.primary500.withOpacity(0.2),
                            checkmarkColor: AppThemData.primary500,
                            labelStyle: TextStyle(
                              color: isChecked ? AppThemData.primary500 : textColor,
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: inputBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isChecked ? AppThemData.primary500 : borderColor,
                              ),
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedModules.add(mod['id']!);
                                } else {
                                  selectedModules.remove(mod['id']!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Bottom Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("CANCEL", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                                Get.snackbar("Error", "Name and Email are required", backgroundColor: Colors.red, colorText: Colors.white);
                                return;
                              }
                              if (item == null && passwordCtrl.text.trim().isEmpty) {
                                Get.snackbar("Error", "Password is required", backgroundColor: Colors.red, colorText: Colors.white);
                                return;
                              }

                              bool success = false;
                              if (item == null) {
                                success = await controller.createSubAdmin(
                                  name: nameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  password: passwordCtrl.text.trim(),
                                  role: selectedRole,
                                  allowedModules: selectedModules,
                                );
                              } else {
                                success = await controller.updateSubAdmin(
                                  id: item.id!,
                                  name: nameCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  password: passwordCtrl.text.trim(),
                                  role: selectedRole,
                                  allowedModules: selectedModules,
                                );
                              }

                              if (success && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppThemData.primary500,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              item == null ? "CREATE ACCOUNT" : "SAVE CHANGES",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeInput({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color cardBg,
    required Color inputBg,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: subTextColor, fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, SubAdminModel item) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    final isDark = themeChange.isDarkTheme();
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final cardBg = isDark ? AppThemData.greyShade900 : AppThemData.primaryWhite;
            final textColor = isDark ? AppThemData.primaryWhite : AppThemData.primaryBlack;
            final subTextColor = isDark ? AppThemData.greyShade400 : AppThemData.greyShade600;
            final inputBg = isDark ? AppThemData.greyShade800 : AppThemData.greyShade100;
            final borderColor = isDark ? AppThemData.greyShade700 : AppThemData.greyShade200;

            final pwdText = item.plainPassword?.isNotEmpty == true ? item.plainPassword! : "Not Set";
            final modulesText = (item.allowedModules == null || item.allowedModules!.isEmpty)
                ? "All / Full Access"
                : item.allowedModules!.join(", ");

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextCustom(
                          title: "Supervisor Details",
                          fontSize: 18,
                          fontFamily: AppThemeData.bold,
                          color: textColor,
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: subTextColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDetailRow("NAME", item.name ?? '-', textColor, subTextColor),
                    const SizedBox(height: 12),
                    _buildDetailRow("EMAIL", item.email ?? '-', textColor, subTextColor),
                    const SizedBox(height: 12),
                    _buildDetailRow("ROLE", (item.role ?? 'supervisor').toUpperCase(), textColor, subTextColor),
                    const SizedBox(height: 12),
                    
                    // Password Detail with Eye Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("PASSWORD", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              showPassword ? pwdText : "••••••••••••",
                              style: TextStyle(color: textColor, fontSize: 15, fontFamily: AppThemeData.medium),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppThemData.primary500,
                          ),
                          onPressed: () => setState(() => showPassword = !showPassword),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Allowed Modules Detail
                    Text("ALLOWED MODULES", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        modulesText,
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemData.primary500,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textColor, fontSize: 15, fontFamily: AppThemeData.medium)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, SubAdminModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete account for '${item.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteSubAdmin(item.id!);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
