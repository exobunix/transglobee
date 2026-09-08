import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../providers/vehicle_type_provider.dart';
import '../../services/driver_service.dart';
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
                    isDark ? vehicleType.accentColor.withOpacity(0.15) : const Color(0xFFE3F2FD),
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
                              onPressed: () {
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
                                  onboardingComplete: driver.onboardingComplete,
                                  isApproved: driver.isApproved,
                                  aadhaarUrl: driver.aadhaarUrl,
                                  licenseUrl: driver.licenseUrl,
                                  panUrl: driver.panUrl,
                                  rcUrl: driver.rcUrl,
                                  signatureUrl: driver.signatureUrl,
                                  insuranceUrl: driver.insuranceUrl,
                                );
                                Navigator.pushNamed(context, AppRouter.editProfile, arguments: model);
                              },
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
                  _buildSectionHeader('Documents'),
                  if (driverProfileState.status == ApiStatus.loading)
                    const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                  else if (driverProfileState.data != null)
                    Builder(builder: (context) {
                      final driver = driverProfileState.data!;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            _buildDocRow(
                              'Email Verified', 
                              'Email Verified', 
                              driver.isEmailVerified,
                              isVerified: driver.isEmailVerified
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'Driving License', 
                              driver.drivingLicenseNumber, 
                              driver.licenseUrl.isNotEmpty,
                              isVerified: driver.drivingLicenseVerified
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'Aadhar Card', 
                              driver.aadharCardNumber, 
                              driver.aadhaarUrl.isNotEmpty,
                              isVerified: driver.aadharVerified
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'PAN Card', 
                              driver.panCardNumber, 
                              driver.panUrl.isNotEmpty || driver.panCardNumber.isNotEmpty,
                              isVerified: driver.panVerified
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'Signature', 
                              'Verified', 
                              true,
                              isVerified: true
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'RC Book', 
                              'Verified', 
                              true,
                              isVerified: true
                            ),
                            const Divider(height: 20),
                            _buildDocRow(
                              'Insurance', 
                              'Verified', 
                              true,
                              isVerified: true
                            ),
                          ],
                        ),
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
                onTap: () {
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
                    onboardingComplete: driver.onboardingComplete,
                    isApproved: driver.isApproved,
                    aadhaarUrl: driver.aadhaarUrl,
                    licenseUrl: driver.licenseUrl,
                    panUrl: driver.panUrl,
                    rcUrl: driver.rcUrl,
                    signatureUrl: driver.signatureUrl,
                    insuranceUrl: driver.insuranceUrl,
                  );
                  Navigator.pushNamed(context, AppRouter.editProfile, arguments: model);
                },
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: const TextStyle(
              color: AppTheme.darkTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }

  Widget _buildDocRow(String name, String status, bool? uploaded,
      {bool isVerified = false}) {
    final color = isVerified
        ? AppTheme.neonGreen
        : (uploaded == true ? AppTheme.earningsAmber : AppTheme.offlineRed);
    final icon =
        isVerified ? Icons.verified : (uploaded == true ? Icons.check_circle : Icons.pending);
    final statusText = isVerified ? 'Verified' : status;

    return Row(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
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
      ],
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
