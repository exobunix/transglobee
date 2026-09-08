import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/driver_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/driver_service.dart';
import '../../features/driver/controllers/driver_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final DriverModel driver;

  const EditProfileScreen({super.key, required this.driver});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _plateController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _mobileController = TextEditingController(text: widget.driver.phoneNumber);
    _plateController = TextEditingController(text: widget.driver.vehicleNumberPlate);
    _modelController = TextEditingController(text: widget.driver.vehicleModel);
    _yearController = TextEditingController(text: widget.driver.vehicleYear);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final db = ref.read(databaseServiceProvider);
      final token = await auth.getIdToken();

      if (token == null) return;

      final updateData = {
        'name': _nameController.text,
        'mobileNumber': _mobileController.text,
        'vehicleNumberPlate': _plateController.text,
        'vehicleModel': _modelController.text,
        'vehicleYear': _yearController.text,
      };

      await db.updateDriverProfile(
        token: token,
        updateData: updateData,
      );

      // Invalidate providers to refresh profile data
      ref.invalidate(driverProfileProvider);
      ref.invalidate(isOnboardingCompleteProvider);
      ref.read(driverProfileControllerProvider.notifier).getDriverProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.neonGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.offlineRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_mobileController, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(_plateController, 'Vehicle Number Plate', Icons.numbers),
            const SizedBox(height: 16),
            _buildTextField(_modelController, 'Vehicle Model', Icons.directions_car),
            const SizedBox(height: 16),
            _buildTextField(_yearController, 'Manufacture Year', Icons.calendar_today, keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('UPDATE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: AppTheme.neonGreen),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.neonGreen),
        ),
        filled: true,
        fillColor: AppTheme.darkCard,
      ),
    );
  }
}
