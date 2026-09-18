import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/driver_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _showEmailForm = true; // default to true so fields are immediately visible
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _errorMessage;

  void _clearFormFields() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _aadharController.clear();
    _panController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    super.dispose();
  }

  bool _isValid() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    final emailValid = _isValidEmail(email);
    final passwordValid = password.length >= 6;
    
    if (!emailValid || !passwordValid) {
      debugPrint("Validation debug - Email valid: $emailValid ('$email'), Password valid: $passwordValid (length: ${password.length})");
      return false;
    }

    if (!_isLogin) {
      final name = _nameController.text.trim();
      final aadhar = _aadharController.text.trim();
      final pan = _panController.text.trim();
      
      final nameValid = name.isNotEmpty;
      final aadharValid = _isValidAadhar(aadhar);
      final panValid = _isValidPan(pan);
      
      if (!nameValid || !aadharValid || !panValid) {
        debugPrint("Validation debug - Name valid: $nameValid ('$name'), Aadhar valid: $aadharValid ('$aadhar'), PAN valid: $panValid ('$pan')");
        return false;
      }
    }
    return true;
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _isValidAadhar(String value) {
    return RegExp(r'^\d{12}$').hasMatch(value.trim());
  }

  bool _isValidPan(String value) {
    // Keep PAN validation practical for onboarding: accept any 10-char
    // uppercase alphanumeric value to avoid blocking legitimate entries.
    return RegExp(r'^[A-Z0-9]{10}$').hasMatch(value.trim().toUpperCase());
  }

  // Handles both login and registration using Firebase Auth
  Future<void> _submit() async {
    if (!_isValid()) {
      setState(() {
        _errorMessage = _isLogin
            ? 'Please enter a valid email and password (at least 6 characters).'
            : 'Please enter a valid name, email, 12-digit Aadhaar, 10-character PAN, and password.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authCtrl = ref.read(authControllerProvider.notifier);
      final dbService = ref.read(databaseServiceProvider);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (!_isLogin) {
        final exists = await dbService.checkEmailAvailability(email);
        if (exists) {
          setState(() {
            _isLogin = true;
            _showEmailForm = true;
            _errorMessage = "Email registered previously. Please enter your password to login.";
          });
          return;
        }
      }

      bool success = false;
      if (_isLogin) {
        success = await authCtrl.login(email, password);
      } else {
        success = await authCtrl.register({
          'name': _nameController.text.trim(),
          'email': email,
          'password': password,
          'aadharCard': _aadharController.text.trim(),
          'panCard': _panController.text.trim().toUpperCase(),
        });
      }

      if (!success) {
        final errorMsg = ref.read(authControllerProvider).error;
        setState(() {
          _errorMessage = errorMsg ?? (_isLogin ? 'Login failed.' : 'Registration failed.');
        });
      }

      if (success && mounted) {
        // Clear cached profile data for the previous user before reading onboarding state
        ref.invalidate(driverProfileProvider);
        ref.invalidate(isOnboardingCompleteProvider);

        if (_isLogin) {
          // An existing driver logging in goes straight to the main app
          Navigator.pushReplacementNamed(context, AppRouter.home);
        } else {
          // New registration: check onboarding status
          final authService = ref.read(authServiceProvider);
          final token = await authService.getIdToken();
          final user = authService.currentUser;
          
          final isComplete = await dbService.isOnboardingComplete(
            user.uid, 
            token ?? ''
          );
          
          if (mounted) {
            if (isComplete) {
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final userCredential = await authService.signInWithGoogle();
      final token = await authService.getIdToken();

      if (mounted) {
        final user = userCredential.user;
        if (user != null) {
          // Clear cached profile data for the previous user before reading onboarding state
          ref.invalidate(driverProfileProvider);
          ref.invalidate(isOnboardingCompleteProvider);

          // Save Google user to backend database
          final isComplete = await dbService.saveDriverToBackend(user, token);

          if (mounted) {
            if (isComplete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Welcome back, ${user.displayName ?? 'Driver'}! 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

 
 
  // ── Facebook Sign-In ───────────────────────────────────────────────────────
  Future<void> _signInWithFacebook() async {
    setState(() {
      _isFacebookLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final userCredential = await authService.signInWithFacebook();
      final token = await authService.getIdToken();

      if (mounted) {
        final user = userCredential.user;
        if (user != null) {
          // Clear cached profile data for the previous user before reading onboarding state
          ref.invalidate(driverProfileProvider);
          ref.invalidate(isOnboardingCompleteProvider);

          // Save Facebook user to backend database
          final isComplete = await dbService.saveDriverToBackend(user, token);

          if (mounted) {
            if (isComplete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Welcome back, ${user.displayName ?? 'Driver'}! 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading || _isGoogleLoading || _isFacebookLoading;
    final errorMessage = authState.error ?? _errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -110,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.08),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.darkDivider.withOpacity(0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 42,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Logo ───────────────────────────────────────────────────────
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppTheme.onlineGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.directions_car,
                                  color: Colors.white, size: 40),
                            ),
                          ),
                          const SizedBox(height: 28),

                          Center(
                            child: Text(
                              _isLogin ? 'Welcome Back!' : 'Join the Fleet',
                              style: const TextStyle(
                                color: AppTheme.darkTextPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              _isLogin
                                  ? 'Login to continue your journey'
                                  : 'Register and start earning today',
                              style: const TextStyle(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Login / Sign Up Toggle ─────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _tab(
                                    'Login',
                                    _isLogin,
                                    () => setState(() {
                                          _clearFormFields();
                                          _isLogin = true;
                                          _showEmailForm = true;
                                        })),
                                _tab(
                                    'Sign Up',
                                    !_isLogin,
                                    () => setState(() {
                                          _clearFormFields();
                                          _isLogin = false;
                                          _showEmailForm = false;
                                        })),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Sign Up CTA (not login tab) ────────────────────────────────
                          if (!_isLogin) ...[
                            Column(
                              children: [
                                _buildTextField(
                                  'Full Name',
                                  _nameController,
                                  Icons.person_outline,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Email',
                                  _emailController,
                                  Icons.email_outlined,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Aadhar Number',
                                  _aadharController,
                                  Icons.credit_card_outlined,
                                  keyboardType: TextInputType.number,
                                  maxLength: 12,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(12),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'PAN Card Number',
                                  _panController,
                                  Icons.badge_outlined,
                                  keyboardType: TextInputType.text,
                                  maxLength: 10,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9]')),
                                    LengthLimitingTextInputFormatter(10),
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) => newValue.copyWith(
                                        text: newValue.text.toUpperCase(),
                                        selection: newValue.selection,
                                      ),
                                    ),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Aadhaar: 12 digits, PAN: 10 chars (e.g. ABCDE1234F)',
                                    style: TextStyle(
                                      color: AppTheme.darkTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Password',
                                  _passwordController,
                                  Icons.lock_outline,
                                  isPassword: true,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? () {}
                                        : (!_isValid() ? null : _submit),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.neonGreen,
                                      foregroundColor: AppTheme.darkBg,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      disabledBackgroundColor:
                                          AppTheme.darkDivider,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: AppTheme.darkBg,
                                                strokeWidth: 2))
                                        : const Text('CREATE ACCOUNT',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.darkDivider)),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('OR',
                                          style: TextStyle(
                                              color: AppTheme.darkTextSecondary,
                                              fontSize: 12)),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: AppTheme.darkDivider)),
                                  ],
                                ),
                                // const SizedBox(height: 20),
                                // SizedBox(
                                //   width: double.infinity,
                                //   height: 56,
                                //   child: OutlinedButton(
                                //     onPressed: _isGoogleLoading
                                //         ? null
                                //         : _signInWithGoogle,
                                //     style: OutlinedButton.styleFrom(
                                //       side: const BorderSide(
                                //           color: AppTheme.neonGreen,
                                //           width: 1.5),
                                //       backgroundColor: AppTheme.darkSurface,
                                //       shape: RoundedRectangleBorder(
                                //           borderRadius:
                                //               BorderRadius.circular(16)),
                                //     ),
                                //     child: _isGoogleLoading
                                //         ? const SizedBox(
                                //             height: 20,
                                //             width: 20,
                                //             child: CircularProgressIndicator(
                                //                 color: AppTheme.neonGreen,
                                //                 strokeWidth: 2))
                                //         : Row(
                                //             mainAxisAlignment:
                                //                 MainAxisAlignment.center,
                                //             children: [
                                //               _googleIcon(),
                                //               const SizedBox(width: 12),
                                //               const Text(
                                //                 'CONTINUE WITH GOOGLE',
                                //                 style: TextStyle(
                                //                     color: AppTheme.neonGreen,
                                //                     fontWeight: FontWeight.w800,
                                //                     fontSize: 14),
                                //               ),
                                //             ],
                                //           ),
                                //   ),
                                // ),
                             
                              ],
                            ),
                          ],

                          // ── Email Form (animated, shown when _showEmailForm = true) ────
                          AnimatedCrossFade(
                            crossFadeState: (_isLogin && _showEmailForm)
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 300),
                            firstChild: Column(
                              children: [
                                _buildTextField(
                                  'Email',
                                  _emailController,
                                  Icons.email_outlined,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Password',
                                  _passwordController,
                                  Icons.lock_outline,
                                  isPassword: true,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 8),
                                // Align(
                                //   alignment: Alignment.centerRight,
                                //   child: TextButton(
                                //     onPressed: () {},
                                //     child: const Text('Forgot Password?',
                                //         style: TextStyle(
                                //             color: AppTheme.neonGreen)),
                                //   ),
                                // ),
                                // const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? () {}
                                        : (!_isValid() ? null : _submit),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.neonGreen,
                                      foregroundColor: AppTheme.darkBg,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      disabledBackgroundColor:
                                          AppTheme.darkDivider,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: AppTheme.darkBg,
                                                strokeWidth: 2))
                                        : const Text('LOGIN',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                            secondChild: const SizedBox.shrink(),
                          ),

                          // ── Error Message ──────────────────────────────────────────────
                          if (errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.red.shade700.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(errorMessage,
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Divider ────────────────────────────────────────────────────
                          if (_isLogin) ...[
                            const Row(
                              children: [
                                Expanded(
                                    child:
                                        Divider(color: AppTheme.darkDivider)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR',
                                      style: TextStyle(
                                          color: AppTheme.darkTextSecondary,
                                          fontSize: 12)),
                                ),
                                Expanded(
                                    child:
                                        Divider(color: AppTheme.darkDivider)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Google Sign-In Button ──────────────────────────────────
                            // SizedBox(
                            //   width: double.infinity,
                            //   height: 56,
                            //   child: OutlinedButton(
                            //     onPressed:
                            //         _isGoogleLoading ? null : _signInWithGoogle,
                            //     style: OutlinedButton.styleFrom(
                            //       side: BorderSide(
                            //           color:
                            //               AppTheme.darkDivider.withOpacity(0.6),
                            //           width: 1.5),
                            //       backgroundColor: AppTheme.darkSurface,
                            //       shape: RoundedRectangleBorder(
                            //           borderRadius: BorderRadius.circular(16)),
                            //     ),
                            //     child: _isGoogleLoading
                            //         ? const SizedBox(
                            //             height: 20,
                            //             width: 20,
                            //             child: CircularProgressIndicator(
                            //                 color: AppTheme.neonGreen,
                            //                 strokeWidth: 2))
                            //         : Row(
                            //             mainAxisAlignment:
                            //                 MainAxisAlignment.center,
                            //             children: [
                            //               _googleIcon(),
                            //               const SizedBox(width: 12),
                            //               const Text(
                            //                 'Continue with Google',
                            //                 style: TextStyle(
                            //                   color: AppTheme.darkTextPrimary,
                            //                   fontSize: 15,
                            //                   fontWeight: FontWeight.w600,
                            //                 ),
                            //               ),
                            //             ],
                            //           ),
                            //   ),
                            // ),
                            
                            const SizedBox(height: 14),

                            // ── Continue with Email Button (toggle) ────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () => setState(
                                    () => _showEmailForm = !_showEmailForm),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: _showEmailForm
                                          ? AppTheme.neonGreen.withOpacity(0.6)
                                          : AppTheme.darkDivider
                                              .withOpacity(0.6),
                                      width: 1.5),
                                  backgroundColor: _showEmailForm
                                      ? AppTheme.neonGreen.withOpacity(0.08)
                                      : AppTheme.darkSurface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _showEmailForm
                                          ? Icons.keyboard_arrow_up
                                          : Icons.email_outlined,
                                      color: _showEmailForm
                                          ? AppTheme.neonGreen
                                          : AppTheme.darkTextPrimary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _showEmailForm
                                          ? 'Hide Email Form'
                                          : 'Continue with Email',
                                      style: TextStyle(
                                        color: _showEmailForm
                                            ? AppTheme.neonGreen
                                            : AppTheme.darkTextPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Other social buttons ───────────────────────────────────
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children: [
                            //     _socialButton(Icons.apple, () {}),
                            //     const SizedBox(width: 16),
                            //     _socialButton(
                            //       Icons.facebook,
                            //       _isFacebookLoading
                            //           ? null
                            //           : _signInWithFacebook,
                            //       isLoading: _isFacebookLoading,
                            //     ),
                            //   ],
                            // ),
                            // const SizedBox(height: 32),
                     
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.darkBg : AppTheme.darkTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.darkTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(icon, color: AppTheme.darkTextSecondary),
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback? onTap,
      {bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkDivider),
        ),
        child: isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.darkTextPrimary))
            : Icon(icon, color: AppTheme.darkTextPrimary, size: 28),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
