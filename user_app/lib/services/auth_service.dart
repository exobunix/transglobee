import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Demo mode flag - set to false when you have real Firebase configured
const bool kDemoMode = false;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class MockUser {
  String? uid;
  String? displayName;
  String? email;
  String? phoneNumber;

  MockUser({
    this.uid = "demo-uid-123",
    this.displayName = "Yogesh Thakur",
    this.email = "yogesh@example.com",
    this.phoneNumber = "+91 98765 43210",
  });

  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }

  Future<void> updatePhoneNumber(String? phone) async {
    phoneNumber = phone;
  }
}

class AuthService {
  static const String _webSessionUidKey = 'web_auth_uid';
  static const String _webSessionPhoneKey = 'web_auth_phone';
  static const String _webSessionNameKey = 'web_auth_name';
  static const String _webSessionEmailKey = 'web_auth_email';
  static const String _restTokenKey = 'rest_jwt_token';
  static const String _restUserKey = 'rest_user_data';


  // Only initialize FirebaseAuth when NOT in demo mode
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final MockUser _mockUser = MockUser();
  static final StreamController<dynamic> _localAuthController =
      StreamController<dynamic>.broadcast();
  static MockUser? _localSessionUser;
  static bool _localSessionLoaded = false;
  static Future<void>? _localSessionLoadFuture;
  static String? _pendingWebPhoneNumber;
  String? _cachedRestToken;

  AuthService() {
    if (!kDemoMode) {
      _ensureLocalSessionLoaded();
    }
  }

  /// Awaits local session restoration before resolving.
  Future<void> waitForSession() {
    if (!kDemoMode) {
      return _ensureLocalSessionLoaded();
    }
    return Future.value();
  }

  FirebaseAuth get auth {
    // Disable app verification (reCAPTCHA) on web for development
    if (kIsWeb) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth;
  }

  dynamic get currentUser {
    if (kDemoMode) return _mockUser;
    if (_localSessionUser != null) return _localSessionUser;
    return auth.currentUser;
  }

  Stream<dynamic> get authStateChanges {
    if (kDemoMode) {
      return Stream.value(_mockUser);
    }

    _ensureLocalSessionLoaded();
    return Stream.multi((controller) {
      void emitCurrentState() {
        controller.add(_localSessionUser ?? auth.currentUser);
      }

      if (_localSessionLoaded) {
        emitCurrentState();
      } else {
        _ensureLocalSessionLoaded().then((_) => emitCurrentState());
      }

      final sessionSub = _localAuthController.stream.listen(controller.add);
      final firebaseSub = auth.authStateChanges().listen((user) {
        if (_localSessionUser == null) {
          controller.add(user);
        }
      });

      controller.onCancel = () async {
        await sessionSub.cancel();
        await firebaseSub.cancel();
      };
    });
  }

  Future<String?> getIdToken() async {
    if (kDemoMode) {
      return 'demo-token-for-testing';
    }

    await _ensureLocalSessionLoaded();

    final user = currentUser;

    if (user is User) {
      try {
        return await user.getIdToken().timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );
      } catch (e) {
        debugPrint('[AUTH] Failed to fetch Firebase token: $e');
        return null;
      }
    }

    if (user is MockUser) {
      final token = await getRestToken();
      return token;
    }

