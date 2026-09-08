import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

import '../models/user_model.dart';
import '../services/rest_api_repository.dart';

/// Notifier to manage the User Profile reactively.
class UserProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    return _fetchProfile();
  }

  /// Fetches the profile from the backend API.
  Future<UserModel?> _fetchProfile() async {
    try {
      final restRepo = ref.read(restApiRepositoryProvider);
      final response = await restRepo.getProfile();

      if (response.success && response.data != null) {
        // The backend returns { user: { ... } }
        final rawData = response.data!;
        final userData = rawData['user'] ?? rawData; 
        
        final rawRoutes = userData['assignedRoutes'] as List?;
        List<UserRoute> parsedRoutes = [];
        if (rawRoutes != null) {
          parsedRoutes = rawRoutes
              .map((r) => r is Map ? UserRoute.fromJson(Map<String, dynamic>.from(r)) : null)
              .whereType<UserRoute>()
              .toList();
        }

        return UserModel(
          id: userData['id']?.toString() ?? userData['_id']?.toString() ?? '',
          firebaseId: userData['firebaseId']?.toString() ?? userData['uid']?.toString() ?? '',
          name: userData['name']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          phoneNumber: userData['phone']?.toString() ?? userData['mobileNumber']?.toString() ?? '',
          profilePic: userData['profilePic']?.toString() ?? userData['imageUrl']?.toString(),
          assignedRoutes: parsedRoutes,
        );
      }
      
      // Fallback to local session if API fails but user is logged in
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        return UserModel(
          id: user.uid, 
          firebaseId: user.uid,
          email: user.email ?? '',
          name: user.displayName,
          phoneNumber: user.phoneNumber,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch profile via REST: $e');
      return null;
    }
  }
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }
}
final fullUserProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserModel?>(() {
  return UserProfileNotifier();
});
final userProfileProvider = Provider<AsyncValue<String>>((ref) {
  final fullProfile = ref.watch(fullUserProfileProvider);
  return fullProfile.whenData((user) => user?.name ?? 'Transglobal User');
});
