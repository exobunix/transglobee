import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegistrationFlow extends ConsumerStatefulWidget {
  const RegistrationFlow({super.key});

  @override
  ConsumerState<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends ConsumerState<RegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  // Step 1: Details
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Step 2: Docs
  bool _aadharUploaded = false;
  bool _panUploaded = false;
  bool _dlUploaded = false;

  // Step 3: Identity
  bool _photoUploaded = false;
  bool _signatureDone = false;

  // Step 4: OTP
  final _phoneOtpController = TextEditingController();
  final _emailOtpController = TextEditingController();
  final bool _phoneVerified = false;
  final bool _emailVerified = false;
  
  // Files for upload
  PlatformFile? _aadharFile;
  PlatformFile? _panFile;
  PlatformFile? _dlFile;
  XFile? _profileFile;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneOtpController.dispose();
    _emailOtpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      // Final submission
      _finishRegistration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  void _finishRegistration() async {
    // Demo finish
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context); // Close loader
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary),
            onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep,
          ),
          title: Text(
            'Step ${_currentStep + 1} of 4',
            style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? AppTheme.neonGreen : AppTheme.darkDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Details(),
                  _buildStep2Documents(),
                  _buildStep3Identity(),
                  _buildStep4Verification(),
                ],
              ),
            ),
  
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isStepValid() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: AppTheme.darkDivider,
                  ),
                  child: Text(
                    _currentStep == 3 ? 'VERIFY & FINISH' : 'CONTINUE',
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

  bool _isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool _isValidMobile(String mobile) => RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile);
  bool _isValidName(String name) => RegExp(r'^[A-Za-z ]+$').hasMatch(name);
  bool _isValidPassword(String password) => password.length >= 8;

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _isValidName(_nameController.text) && 
               _isValidMobile(_mobileController.text) && 
               _isValidEmail(_emailController.text) && 
               _isValidPassword(_passwordController.text);
      case 1:
        return _aadharUploaded && _panUploaded && _dlUploaded;
      case 2:
        return _photoUploaded && _signatureDone;
      case 3:
        return _phoneOtpController.text.length == 4 && _emailOtpController.text.length == 4;
      default:
        return false;
    }
  }

  Widget _buildStep1Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Provide your contact and security information', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          _buildTextField(
            'Full Name', 
            _nameController, 
            Icons.person_outline,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
            errorText: _nameController.text.isNotEmpty && !_isValidName(_nameController.text) ? 'Enter at least 3 alphabets' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Mobile Number', 
            _mobileController, 
            Icons.phone_android, 
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            errorText: _mobileController.text.isNotEmpty && !_isValidMobile(_mobileController.text) ? 'Enter a valid 10-digit number' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Email Address', 
            _emailController, 
            Icons.email_outlined, 
            keyboardType: TextInputType.emailAddress,
            errorText: _emailController.text.isNotEmpty && !_isValidEmail(_emailController.text) ? 'Enter a valid email address' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Create Password', 
            _passwordController, 
            Icons.lock_outline, 
            isPassword: true,
            errorText: _passwordController.text.isNotEmpty && !_isValidPassword(_passwordController.text) ? 'Password must be at least 8 characters' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Documents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Document Upload', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Upload scan copies of your official documents', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          _docUploadCard('Aadhar Card', _aadharUploaded, _aadharFile, () => _pickFile('Aadhar Card', (file) => setState(() { _aadharUploaded = true; _aadharFile = file; }))),
          const SizedBox(height: 16),
          _docUploadCard('PAN Card', _panUploaded, _panFile, () => _pickFile('PAN Card', (file) => setState(() { _panUploaded = true; _panFile = file; }))),
          const SizedBox(height: 16),
          _docUploadCard('Driving License', _dlUploaded, _dlFile, () => _pickFile('Driving License', (file) => setState(() { _dlUploaded = true; _dlFile = file; }))),
        ],
      ),
    );
  }

  Widget _buildStep3Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Identity', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Upload your photo and digital signature', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () => _pickImage('Profile Photo', (file) => setState(() { _photoUploaded = true; _profileFile = file; })),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _photoUploaded ? AppTheme.neonGreen : AppTheme.darkDivider, width: 2),
                ),
                child: _photoUploaded && _profileFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: kIsWeb 
                        ? Image.network(_profileFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_profileFile!.path), fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppTheme.darkTextSecondary, size: 32),
                        SizedBox(height: 4),
                        Text('Photo', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                      ],
                    ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text('Digital Signature', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _signatureDone = true),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _signatureDone ? AppTheme.neonGreen : AppTheme.darkDivider, width: 2),
              ),
              child: _signatureDone 
                ? const Center(child: Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 48))
                : const Center(child: Text('Tap to Sign', style: TextStyle(color: AppTheme.darkTextSecondary))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Verification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Verify your account with dual OTPs', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          _otpVerificationCard('Mobile Number', _mobileController.text, _phoneOtpController, _phoneVerified),
          const SizedBox(height: 24),
          _otpVerificationCard('Email Address', _emailController.text, _emailOtpController, _emailVerified),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {
    bool isPassword = false, 
    TextInputType? keyboardType, 
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppTheme.darkTextPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
            prefixIcon: Icon(icon, color: AppTheme.darkTextSecondary),
            filled: true,
            fillColor: AppTheme.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide(color: errorText != null ? AppTheme.offlineRed : Colors.transparent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide(color: errorText != null ? AppTheme.offlineRed : Colors.transparent, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: BorderSide(color: errorText != null ? AppTheme.offlineRed : AppTheme.neonGreen, width: 1.5),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText,
              style: const TextStyle(color: AppTheme.offlineRed, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _docUploadCard(String title, bool isUploaded, PlatformFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUploaded ? AppTheme.neonGreen : AppTheme.darkDivider, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUploaded ? AppTheme.neonGreen.withValues(alpha: 0.1) : AppTheme.darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isUploaded ? AppTheme.neonGreen.withValues(alpha: 0.2) : Colors.transparent),
              ),
              child: isUploaded && file != null && (file.extension == 'jpg' || file.extension == 'png' || file.extension == 'jpeg')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb 
                      ? Image.memory(file.bytes!, fit: BoxFit.cover)
                      : Image.file(File(file.path!), fit: BoxFit.cover),
                  )
                : Icon(
                    isUploaded ? Icons.file_present : Icons.upload_file,
                    color: isUploaded ? AppTheme.neonGreen : AppTheme.darkTextSecondary,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w600)),
                  Text(
                    isUploaded ? (file?.name ?? 'Document Selected') : 'Tap to select from Desktop',
                    style: TextStyle(color: isUploaded ? AppTheme.neonGreen : AppTheme.darkTextSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUploaded) const Icon(Icons.check_circle, color: AppTheme.neonGreen),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(String docTitle, Function(PlatformFile) onFilePicked) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'png', 'jpeg'],
        withData: kIsWeb,
      );
      
      if (result != null && result.files.isNotEmpty) {
        onFilePicked(result.files.first);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$docTitle added!"),
              backgroundColor: AppTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error picking file. Please ensure permissions are granted."),
            backgroundColor: AppTheme.offlineRed,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(String docTitle, Function(XFile) onFilePicked) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (image != null) {
        onFilePicked(image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$docTitle selected successfully!"),
              backgroundColor: AppTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking $docTitle. Please try again."),
            backgroundColor: AppTheme.offlineRed,
          ),
        );
      }
    }
  }

  Widget _otpVerificationCard(String type, String value, TextEditingController controller, bool isVerified) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
              TextButton(onPressed: () {}, child: const Text('Resend OTP', style: TextStyle(color: AppTheme.neonGreen, fontSize: 12))),
            ],
          ),
          Text(value, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkDivider),
                ),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (v) {
                    if (v.length == 4) setState(() {});
                  },
                  style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