    return await getRestToken();
  }

  Future<String?> getRestToken() async {
    if (_cachedRestToken != null) return _cachedRestToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedRestToken = prefs.getString(_restTokenKey);
    return _cachedRestToken;
  }

  Future<void> saveRestAuth(String token, Map<String, dynamic> data) async {
    _cachedRestToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restTokenKey, token);
    await prefs.setString(_restUserKey, jsonEncode(data));
    
    // Extract user data (handle nested 'user' key if present)
    final userData = data['user'] ?? data;
    
    _localSessionUser = MockUser(
      uid: userData['id']?.toString() ?? userData['_id']?.toString() ?? userData['uid']?.toString(),
      displayName: userData['name']?.toString(),
      email: userData['email']?.toString(),
      phoneNumber: userData['mobileNumber']?.toString() ?? userData['phone']?.toString(),
    );
    _localAuthController.add(_localSessionUser);
    
    // Also sync with web session if needed to survive refreshes
    if (kIsWeb) {
       await syncWebSessionUser(
        uid: userData['id']?.toString() ?? userData['_id']?.toString(),
        displayName: userData['name'],
        email: userData['email'],
        phoneNumber: userData['mobileNumber']?.toString() ?? userData['phone']?.toString(),
      );
    }
  }

  Future<void> clearRestAuth() async {
    _cachedRestToken = null;
    _localSessionUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restTokenKey);
    await prefs.remove(_restUserKey);
    _localAuthController.add(null);
  }

  Future<Map<String, String>> buildAuthHeaders({
    bool includeContentType = true,
    Map<String, String>? extraHeaders,
  }) async {
    await _ensureLocalSessionLoaded();
    final restToken = await getRestToken();
    final firebaseToken = restToken != null ? null : await getIdToken();
    
    final token = restToken ?? firebaseToken;

    final headers = <String, String>{
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uid = currentUser?.uid?.toString();
    if (uid != null && uid.isNotEmpty) {
      headers['x-dev-uid'] = uid;
    }

    if (extraHeaders != null && extraHeaders.isNotEmpty) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }


  Future<void> _ensureLocalSessionLoaded() {
    if (_localSessionLoaded) {
      return Future.value();
    }

    _localSessionLoadFuture ??= _loadLocalSession();
    return _localSessionLoadFuture!;
  }

  Future<void> _loadLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_restTokenKey);
    final userDataString = prefs.getString(_restUserKey);

    if (token != null && userDataString != null) {
      try {
        final data = jsonDecode(userDataString);
        final userData = data['user'] ?? data;
        _localSessionUser = MockUser(
          uid: userData['id']?.toString() ?? userData['_id']?.toString() ?? userData['uid']?.toString(),
          displayName: userData['name']?.toString(),
          email: userData['email']?.toString(),
          phoneNumber: userData['mobileNumber']?.toString() ?? userData['phone']?.toString(),
        );
      } catch (e) {
        debugPrint('[AUTH] Failed to parse local session user: $e');
      }
    }

    // Fallback to web session keys if they exist and no REST user was loaded
    if (_localSessionUser == null) {
      final uid = prefs.getString(_webSessionUidKey);
      final phoneNumber = prefs.getString(_webSessionPhoneKey);

      if (uid != null && phoneNumber != null) {
        _localSessionUser = MockUser(
          uid: uid,
          displayName: prefs.getString(_webSessionNameKey),
          email: prefs.getString(_webSessionEmailKey),
          phoneNumber: phoneNumber,
        );
      }
    }

    _localSessionLoaded = true;
    _localAuthController.add(_localSessionUser ?? auth.currentUser);
  }

  Future<void> _persistWebSession(MockUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webSessionUidKey, user.uid ?? '');
    await prefs.setString(_webSessionPhoneKey, user.phoneNumber ?? '');

    if ((user.displayName ?? '').isNotEmpty) {
      await prefs.setString(_webSessionNameKey, user.displayName!);
    } else {
      await prefs.remove(_webSessionNameKey);
    }

    if ((user.email ?? '').isNotEmpty) {
      await prefs.setString(_webSessionEmailKey, user.email!);
    } else {
      await prefs.remove(_webSessionEmailKey);
    }
  }

  Future<void> syncWebSessionUser({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    if (!kIsWeb) return;
    await _ensureLocalSessionLoaded();

    final user = _localSessionUser ?? MockUser();
    if (uid != null) user.uid = uid;
    if (displayName != null) user.displayName = displayName;
    if (email != null) user.email = email;
    if (phoneNumber != null) user.phoneNumber = phoneNumber;

    _localSessionUser = user;
    await _persistWebSession(user);
    _localAuthController.add(user);
  }

  Future<void> _clearWebSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webSessionUidKey);
    await prefs.remove(_webSessionPhoneKey);
    await prefs.remove(_webSessionNameKey);
    await prefs.remove(_webSessionEmailKey);
    _localSessionUser = null;
    _localAuthController.add(null);
  }

  Future<void> _signInWebBypassUser(String phoneNumber) async {
    await _ensureLocalSessionLoaded();

    final normalizedDigits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final sessionUser = MockUser(
      uid: 'web-user-$normalizedDigits',
      phoneNumber: phoneNumber,
      displayName: _localSessionUser?.displayName,
      email: _localSessionUser?.email,
    );

    _localSessionUser = sessionUser;
    await _persistWebSession(sessionUser);
    _localAuthController.add(sessionUser);
  }

  // Phone OTP Authentication
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (kDemoMode) {
      // In demo mode, simulate OTP sent after 1 second
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('demo-verification-id', null);
      return;
    }

    // On web, Firebase phone auth requires reCAPTCHA + authorized domain.
    // Use a simulated web flow — OTP is accepted client-side, backend validates phone.
    if (kIsWeb) {
      _pendingWebPhoneNumber = phoneNumber;
      await Future.delayed(const Duration(milliseconds: 500));
      onCodeSent('web-bypass-${phoneNumber.replaceAll('+', '')}', null);
      return;
    }

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential?> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    if (kDemoMode || kIsWeb) {
      // On web, accept any 6-digit OTP — backend validates the phone registration
      if (smsCode.length == 6) {
        if (kIsWeb) {
          final digitsFromVerificationId = verificationId.replaceFirst('web-bypass-', '');
          final normalizedPhone = _pendingWebPhoneNumber ??
              (digitsFromVerificationId.isNotEmpty ? '+$digitsFromVerificationId' : null);

          if (normalizedPhone == null || normalizedPhone.isEmpty) {
            throw Exception('Phone number missing for web sign-in');
          }

          await _signInWebBypassUser(normalizedPhone);
        }
        return null;
      }
      throw Exception('Invalid OTP');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await auth.signInWithCredential(credential);
  }

  // Sign in with any credential (used for auto-verification)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await auth.signInWithCredential(credential);
  }

  // Email/Password Authentication
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await clearRestAuth();
    if (kIsWeb) {
      await _clearWebSession();
    }
    if (!kDemoMode) {
      try {
        await auth.signOut();
      } catch (e) {
        debugPrint('[AUTH] Firebase signOut error: $e');
      }
    }
  }


  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }
}
