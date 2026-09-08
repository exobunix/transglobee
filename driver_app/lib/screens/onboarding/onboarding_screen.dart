import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../core/config.dart';
import '../../providers/vehicle_type_provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/driver_model.dart';
import '../../utils/id_generator.dart';
import '../../services/driver_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Form data
  VehicleType _selectedVehicle = VehicleType.cab;
  String _selectedSubType = 'Sedan';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  
  DateTime? _dob;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  final Map<String, XFile?> _docFiles = {
    'Profile Photo': null,
    'Driving License': null,
    'Aadhar Card': null,
    'PAN Card': null,
    'Signature': null,
    'RC Book': null,
    'Insurance': null,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
    
    // Pre-fill from existing profile data to avoid duplicate entries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await ref.read(driverProfileProvider.future);
      if (profile != null) {
        final status = profile.status.trim().toLowerCase();
        final shouldPrefill = profile.isApproved ||
            profile.onboardingComplete ||
            status == 'active' ||
            status == 'available' ||
            status == 'offline';
        if (!shouldPrefill) return;

        setState(() {
          if (profile.name != null && profile.name!.isNotEmpty) {
            _nameCtrl.text = profile.name!;
          }
          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
            _phoneCtrl.text = profile.phoneNumber!;
          }
          if (profile.aadharCardNumber != null && profile.aadharCardNumber!.isNotEmpty) {
            _aadharCtrl.text = profile.aadharCardNumber!;
          }
          if (profile.panCardNumber != null && profile.panCardNumber!.isNotEmpty) {
            _panCtrl.text = profile.panCardNumber!;
          }
          
          // Pre-fill vehicle details if available
          if (profile.vehicleNumberPlate != null && profile.vehicleNumberPlate!.isNotEmpty) {
            _plateCtrl.text = profile.vehicleNumberPlate!;
          }
          if (profile.vehicleModel != null && profile.vehicleModel!.isNotEmpty) {
            _modelCtrl.text = profile.vehicleModel!;
          }
          if (profile.vehicleYear != null && profile.vehicleYear!.isNotEmpty) {
            _yearCtrl.text = profile.vehicleYear!;
          }
          if (profile.drivingLicenseNumber != null && profile.drivingLicenseNumber!.isNotEmpty) {
            _licenseCtrl.text = profile.drivingLicenseNumber!;
          }
          if (profile.dob != null && profile.dob!.isNotEmpty) {
            try {
              _dob = DateTime.parse(profile.dob!);
            } catch (e) {
              debugPrint('Error parsing DOB: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile for onboarding: $e');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _aadharCtrl.dispose();
    _panCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  int get _calculateAge {
    if (_dob == null) return 0;
    final today = DateTime.now();
    int age = today.year - _dob!.year;
    if (today.month < _dob!.month || (today.month == _dob!.month && today.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickImage(String docKey) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _docFiles[docKey] = image;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonGreen,
              onPrimary: AppTheme.darkBg,
              surface: AppTheme.darkSurface,
              onSurface: AppTheme.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _next() async {
    // Step-wise validation
    if (_currentPage == 0) { // Vehicle Type
      if (_selectedSubType == null) {
        _showError('Please select a vehicle type and sub-category.');
        return;
      }
    } else if (_currentPage == 1) { // Personal Info
      final name = _nameCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final aadhar = _aadharCtrl.text.trim();
      final pan = _panCtrl.text.trim().toUpperCase();
      final dl = _licenseCtrl.text.trim().toUpperCase();

      if (name.isEmpty) {
        _showError('Name is required');
        return;
      }
      if (!RegExp(r'^[A-Za-z ]+$').hasMatch(name)) {
        _showError('Enter valid name (only letters allowed)');
        return;
      }
      if (phone.isEmpty) {
        _showError('Phone number is required');
        return;
      }
      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
        _showError('Enter valid 10-digit mobile number (starting with 6-9)');
        return;
      }
      if (dl.isEmpty) {
        _showError('Driving License number is required');
        return;
      }
      if (!RegExp(r'^[A-Z]{2}[- ]?[0-9]{2}[- ]?[0-9]{4}[- ]?[0-9]{7}$').hasMatch(dl)) {
        _showError('Enter valid DL number (e.g., MH-12-20110012345)');
        return;
      }
      if (aadhar.isEmpty) {
        _showError('Aadhar number is required');
        return;
      }
      if (!RegExp(r'^[0-9]{12}$').hasMatch(aadhar)) {
        _showError('Enter valid 12-digit Aadhar number');
        return;
      }
      if (pan.isEmpty) {
        _showError('PAN number is required');
        return;
      }
      // if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(pan)) {
      //   _showError('Enter valid PAN number (ABCDE1234F)');
      //   return;
      // }
      if (_dob == null) {
        _showError('Please select your date of birth.');
        return;
      }
      if (_calculateAge < 18) {
        _showError('You must be at least 18 years old to register.');
        return;
      }
      if (_docFiles['Profile Photo'] == null) {
        _showError('Please upload a profile photo (selfie).');
        return;
      }
    } else if (_currentPage == 2) { // Documents
      final mandatoryDocs = ['Driving License', 'Aadhar Card'];
      for (var doc in mandatoryDocs) {
        if (_docFiles[doc] == null) {
          _showError('Please upload your $doc.');
          return;
        }
      }
    } else if (_currentPage == 3) { // Vehicle Details
      if (_plateCtrl.text.trim().isEmpty) {
        _showError('Please enter your vehicle number plate.');
        return;
      }
      if (_modelCtrl.text.trim().isEmpty) {
        _showError('Please enter your vehicle model.');
        return;
      }
      if (_yearCtrl.text.trim().isEmpty) {
        _showError('Please enter the year of manufacture.');
        return;
      }
    }
    
    if (_currentPage < 4) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = ref.read(authServiceProvider);
      final db = ref.read(databaseServiceProvider);
      final user = auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      final token = await auth.getIdToken();

      // 0. Use dev bypass if token is null or if we are targeting localhost (to avoid Firebase verification issues during dev)
      final bool isLocal = AppConfig.apiBaseUrl.toLowerCase().contains('localhost') || AppConfig.apiBaseUrl.toLowerCase().contains('127.0.0.1');
      final finalToken = isLocal ? 'dev-token-bypass' : (token ?? 'dev-token-bypass');
      debugPrint('[AUTH-DEBUG] Target: ${AppConfig.apiBaseUrl}, IsLocal: $isLocal, FinalToken: $finalToken');

      // 1. Upload Documents first
      await db.uploadDriverDocuments(
        token: finalToken,
        photoFile: _docFiles['Profile Photo'],
        aadharFile: _docFiles['Aadhar Card'],
        licenseFile: _docFiles['Driving License'],
        signatureFile: _docFiles['Signature'],
        panFile: _docFiles['PAN Card'],
        rcBookFile: _docFiles['RC Book'],
        insuranceFile: _docFiles['Insurance'],
        uid: user.uid,
      );

      // 2. Prepare Driver Model for sync (text fields)
      final driver = DriverModel(
        id: IdGenerator.generateDriverId(),
        firebaseId: user.uid,
        email: user.email ?? '',
        name: _nameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        vehicleId: _plateCtrl.text,
        dob: _dob!.toIso8601String(),
        aadharCardNumber: _aadharCtrl.text,
        drivingLicenseNumber: _licenseCtrl.text,
        panCardNumber: _panCtrl.text.toUpperCase(),
        vehicleModel: _modelCtrl.text,
        vehicleYear: _yearCtrl.text,
        vehicleNumberPlate: _plateCtrl.text,
        onboardingComplete: true,
      );

      // 3. Sync profile data
      await db.saveDriverProfile(driver, finalToken);

      // Invalidate providers to refresh the app state
      ref.invalidate(isOnboardingCompleteProvider);
      ref.invalidate(driverProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to the transglob'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Driver Onboarding'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.auth,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            label: const Text('Logout', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentPage > 0) ...[
                        GestureDetector(
                          onTap: () {
                            _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                            setState(() => _currentPage--);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.darkDivider),
                            ),
                            child: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        GestureDetector(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.darkDivider),
                            ),
                            child: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.onlineGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FleetPartner', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                          Text('Driver Registration', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Step progress
                  Row(
                    children: List.generate(5, (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentPage ? AppTheme.neonGreen : AppTheme.darkDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Step ${_currentPage + 1} of 5', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                      Text(_stepTitle(_currentPage), style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildVehicleTypeStep(),
                  _buildPersonalInfoStep(),
                  _buildDocumentUploadStep(),
                  _buildVehicleDetailsStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            // Next button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: AppTheme.darkBg)
                    : Text(
                        _currentPage == 5 ? '✓  Verify & Submit' : (_currentPage == 4 ? 'Send Verification Code' : 'Continue'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(int step) {
    return ['Vehicle Type', 'Personal Info', 'Documents', 'Vehicle Details', 'Review'][step];
  }

  Widget _buildVehicleTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Your Vehicle Type', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Select the type of vehicle you drive', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          ...VehicleType.values.map((type) {
            final isSelected = _selectedVehicle == type;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedVehicle = type;
                _selectedSubType = type.subOptions.first.name;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isSelected ? LinearGradient(colors: [type.accentColor.withValues(alpha: 0.15), type.accentColor.withValues(alpha: 0.05)]) : null,
                  color: isSelected ? null : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? type.accentColor : AppTheme.darkDivider, width: isSelected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: type.accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: Icon(type.icon, color: type.accentColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.label, style: TextStyle(color: isSelected ? AppTheme.darkTextPrimary : AppTheme.darkTextSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('${type.subOptions.length} sub-categories available', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: type.subOptions.map((opt) => GestureDetector(
                              onTap: () => setState(() { _selectedVehicle = type; _selectedSubType = opt.name; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _selectedSubType == opt.name && isSelected ? opt.color.withValues(alpha: 0.2) : AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _selectedSubType == opt.name && isSelected ? opt.color : AppTheme.darkDivider.withValues(alpha: 0.3)),
                                ),
                                child: Text(opt.name, style: TextStyle(color: _selectedSubType == opt.name && isSelected ? opt.color : AppTheme.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: type.accentColor, size: 24),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Tell us about yourself. You must be 18+.', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          
          // Only show fields that weren't captured during registration
          if (_nameCtrl.text.isEmpty) ...[
            _buildTextField('Full Name', _nameCtrl, Icons.person_outline, 
              hintText: 'Enter your full name',
              textCapitalization: TextCapitalization.words,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))]),
            const SizedBox(height: 14),
          ],
          
          _buildTextField('Phone Number', _phoneCtrl, Icons.phone_outlined, 
            hintText: 'Enter 10-digit mobile number',
            keyboardType: TextInputType.phone, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
          const SizedBox(height: 14),
          
          _buildTextField('Driving License No.', _licenseCtrl, Icons.badge_outlined,
            hintText: 'e.g. MH-12-20110012345',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-\s]')), LengthLimitingTextInputFormatter(20)]),
          const SizedBox(height: 14),
          
          if (_aadharCtrl.text.isEmpty) ...[
            _buildTextField('Aadhar Card No.', _aadharCtrl, Icons.credit_card_outlined, 
              hintText: 'Enter 12-digit Aadhar number',
              keyboardType: TextInputType.number, 
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)]),
            const SizedBox(height: 14),
          ],
          
          if (_panCtrl.text.isEmpty) ...[
            _buildTextField('PAN Card No.', _panCtrl, Icons.account_balance_wallet_outlined,
              hintText: 'Enter 10-digit PAN number',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), LengthLimitingTextInputFormatter(10)]),
            const SizedBox(height: 14),
          ],
          
          // Show summary of already provided info if any
          if (_nameCtrl.text.isNotEmpty || _aadharCtrl.text.isNotEmpty || _panCtrl.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: AppTheme.neonGreen, size: 16),
                      SizedBox(width: 8),
                      Text('Registration Info Verified', style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Basic details like Name, Aadhar, and PAN have been carried over from your registration.', 
                    style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // DOB Picker
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.darkDivider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, color: AppTheme.darkTextSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dob == null ? 'Select Date of Birth' : '${_dob!.day}/${_dob!.month}/${_dob!.year} (Age: $_calculateAge)',
                    style: TextStyle(color: _dob == null ? AppTheme.darkTextSecondary : AppTheme.darkTextPrimary),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          // Profile photo
          Center(
            child: GestureDetector(
              onTap: () => _pickImage('Profile Photo'),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.5), width: 2),
                ),
                child: _docFiles['Profile Photo'] != null
                  ? ClipOval(
                      child: Image.network(
                        _docFiles['Profile Photo']!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppTheme.neonGreen, size: 40),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppTheme.neonGreen, size: 28),
                        SizedBox(height: 4),
                        Text('Selfie', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Upload your clear photo', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload Documents', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Upload clear photos/scans', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          ..._docFiles.keys.where((k) => k != 'Profile Photo' && k != 'Signature').map((doc) {
            final uploaded = _docFiles[doc] != null;
            return GestureDetector(
              onTap: () => _pickImage(doc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: uploaded ? AppTheme.neonGreen.withValues(alpha: 0.08) : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: uploaded ? AppTheme.neonGreen.withValues(alpha: 0.4) : AppTheme.darkDivider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: uploaded ? AppTheme.neonGreen.withValues(alpha: 0.15) : AppTheme.darkCardLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(uploaded ? Icons.check_circle : Icons.upload_file, color: uploaded ? AppTheme.neonGreen : AppTheme.darkTextSecondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc, style: TextStyle(color: uploaded ? AppTheme.darkTextPrimary : AppTheme.darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(uploaded ? 'Uploaded ✓' : 'Tap to upload', style: TextStyle(color: uploaded ? AppTheme.neonGreen : AppTheme.darkTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.darkDivider, size: 20),
                  ],
                ),
              ),
            );
          }),
          
          // Signature Step
          const SizedBox(height: 12),
          const Text('Signature Upload', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage('Signature'),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _docFiles['Signature'] != null ? AppTheme.neonGreen : AppTheme.darkDivider, style: BorderStyle.solid),
              ),
              child: _docFiles['Signature'] != null
                ? Image.network(_docFiles['Signature']!.path, fit: BoxFit.contain)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined, color: AppTheme.darkTextSecondary, size: 32),
                      SizedBox(height: 8),
                      Text('Upload Signature Image', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                    ],
                  ),
            ),
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.earningsAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.earningsAmber.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.earningsAmber, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text('Verification takes up to 24 hours.', style: TextStyle(color: AppTheme.earningsAmber, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Enter your vehicle information', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _buildTextField('Number Plate', _plateCtrl, Icons.confirmation_number_outlined, hintText: 'e.g. MH 12 AB 1234'),
          const SizedBox(height: 14),
          _buildTextField('Vehicle Model', _modelCtrl, Icons.directions_car_outlined, hintText: 'e.g. Swift Dzire'),
          const SizedBox(height: 14),
          _buildTextField('Year of Manufacture', _yearCtrl, Icons.calendar_today_outlined, 
            hintText: 'e.g. 2020',
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(gradient: AppTheme.onlineGradient, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('Review & Submit', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          _buildReviewCard('Vehicle', Icons.directions_car, [
            _ReviewRow('Type', _selectedVehicle.label),
            _ReviewRow('Sub-type', _selectedSubType),
            _ReviewRow('Plate', _plateCtrl.text),
          ], _selectedVehicle.accentColor),
          const SizedBox(height: 12),
          _buildReviewCard('Personal', Icons.person, [
            _ReviewRow('Name', _nameCtrl.text),
            _ReviewRow('Age', _calculateAge.toString()),
            _ReviewRow('License', _licenseCtrl.text),
          ], AppTheme.cabBlue),
          const SizedBox(height: 12),
          _buildReviewCard('Documents', Icons.description, [
            ..._docFiles.entries.map((e) => _ReviewRow(e.key, e.value != null ? '✓ Uploaded' : '✗ Missing')),
          ], AppTheme.earningsAmber),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String title, IconData icon, List<_ReviewRow> rows, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                Text(r.value, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {String? hintText, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: AppTheme.darkTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: AppTheme.darkTextSecondary.withValues(alpha: 0.5)),
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(icon, color: AppTheme.darkTextSecondary, size: 20),
        filled: true,
        fillColor: AppTheme.darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.darkDivider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.darkDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2)),
      ),
    );
  }

  Widget _buildOTPStep() {
    final email = ref.read(authServiceProvider).currentUser?.email ?? 'your email';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Code sent to $email', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
          const SizedBox(height: 32),
          _buildTextField('Verification Code', _otpCtrl, Icons.lock_outline, 
            hintText: 'Enter 6-digit OTP',
            keyboardType: TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : () async {
                setState(() => _isSubmitting = true);
                try {
                  await ref.read(databaseServiceProvider).sendOTP(email);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification Code Resent')));
                } catch (e) {
                  _showError('Failed to resend: $e');
                } finally {
                  setState(() => _isSubmitting = false);
                }
              },
              child: const Text('Resend Code', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow {
  final String label;
  final String value;
  const _ReviewRow(this.label, this.value);
}
