import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/components/menu_widget.dart';
import 'package:admin/app/constant/constants.dart';
import 'package:admin/app/models/wallet_request_model.dart';
import 'package:admin/app/modules/wallet_requests/controllers/wallet_requests_controller.dart';
import 'package:admin/app/routes/app_pages.dart';
import 'package:admin/app/utils/app_colors.dart';
import 'package:admin/app/utils/app_them_data.dart';
import 'package:admin/app/utils/dark_theme_provider.dart';
import 'package:admin/app/utils/responsive.dart';
import 'package:admin/widget/container_custom.dart';
import 'package:admin/widget/global_widgets.dart';
import 'package:admin/widget/text_widget.dart';
import 'package:admin/widget/common_ui.dart';

class WalletRequestsView extends GetView<WalletRequestsController> {
  const WalletRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<WalletRequestsController>(
      init: WalletRequestsController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade950 : AppThemData.greyShade50,
          appBar: AppBar(
            elevation: 0.0,
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            leadingWidth: 260,
            leading: Builder(
              builder: (BuildContext ctx) {
                return GestureDetector(
                  onTap: () {
                    if (!ResponsiveWidget.isDesktop(ctx)) {
                      Scaffold.of(ctx).openDrawer();
                    }
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: !ResponsiveWidget.isDesktop(ctx)
                        ? const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.menu,
                              size: 30,
                              color: AppThemData.primary500,
                            ),
                          )
                        : SizedBox(
                            height: 45,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/image/logo.png",
                                  height: 45,
                                  color: AppThemData.primary500,
                                ),
                                spaceW(),
                                const TextCustom(
                                  title: 'Transglobe',
                                  color: AppThemData.primary500,
                                  fontSize: 30,
                                  fontFamily: AppThemeData.semiBold,
                                  fontWeight: FontWeight.w700,
                                )
                              ],
                            ),
                          ),
                  ),
                );
              },
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  if (themeChange.darkTheme == 1) {
                    themeChange.darkTheme = 0;
                  } else {
                    themeChange.darkTheme = 1;
                  }
                },
                child: themeChange.isDarkTheme()
                    ? SvgPicture.asset(
                        "assets/icons/ic_sun.svg",
                        colorFilter: const ColorFilter.mode(AppThemData.yellow600, BlendMode.srcIn),
                        height: 20,
                        width: 20,
                      )
                    : SvgPicture.asset(
                        "assets/icons/ic_moon.svg",
                        colorFilter: const ColorFilter.mode(AppThemData.blue400, BlendMode.srcIn),
                        height: 20,
                        width: 20,
                      ),
              ),
              spaceW(),
              const LanguagePopUp(),
              spaceW(),
              ProfilePopUp()
            ],
          ),
          drawer: Drawer(
            width: 270,
            backgroundColor: themeChange.isDarkTheme() ? AppThemData.primaryBlack : AppThemData.primaryWhite,
            child: const MenuWidget(),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ResponsiveWidget.isDesktop(context)) const MenuWidget(),
              Expanded(
                child: Padding(
                  padding: paddingEdgeInsets(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header & Breadcrumb
                        _buildHeader(context, controller),
                        spaceH(height: 20),

                        // Stats Summary Cards
                        _buildStatsCards(context, controller, themeChange),
                        spaceH(height: 24),

                        // Main Content Container
                        ContainerCustom(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filters & Search Bar
                              _buildFiltersBar(context, controller, themeChange),
                              spaceH(height: 20),
                              const Divider(height: 1, color: AppThemData.greyShade200),
                              spaceH(height: 20),

                              // Table / Request List
                              controller.isLoading.value
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 60),
                                      child: Constant.loader(),
                                    )
                                  : controller.requestList.isEmpty
                                      ? _buildEmptyState(themeChange)
                                      : _buildRequestsTable(context, controller, themeChange),

                              // Pagination
                              if (!controller.isLoading.value && controller.requestList.isNotEmpty) ...[
                                spaceH(height: 20),
                                _buildPagination(controller, themeChange),
                              ],
                            ],
                          ),
                        ),
                        spaceH(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, WalletRequestsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(
          title: 'Wallet Requests'.tr,
          fontSize: 22,
          fontFamily: AppThemeData.bold,
        ),
        spaceH(height: 4),
        Row(
          children: [
            GestureDetector(
              onTap: () => Get.offAllNamed(Routes.DASHBOARD_SCREEN),
              child: TextCustom(
                title: 'Dashboard'.tr,
                fontSize: 14,
                fontFamily: AppThemeData.medium,
                color: AppThemData.greyShade500,
              ),
            ),
            const TextCustom(title: ' / ', fontSize: 14, color: AppThemData.greyShade500),
            TextCustom(
              title: 'Wallet Requests'.tr,
              fontSize: 14,
              fontFamily: AppThemeData.medium,
              color: AppThemData.primary500,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(
      BuildContext context, WalletRequestsController controller, DarkThemeProvider themeChange) {
    final stats = controller.stats.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final isTablet = constraints.maxWidth < 1100 && !isMobile;

        final cards = [
          _buildStatCard(
            title: 'Total Requests',
            value: stats.total.toString(),
            icon: Icons.receipt_long_rounded,
            iconColor: AppThemData.blue500,
            bgColor: AppThemData.blue500.withOpacity(0.08),
            themeChange: themeChange,
          ),
          _buildStatCard(
            title: 'Pending Approval',
            value: '${stats.pending}  (₹${stats.pendingAmount.toStringAsFixed(0)})',
            icon: Icons.hourglass_top_rounded,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFF59E0B).withOpacity(0.12),
            isHighlighted: true,
            themeChange: themeChange,
          ),
          _buildStatCard(
            title: 'Total Approved',
            value: '${stats.approved}  (₹${stats.approvedAmount.toStringAsFixed(0)})',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF10B981).withOpacity(0.1),
            themeChange: themeChange,
          ),
          _buildStatCard(
            title: 'Rejected',
            value: stats.rejected.toString(),
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFEF4444).withOpacity(0.1),
            themeChange: themeChange,
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }

        if (isTablet) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 14), Expanded(child: cards[1])]),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 14), Expanded(child: cards[3])]),
            ],
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 14), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required DarkThemeProvider themeChange,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (themeChange.isDarkTheme() ? const Color(0xFF2A2111) : const Color(0xFFFFFBEB))
            : (themeChange.isDarkTheme() ? AppThemData.greyShade900 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFF59E0B).withOpacity(0.4)
              : (themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade200),
          width: isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: themeChange.isDarkTheme() ? AppThemData.greyShade400 : AppThemData.greyShade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppThemeData.bold,
                    color: isHighlighted
                        ? const Color(0xFFD97706)
                        : (themeChange.isDarkTheme() ? Colors.white : AppThemData.greyShade950),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(
      BuildContext context, WalletRequestsController controller, DarkThemeProvider themeChange) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Status Filter Chips
        Row(
          mainAxisSize: MainAxisSize.min,
          children: controller.statusFilters.map((status) {
            final isSelected = controller.selectedStatus.value == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status.tr),
                selected: isSelected,
                onSelected: (_) => controller.onStatusChanged(status),
                selectedColor: AppThemData.primary500,
                backgroundColor: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (themeChange.isDarkTheme() ? AppThemData.greyShade300 : AppThemData.greyShade700),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),

        // User Type & Search Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Type Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeChange.isDarkTheme() ? AppThemData.greyShade700 : AppThemData.greyShade200,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedUserType.value,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  dropdownColor: themeChange.isDarkTheme() ? AppThemData.greyShade900 : Colors.white,
                  items: controller.userTypeFilters.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type == 'All' ? 'All Roles' : type,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeChange.isDarkTheme() ? Colors.white : AppThemData.greyShade900,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) controller.onUserTypeChanged(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Search Box
            SizedBox(
              width: 220,
              height: 42,
              child: TextField(
                controller: controller.searchController,
                onSubmitted: controller.onSearchSubmit,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search name, phone...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppThemData.greyShade400),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppThemData.greyShade400),
                  suffixIcon: controller.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: controller.clearSearch,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: themeChange.isDarkTheme() ? AppThemData.greyShade800 : AppThemData.greyShade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppThemData.primary500),
              tooltip: 'Refresh',
              onPressed: () => controller.fetchRequests(page: controller.currentPage.value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(DarkThemeProvider themeChange) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: themeChange.isDarkTheme() ? AppThemData.greyShade600 : AppThemData.greyShade400),
            const SizedBox(height: 16),
            Text(
              'No Wallet Requests Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeChange.isDarkTheme() ? Colors.white : AppThemData.greyShade900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When drivers or users request wallet top-up, they will show up here.',
              style: TextStyle(fontSize: 13, color: AppThemData.greyShade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTable(
      BuildContext context, WalletRequestsController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 340),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            themeChange.isDarkTheme() ? AppThemData.greyShade900 : AppThemData.greyShade100,
          ),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 74,
          horizontalMargin: 16,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Requester', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Requested Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: controller.requestList.map((req) {
            return DataRow(
              cells: [
                // Requester (Avatar + Name + Phone)
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: req.userType == 'driver'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                        child: Text(
                          (req.userName != null && req.userName!.isNotEmpty)
                              ? req.userName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: req.userType == 'driver'
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            req.userName ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (req.userPhone != null && req.userPhone!.isNotEmpty)
                            Text(
                              req.userPhone!,
                              style: const TextStyle(fontSize: 11, color: AppThemData.greyShade500),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Role badge (User or Driver)
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: req.userType == 'driver'
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      req.userType == 'driver' ? 'Driver' : 'User',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: req.userType == 'driver'
                            ? const Color(0xFFB45309)
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ),

                // Amount
                DataCell(
                  Text(
                    '₹${req.amount?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),

                // Payment Method
                DataCell(
                  Text(
                    req.paymentMethod?.toUpperCase() ?? 'UPI',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),

                // Status Badge
                DataCell(_buildStatusBadge(req.status ?? 'pending')),

                // Requested Date
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        req.createdAt != null
                            ? DateFormat('dd MMM yyyy').format(req.createdAt!)
                            : 'N/A',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (req.createdAt != null)
                        Text(
                          DateFormat('hh:mm a').format(req.createdAt!),
                          style: const TextStyle(fontSize: 11, color: AppThemData.greyShade500),
                        ),
                    ],
                  ),
                ),

                // Actions
                DataCell(
                  _buildActions(context, req, controller),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, WalletRequestModel req, WalletRequestsController controller) {
    if (req.status != 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            req.status == 'approved' ? Icons.check_circle : Icons.cancel,
            color: req.status == 'approved' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            req.status == 'approved' ? 'Settled' : 'Declined',
            style: const TextStyle(fontSize: 12, color: AppThemData.greyShade500),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Approve button
        ElevatedButton.icon(
          onPressed: () => _showApproveDialog(context, req, controller),
          icon: const Icon(Icons.check, size: 14),
          label: const Text('Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),

        // Reject button
        OutlinedButton.icon(
          onPressed: () => _showRejectDialog(context, req, controller),
          icon: const Icon(Icons.close, size: 14),
          label: const Text('Reject'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showApproveDialog(
      BuildContext context, WalletRequestModel req, WalletRequestsController controller) {
    final noteCtrl = TextEditingController(text: 'Approved by admin');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Approve Top-up Request', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve this wallet recharge request?'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _dialogRow('Requester', '${req.userName} (${req.userType?.toUpperCase()})'),
                  const SizedBox(height: 6),
                  _dialogRow('Amount to Credit', '₹${req.amount?.toStringAsFixed(2)}', isBold: true),
                  const SizedBox(height: 6),
                  _dialogRow('Payment Mode', req.paymentMethod?.toUpperCase() ?? 'UPI'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Admin Note (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (req.id != null) {
                controller.approveRequest(req.id!, note: noteCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm & Credit'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, WalletRequestModel req, WalletRequestsController controller) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFB91C1C), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Reject Top-up Request', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject the top-up request for ₹${req.amount}?'),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection',
                hintText: 'e.g. Payment not verified / Incorrect details',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (req.id != null) {
                controller.rejectRequest(
                  req.id!,
                  reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Payment not verified',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reject Request'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppThemData.greyShade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF10B981) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(WalletRequestsController controller, DarkThemeProvider themeChange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing page ${controller.currentPage.value} of ${controller.totalPage.value} (${controller.totalItems.value} total)',
          style: TextStyle(
            fontSize: 13,
            color: themeChange.isDarkTheme() ? AppThemData.greyShade400 : AppThemData.greyShade600,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: controller.currentPage.value > 1
                  ? () => controller.fetchRequests(page: controller.currentPage.value - 1)
                  : null,
            ),
            Text(
              '${controller.currentPage.value}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: controller.currentPage.value < controller.totalPage.value
                  ? () => controller.fetchRequests(page: controller.currentPage.value + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
