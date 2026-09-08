import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/id_generator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'database_service.dart';
import '../core/config.dart';
import '../core/network/secure_storage.dart';

// Demo mode flag - set to false when you have real Firebase configured
// Google Sign-In always uses real Firebase (bypasses demo mode)
const bool kDemoMode = false;

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.currentUser;
  print('[ONBOARD-DEBUG] Initializing status check for user: ${user?.uid}');
  if (user == null) {
    print('[ONBOARD-DEBUG] No user found. Defaulting to false.');
    return false;
  }

  final token = await authService.getIdToken();
  print(
      '[ONBOARD-DEBUG] Token retrieved (is null: ${token == null}). Checking backend...');
  final res = await dbService.isOnboardingComplete(
      user.uid, token ?? 'dev-token-bypass');
  print('[ONBOARD-DEBUG] Backend status check completed: $res');
  return res;
});

class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  MockUser({required this.uid, this.email, this.displayName, this.photoURL});
}

class AuthService {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email'],
  );

  static final MockUser _mockUser = MockUser(
    uid: IdGenerator.generateDriverId(),
    email: 'driver@rideshare.com',
    displayName: 'Driver User',
    photoURL: null,
  );

  MockUser? _localUser;
  late final StreamController<dynamic> _authStateController;

  AuthService() {
    _authStateController = StreamController<dynamic>.broadcast(
      onListen: () => _authStateController.add(currentUser),
    );
    // 1. Initialize local storage check
    _initializeLocalAuth();

    // 2. Listen for future Firebase changes
    auth.authStateChanges().listen((user) {
      _authStateController.add(user ?? _localUser);
    });
  }

  Future<void> _initializeLocalAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');

      if (isLoggedIn && token != null && userData != null) {
        final data = json.decode(userData);
        _localUser = MockUser(
          uid: data['id'] ?? data['_id'] ?? data['uid'] ?? '',
          email: data['email'],
          displayName: data['name'],
        );
        // Only broadcast if Firebase hasn't already found a user
        if (auth.currentUser == null) {
          _authStateController.add(_localUser);
        }
      } else if (auth.currentUser == null) {
        _authStateController.add(null);
      }
    } catch (e) {
      debugPrint('Error initializing local auth: $e');
      if (auth.currentUser == null) _authStateController.add(null);
    }
  }

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    // Enable reCAPTCHA bypass for testing in debug mode on Web
    if (kIsWeb && kDebugMode) {
      _auth!.setSettings(appVerificationDisabledForTesting: true);
    }
    return _auth!;
  }

  dynamic get currentUser {
    if (kDemoMode) return _mockUser;
    // Prefer Firebase user if available, otherwise return local custom user
    return auth.currentUser ?? _localUser;
  }

  Stream<dynamic> get authStateChanges =>
      _authStateController.stream.distinct((prev, next) {
        // Basic comparison to prevent flickering
        if (prev == null && next == null) return true;
        if (prev != null && next != null) {
          final prevId = (prev is User) ? prev.uid : (prev as MockUser).uid;
          final nextId = (next is User) ? next.uid : (next as MockUser).uid;
          return prevId == nextId;
        }
        return false;
      });

  Future<String?> getIdToken() async {
    if (kDemoMode) return 'demo-token-for-testing';

    // 1. Prefer Firebase token when user is signed in.
    final user = auth.currentUser;
    if (user != null) {
      try {
        return await user.getIdToken().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[AUTH] Firebase token fetch failed, trying local token: $e');
      }
    }

    // 2. Fallback to locally saved JWT (custom REST login flow).
    final prefs = await SharedPreferences.getInstance();
    final localToken = prefs.getString('auth_token');
    if (localToken != null && localToken.isNotEmpty) {
      return localToken;
    }
    return null;
  }

  // --- REST AUTH HELPERS ---
  static const String _restTokenKey = 'auth_token';
  static const String _restUserKey = 'user_data';

  Future<void> saveRestAuth(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restTokenKey, token);
    await prefs.setString(_restUserKey, jsonEncode(userData));
    await prefs.setBool('is_logged_in', true);
    
    // Update local user state
    _localUser = MockUser(
      uid: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
      displayName: userData['name']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
    );
    _authStateController.add(_localUser);
  }

  Future<void> clearRestAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restTokenKey);
    await prefs.remove(_restUserKey);
    _localUser = null;
    _authStateController.add(null);
  }

  Future<Map<String, String>> buildAuthHeaders({
    bool includeContentType = true,
  }) async {
    final token = await getIdToken();
    return {
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Save login state
  Future<void> _persistLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  /// Signs in with Google and returns the Firebase [UserCredential].
  /// Works regardless of [kDemoMode] since it always opens a real OAuth flow.
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw Exception('Failed to obtain Google authentication tokens.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // ─── Facebook Sign-In ──────────────────────────────────────────────────────
  Future<UserCredential> signInWithFacebook() async {
    // Step 1 - Trigger Facebook login
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status == LoginStatus.success) {
      if (result.accessToken == null) {
        throw Exception('Facebook access token is null.');
      }

      // Create a Firebase credential
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Sign into Firebase
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      await _persistLoginState(true);
      return cred;
    } else if (result.status == LoginStatus.cancelled) {
      throw Exception('Facebook login was cancelled by the user.');
    } else {
      throw Exception('Facebook login failed: ${result.message}');
    }
  }

  // ─── Phone OTP Authentication ──────────────────────────────────────────────
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent('demo-verification-id', null);
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

  Future<dynamic> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    if (kDemoMode) {
      if (smsCode.length == 6) {
        await _persistLoginState(true);
        return _mockUser;
      }
      throw Exception('Invalid OTP');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // Sign in with any credential (used for auto-verification)
  Future<dynamic> signInWithCredential(AuthCredential credential) async {
    final cred = await auth.signInWithCredential(credential);
    await _persistLoginState(true);
    return cred;
  }

  // ─── Email / Password Authentication ──────────────────────────────────────
  Future<dynamic> signInWithEmail(String email, String password) async {
    if (kDemoMode) {
      await Future.delayed(const Duration(seconds: 1));
      await _persistLoginState(true);
      return _mockUser;
    }
    final cred = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistLoginState(true);
    return cred;
  }

  Future<dynamic> signUpWithEmail(String email, String password) async {
    if (kDemoMode) {
      await _persistLoginState(true);
      return _mockUser;
    }
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _persistLoginState(true);
    return cred;
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } on MissingPluginException {
      // Facebook plugin may not be registered in some release/device builds.
    } catch (_) {
      // Non-fatal logout provider error; continue clearing local session.
    }
    if (!kDemoMode) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    await _persistLoginState(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await SecureStorageService.clearAll();
    _localUser = null;
    _authStateController.add(null);
  }

  Future<void> resetPassword(String email) async {
    if (!kDemoMode) {
      await auth.sendPasswordResetEmail(email: email);
    }
  }

  // Check if session exists in local storage
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // ─── Custom Backend Auth ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> signUpCustom({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
  }) async {
    try {
      final response =
          await _signUpApi(name, email, password, aadharCard, panCard);
      if (response['success']) {
        await _persistLoginState(true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token'] ?? '');

        // Save user data and update state
        final userData = response['user'];
        await prefs.setString('user_data', json.encode(userData));
        _localUser = MockUser(
          uid: userData['id'] ?? userData['_id'] ?? '',
          email: userData['email'],
          displayName: userData['name'],
        );
        _authStateController.add(_localUser);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInCustom(
      String email, String password) async {
    try {
      final response = await _signInApi(email, password);
      if (response['success']) {
        await _persistLoginState(true);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['token']);

        // Save user data and update state
        final userData = response['user'];
        await prefs.setString('user_data', json.encode(userData));
        _localUser = MockUser(
          uid: userData['id'] ?? userData['_id'] ?? '',
          email: userData['email'],
          displayName: userData['name'],
        );
        _authStateController.add(_localUser);
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _signUpApi(String name, String email,
      String password, String aadhar, String pan) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/register');
    final response = await _post(url, {
      'name': name,
      'email': email,
      'password': password,
      'aadharCard': aadhar,
      'panCard': pan,
    });
    return response;
  }

  Future<Map<String, dynamic>> _signInApi(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/driver/login');
    final response = await _post(url, {
      'email': email,
      'password': password,
    });
    return response;
  }

  Future<Map<String, dynamic>> _post(Uri url, Map<String, dynamic> body) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    final data = json.decode(response.body);
    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'message': data['message'],
      'token': data['token'],
      'user': data['driver'] ?? data['user'],
    };
  }
}
