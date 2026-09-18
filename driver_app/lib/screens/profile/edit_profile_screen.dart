import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../models/driver_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/driver_service.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../providers/vehicle_type_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final DriverModel driver;

  const EditProfileScreen({super.key, required this.driver});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // Personal Controllers
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;

  // Vehicle Controllers
  late TextEditingController _plateController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;

  // Identity / KYC Controllers
  late TextEditingController _aadharController;
  late TextEditingController _licenseController;
  late TextEditingController _panController;

  // Selected Vehicle Type
  String _selectedVehicleType = 'Cab';

  // Document Files for upload
  final ImagePicker _picker = ImagePicker();
  final Map<String, XFile?> _pickedFiles = {};
  final Map<String, Uint8List?> _pickedBytes = {};

  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _nameController = TextEditingController(text: d.name ?? '');
    _mobileController = TextEditingController(text: d.phoneNumber ?? '');
    _dobController = TextEditingController(
      text: d.dob != null && d.dob!.isNotEmpty
          ? (d.dob!.contains('T') ? d.dob!.split('T').first : d.dob!)
          : '',
    );

    // Initialize vehicle type
    final initialVehicle = d.vehicleType;
    if (initialVehicle != null && initialVehicle.isNotEmpty && initialVehicle.toUpperCase() != 'N/A') {
      final normalized = initialVehicle.trim().toLowerCase();
      if (normalized == 'truck') {
        _selectedVehicleType = 'Truck';
      } else if (normalized == 'bus') {
        _selectedVehicleType = 'Bus';
      } else {
        _selectedVehicleType = 'Cab';
      }
    } else {
      _selectedVehicleType = 'Cab';
    }

    _plateController = TextEditingController(text: d.vehicleNumberPlate ?? '');
    _modelController = TextEditingController(text: d.vehicleModel ?? '');
    _yearController = TextEditingController(text: d.vehicleYear ?? '');

    _aadharController = TextEditingController(text: d.aadharCardNumber ?? '');
    _licenseController = TextEditingController(text: d.drivingLicenseNumber ?? '');
    _panController = TextEditingController(text: d.panCardNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _plateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _aadharController.dispose();
    _licenseController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String docKey) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedFiles[docKey] = file;
          _pickedBytes[docKey] = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e'), backgroundColor: AppTheme.offlineRed),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonGreen,
              onPrimary: Colors.black,
              surface: AppTheme.darkCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving profile details...';
    });

    try {
      final auth = ref.read(authServiceProvider);
      final db = ref.read(databaseServiceProvider);
      final user = auth.currentUser;
      final token = await auth.getIdToken();

      if (token == null) throw Exception('Authentication token missing. Please log in again.');

      final effectiveUid = user?.uid ?? widget.driver.id;
      final effectiveEmail = user?.email ?? widget.driver.email;

      // 1. Upload any selected document files (including profile photo) first
      Map<String, dynamic>? uploadResult;
      if (_pickedFiles.values.any((f) => f != null)) {
        setState(() => _loadingMessage = 'Uploading photo & documents...');
        uploadResult = await db.uploadDriverDocuments(
          token: token,
          photoFile: _pickedFiles['photo'],
          aadharFile: _pickedFiles['aadharCard'],
          licenseFile: _pickedFiles['drivingLicense'],
          signatureFile: _pickedFiles['signature'],
          panFile: _pickedFiles['panCard'],
          rcBookFile: _pickedFiles['rcBook'],
          insuranceFile: _pickedFiles['insurance'],
          uid: effectiveUid,
          email: effectiveEmail,
        );
      }

      // 2. Update text fields in MongoDB
      setState(() => _loadingMessage = 'Updating driver details...');
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'dob': _dobController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'vehicleNumberPlate': _plateController.text.trim(),
        'vehicleModel': _modelController.text.trim(),
        'vehicleYear': _yearController.text.trim(),
        'aadharCardNumber': _aadharController.text.trim(),
        'drivingLicenseNumber': _licenseController.text.trim(),
        'panCardNumber': _panController.text.trim().toUpperCase(),
      };

      if (uploadResult != null && uploadResult['urls'] is Map) {
        final urls = uploadResult['urls'] as Map;
        if (urls['photo'] != null) {
          updateData['photo'] = urls['photo'];
        }
      }

      await db.updateDriverProfile(
        token: token,
        updateData: updateData,
        uid: effectiveUid,
        email: effectiveEmail,
      );

      // Update vehicle type provider state
      if (_selectedVehicleType.toLowerCase() == 'truck') {
        ref.read(vehicleTypeProvider.notifier).select(VehicleType.truck);
      } else if (_selectedVehicleType.toLowerCase() == 'bus') {
        ref.read(vehicleTypeProvider.notifier).select(VehicleType.bus);
      } else {
        ref.read(vehicleTypeProvider.notifier).select(VehicleType.cab);
      }

      // Invalidate providers to refresh profile in whole app
      ref.invalidate(driverProfileProvider);
      ref.invalidate(isOnboardingCompleteProvider);
      ref.read(driverProfileControllerProvider.notifier).getDriverProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile & Details updated successfully!'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.offlineRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfilePhotoHeader() {
    final bool hasNewPhoto = _pickedBytes['photo'] != null;
    final bool hasExistingPhoto =
        widget.driver.profilePic != null && widget.driver.profilePic!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 6),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasNewPhoto
                        ? AppTheme.neonGreen
                        : AppTheme.neonGreen.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: hasNewPhoto ? 0.35 : 0.15),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _pickImage('photo'),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: AppTheme.darkCard,
                    backgroundImage: hasNewPhoto
                        ? MemoryImage(_pickedBytes['photo']!)
                        : (hasExistingPhoto
                            ? NetworkImage(widget.driver.profilePic!) as ImageProvider
                            : null),
                    child: (!hasNewPhoto && !hasExistingPhoto)
                        ? const Icon(
                            Icons.person,
                            size: 54,
                            color: AppTheme.neonGreen,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppTheme.neonGreen,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _pickImage('photo'),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickImage('photo'),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasNewPhoto ? Icons.check_circle_outline : Icons.photo_camera_outlined,
                    size: 16,
                    color: hasNewPhoto ? AppTheme.neonGreen : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasNewPhoto ? 'New Photo Selected (Tap to change)' : 'Change Profile Photo',
                    style: TextStyle(
                      color: hasNewPhoto ? AppTheme.neonGreen : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasNewPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Will be saved when you press Save All Changes below',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Edit Profile & Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Profile Photo Avatar
            _buildProfilePhotoHeader(),

            // Section 1: Personal Details
            _buildSectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _buildTextField(_nameController, 'Full Name', Icons.badge_outlined),
                const SizedBox(height: 14),
                _buildTextField(
                  _mobileController,
                  'Mobile Number',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: _buildTextField(
                      _dobController,
                      'Date of Birth (YYYY-MM-DD)',
                      Icons.cake_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2: Vehicle Details
            _buildSectionCard(
              title: 'Vehicle Details',
              icon: Icons.directions_car_outlined,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vehicle Type',
                      style: TextStyle(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedVehicleType,
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildVehicleTypeChip('Cab', Icons.local_taxi, AppTheme.cabBlue),
                    const SizedBox(width: 8),
                    _buildVehicleTypeChip('Truck', Icons.local_shipping, AppTheme.truckOrange),
                    const SizedBox(width: 8),
                    _buildVehicleTypeChip('Bus', Icons.directions_bus, AppTheme.busPurple),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_plateController, 'Vehicle Number Plate', Icons.numbers),
                const SizedBox(height: 14),
                _buildTextField(_modelController, 'Vehicle Model (e.g. Innova, Swift)', Icons.car_repair_outlined),
                const SizedBox(height: 14),
                _buildTextField(
                  _yearController,
                  'Manufacture Year (e.g. 2022)',
                  Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: Identity & KYC Numbers
            _buildSectionCard(
              title: 'Identity & KYC Numbers',
              icon: Icons.verified_user_outlined,
              children: [
                _buildTextField(
                  _aadharController,
                  'Aadhaar Card Number',
                  Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _licenseController,
                  'Driving License Number',
                  Icons.card_membership_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _panController,
                  'PAN Card Number',
                  Icons.assignment_ind_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 4: Document Uploads
            _buildSectionCard(
              title: 'Documents & Photos',
              icon: Icons.cloud_upload_outlined,
              children: [
                _buildDocUploadRow('Profile Photo', 'photo', widget.driver.profilePic),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('Driving License', 'drivingLicense', widget.driver.licenseUrl),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('Aadhaar Card', 'aadharCard', widget.driver.aadhaarUrl),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('PAN Card', 'panCard', widget.driver.panUrl),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('Signature', 'signature', widget.driver.signatureUrl),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('RC Book', 'rcBook', widget.driver.rcUrl),
                const Divider(color: AppTheme.darkDivider, height: 20),
                _buildDocUploadRow('Insurance', 'insurance', widget.driver.insuranceUrl),
              ],
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_loadingMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      )
                    : const Text(
                        'SAVE ALL CHANGES',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.neonGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.neonGreen, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDocUploadRow(String title, String docKey, String? existingUrl) {
    final bool hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final bool hasPicked = _pickedFiles[docKey] != null;
    final Uint8List? previewBytes = _pickedBytes[docKey];

    return Row(
      children: [
        // Thumbnail or Icon
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            color: AppTheme.darkBg,
            child: previewBytes != null
                ? Image.memory(previewBytes, fit: BoxFit.cover)
                : (hasExisting
                    ? Image.network(
                        existingUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.description_outlined, color: AppTheme.neonGreen, size: 22),
                      )
                    : const Icon(Icons.upload_file_outlined, color: Colors.white54, size: 22)),
          ),
        ),
        const SizedBox(width: 12),
        // Title & status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                hasPicked
                    ? 'New image selected'
                    : (hasExisting ? 'Uploaded on server' : 'Not uploaded yet'),
                style: TextStyle(
                  color: hasPicked
                      ? AppTheme.neonGreen
                      : (hasExisting ? Colors.white60 : Colors.amber.shade300),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Action Button
        OutlinedButton.icon(
          onPressed: () => _pickImage(docKey),
          style: OutlinedButton.styleFrom(
            foregroundColor: hasPicked ? AppTheme.neonGreen : Colors.white,
            side: BorderSide(color: hasPicked ? AppTheme.neonGreen : Colors.white24),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(hasPicked || hasExisting ? Icons.refresh : Icons.add_photo_alternate_outlined, size: 14),
          label: Text(hasPicked || hasExisting ? 'Change' : 'Upload', style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeChip(String type, IconData icon, Color color) {
    final bool isSelected = _selectedVehicleType.toLowerCase() == type.toLowerCase();
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVehicleType = type;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.darkBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.darkDivider.withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppTheme.darkTextSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
