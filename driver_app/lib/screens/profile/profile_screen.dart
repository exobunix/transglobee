import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../providers/vehicle_type_provider.dart';
import '../../services/auth_service.dart';
import '../../core/app_router.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../features/driver/models/response/driver_profile_response.dart';
import '../../core/network/api_state.dart';
import '../wallet/wallet_screen.dart';
import '../../models/driver_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileControllerProvider.notifier).getDriverProfile();
    });
  }

  void _openEditProfile(DriverProfileResponseModel driver) {
    final model = DriverModel(
      id: driver.id,
      firebaseId: driver.id,
      email: driver.email,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      profilePic: driver.profilePic,
      vehicleId: driver.vehicleNumber,
      vehicleModel: driver.vehicleModel,
      vehicleYear: driver.vehicleYear,
      vehicleNumberPlate: driver.vehicleNumberPlate,
      aadharCardNumber: driver.aadharCardNumber,
      drivingLicenseNumber: driver.drivingLicenseNumber,
      panCardNumber: driver.panCardNumber,
      isEmailVerified: driver.isEmailVerified,
      panVerified: driver.panVerified,
      aadharVerified: driver.aadharVerified,
      drivingLicenseVerified: driver.drivingLicenseVerified,
      rcVerified: driver.rcVerified,
      insuranceVerified: driver.insuranceVerified,
      signatureVerified: driver.signatureVerified,
      onboardingComplete: driver.onboardingComplete,
      isApproved: driver.isApproved,
      aadhaarUrl: driver.aadhaarUrl,
      licenseUrl: driver.licenseUrl,
      panUrl: driver.panUrl,
      rcUrl: driver.rcUrl,
      signatureUrl: driver.signatureUrl,
      insuranceUrl: driver.insuranceUrl,
      dob: driver.dob,
      vehicleType: driver.vehicleType,
    );
    Navigator.pushNamed(context, AppRouter.editProfile, arguments: model);
  }

  @override
  Widget build(BuildContext context) {
    final vehicleType = ref.watch(vehicleTypeProvider);
    final isDark = ref.watch(themeProvider);
    final driverProfileState = ref.watch(driverProfileControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? vehicleType.accentColor.withValues(alpha: 0.15) : const Color(0xFFE3F2FD),
                    Theme.of(context).scaffoldBackgroundColor
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: _buildProfileHeader(driverProfileState, vehicleType, isDark),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle card
                  _buildSectionHeader('My Vehicle'),
                  if (driverProfileState.status == ApiStatus.loading)
                    const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                  else if (driverProfileState.data != null)
                    Builder(builder: (context) {
                      final driver = driverProfileState.data!;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: vehicleType.accentColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: vehicleType.accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                              child: Icon(vehicleType.icon, color: vehicleType.accentColor, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(driver.vehicleModel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).dividerColor)),
                                        child: Text(driver.vehicleNumberPlate, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11, fontFamily: 'monospace')),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${driver.vehicleYear} • ${vehicleType.label}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                                    ]),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _openEditProfile(driver),
                              icon: Icon(Icons.edit_outlined, color: vehicleType.accentColor, size: 20),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    const Text('Error loading vehicle'),
                  const SizedBox(height: 20),

                  // Documents
                  if (driverProfileState.status == ApiStatus.loading)
                    const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                  else if (driverProfileState.data != null)
                    Builder(builder: (context) {
                      final driver = driverProfileState.data!;

                      final hasDLNum = driver.drivingLicenseNumber.trim().isNotEmpty;
                      final hasDLFile = driver.licenseUrl.trim().isNotEmpty;
                      final isDLVerified = driver.drivingLicenseVerified;
                      final isDLUploaded = hasDLFile || hasDLNum;
                      final dlStatus = isDLVerified ? 'Verified' : (hasDLFile ? 'Uploaded' : (hasDLNum ? 'Added' : 'Not Uploaded'));

                      final hasAadharNum = driver.aadharCardNumber.trim().isNotEmpty;
                      final hasAadharFile = driver.aadhaarUrl.trim().isNotEmpty;
                      final isAadharVerified = driver.aadharVerified;
                      final isAadharUploaded = hasAadharFile || hasAadharNum;
                      final aadharStatus = isAadharVerified ? 'Verified' : (hasAadharFile ? 'Uploaded' : (hasAadharNum ? 'Added' : 'Not Uploaded'));

                      final hasPanNum = driver.panCardNumber.trim().isNotEmpty;
                      final hasPanFile = driver.panUrl.trim().isNotEmpty;
                      final isPanVerified = driver.panVerified;
                      final isPanUploaded = hasPanFile || hasPanNum;
                      final panStatus = isPanVerified ? 'Verified' : (hasPanFile ? 'Uploaded' : (hasPanNum ? 'Added' : 'Not Uploaded'));

                      final hasSigFile = driver.signatureUrl.trim().isNotEmpty;
                      final isSigVerified = driver.signatureVerified || (hasSigFile && driver.isApproved);
                      final isSigUploaded = hasSigFile;
                      final sigStatus = isSigVerified ? 'Verified' : (hasSigFile ? 'Uploaded' : 'Not Uploaded');

                      final hasRcFile = driver.rcUrl.trim().isNotEmpty;
                      final isRcVerified = driver.rcVerified || (hasRcFile && driver.isApproved);
                      final isRcUploaded = hasRcFile;
                      final rcStatus = isRcVerified ? 'Verified' : (hasRcFile ? 'Uploaded' : 'Not Uploaded');

                      final hasInsFile = driver.insuranceUrl.trim().isNotEmpty;
                      final isInsVerified = driver.insuranceVerified || (hasInsFile && driver.isApproved);
                      final isInsUploaded = hasInsFile;
                      final insStatus = isInsVerified ? 'Verified' : (hasInsFile ? 'Uploaded' : 'Not Uploaded');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Documents',
                            onAction: () => _openEditProfile(driver),
                            actionText: 'Upload / Edit',
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                _buildDocRow(
                                  'Email Verified', 
                                  driver.isEmailVerified ? 'Verified' : 'Unverified', 
                                  driver.isEmailVerified,
                                  isVerified: driver.isEmailVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'Driving License', 
                                  dlStatus, 
                                  isDLUploaded,
                                  isVerified: isDLVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'Aadhar Card', 
                                  aadharStatus, 
                                  isAadharUploaded,
                                  isVerified: isAadharVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'PAN Card', 
                                  panStatus, 
                                  isPanUploaded,
                                  isVerified: isPanVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'Signature', 
                                  sigStatus, 
                                  isSigUploaded,
                                  isVerified: isSigVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'RC Book', 
                                  rcStatus, 
                                  isRcUploaded,
                                  isVerified: isRcVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                                const Divider(height: 20),
                                _buildDocRow(
                                  'Insurance', 
                                  insStatus, 
                                  isInsUploaded,
                                  isVerified: isInsVerified,
                                  onTap: () => _openEditProfile(driver),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                  else
                    const Text('Error loading documents'),
                  const SizedBox(height: 20),

                  // Settings
                  _buildSectionHeader('Settings'),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildArrowTile(Icons.person_outline, 'Edit Profile', 'Update personal & vehicle details', AppTheme.neonGreen, onTap: () {
                          if (driverProfileState.data != null) {
                            _openEditProfile(driverProfileState.data!);
                          }
                        }),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.account_balance_wallet_outlined, 'My Wallet', 'Check balance & history', AppTheme.earningsAmber, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                        }),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildToggle('Dark Mode', Icons.dark_mode_outlined, AppTheme.earningsAmber, isDark, (v) => ref.read(themeProvider.notifier).toggle()),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildToggle('Push Notifications', Icons.notifications_outlined, AppTheme.neonGreen, _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildToggle('Location Sharing', Icons.location_on_outlined, AppTheme.cabBlue, _locationSharing, (v) => setState(() => _locationSharing = v)),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.language, 'Language', 'English', AppTheme.busPurple),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.help_outline, 'Support & Help', '', AppTheme.earningsAmber),
                        const Divider(color: AppTheme.darkDivider, height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.policy_outlined, 'Terms & Privacy', '', AppTheme.darkTextSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Call API #14
                        await ref.read(logoutControllerProvider.notifier).logout('placeholder_device_token');
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, AppRouter.auth, (r) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.offlineRed,
                        side: BorderSide(color: AppTheme.offlineRed.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      ))
      );
  }

  Widget _buildProfileHeader(ApiState<DriverProfileResponseModel> state, VehicleType vehicleType, bool isDark) {
    if (state.status == ApiStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.data == null) {
      return const Center(child: Text('Error loading profile'));
    }
    final driver = state.data!;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [vehicleType.accentColor, vehicleType.accentColor.withValues(alpha: 0.5)])),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: (driver.profilePic.isNotEmpty) ? NetworkImage(driver.profilePic) : null,
                child: (driver.profilePic.isEmpty) ? Icon(Icons.person, color: vehicleType.accentColor, size: 46) : null,
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: InkWell(
                onTap: () => _openEditProfile(driver),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(driver.name, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(driver.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _statPill(Icons.star, '${driver.rating}', AppTheme.earningsAmber),
            _statPill(Icons.directions_car, '${driver.totalRides} Trips',
                vehicleType.accentColor),
            _statPill(
                Icons.verified,
                driver.onboardingComplete ? 'Verified' : 'Pending',
                driver.onboardingComplete
                    ? AppTheme.neonGreen
                    : AppTheme.earningsAmber),
          ],
        ),
      ],
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, String? actionText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.darkTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          if (onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText ?? 'Edit',
                      style: const TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit_outlined, size: 12, color: AppTheme.neonGreen),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocRow(
    String name,
    String status,
    bool uploaded, {
    bool isVerified = false,
    VoidCallback? onTap,
  }) {
    final Color color;
    final IconData icon;
    final String statusText;

    if (isVerified) {
      color = AppTheme.neonGreen;
      icon = Icons.verified;
      statusText = 'Verified';
    } else if (uploaded) {
      color = AppTheme.earningsAmber;
      icon = Icons.access_time_rounded;
      statusText = status.isNotEmpty && status != 'Pending' ? status : 'Uploaded';
    } else {
      color = AppTheme.offlineRed;
      icon = Icons.pending;
      statusText = status.isNotEmpty ? status : 'Not Uploaded';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.description_outlined,
                color: AppTheme.darkTextSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 14, color: AppTheme.darkTextSecondary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: color),
    );
  }

  Widget _buildArrowTile(IconData icon, String label, String sub, Color color, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: sub.isNotEmpty
          ? Text(
              sub,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.darkDivider,
        size: 18,
      ),
    );
  }
}
