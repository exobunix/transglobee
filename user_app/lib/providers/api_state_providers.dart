import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:user_app/services/auth_service.dart';
import '../models/booking_model.dart';
import '../models/wallet_model.dart';
import '../models/shuttle_model.dart';
import '../models/notification_model.dart';
import '../services/rest_api_repository.dart';
import 'user_provider.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final RestApiRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.login(email: email, password: password);
      if (res.success) {
        state = state.copyWith(isLoading: false, user: res.data ?? {});
        _ref.invalidate(fullUserProfileProvider);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _repo.register(name: name, email: email, phone: phone, password: password);
      if (res.success) {
        state = state.copyWith(isLoading: false, user: res.data ?? {});
        _ref.invalidate(fullUserProfileProvider);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout(String deviceId, {required AuthService authService}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.logout(deviceId);
      await authService.signOut();
      _ref.invalidate(fullUserProfileProvider);
      state = AuthState();
    } catch (e) {
      // Still sign out locally even if API fails
      await authService.signOut();
      _ref.invalidate(fullUserProfileProvider);
      state = AuthState();
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(restApiRepositoryProvider), ref);
});

// --- BOOKING PROVIDER ---

class BookingState {
  final bool isLoading;
  final List<BookingModel> history;
  final BookingModel? activeBooking;
  final String? error;

  BookingState({this.isLoading = false, this.history = const [], this.activeBooking, this.error});

  BookingState copyWith({bool? isLoading, List<BookingModel>? history, BookingModel? activeBooking, String? error}) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      history: history ?? this.history,
      activeBooking: activeBooking ?? this.activeBooking,
      error: error,
    );
  }
}

class BookingController extends StateNotifier<BookingState> {
  final RestApiRepository _repo;

  BookingController(this._repo) : super(BookingState());

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.getBookingHistory();
    if (res.success) {
      state = state.copyWith(isLoading: false, history: res.data ?? []);
    } else {
      state = state.copyWith(isLoading: false, error: res.message);
    }
  }

  Future<BookingModel?> createBooking(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.createBooking(data);
    state = state.copyWith(isLoading: false);
    if (res.success) {
      state = state.copyWith(activeBooking: res.data);
      return res.data;
    } else {
      state = state.copyWith(error: res.message);
      return null;
    }
  }

  Future<void> getDetails(String id) async {
    final res = await _repo.getBookingDetails(id);
    if (res.success) {
      state = state.copyWith(activeBooking: res.data);
    }
  }
}

final bookingControllerProvider = StateNotifierProvider<BookingController, BookingState>((ref) {
  return BookingController(ref.watch(restApiRepositoryProvider));
});

// --- WALLET PROVIDER ---

class WalletNotifier extends StateNotifier<UserWalletState> {
  final RestApiRepository _repo;

  WalletNotifier(this._repo) : super(const UserWalletState(balance: 0, transactions: []));

  Future<void> refreshBalance() async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.getWalletBalance();
    if (res.success && res.data != null) {
      state = res.data!.copyWith(isLoading: false, transactions: state.transactions);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.getWalletHistory();
    if (res.success) {
      state = state.copyWith(isLoading: false, transactions: res.data ?? []);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> topup(double amount, String method) async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.topupWallet(amount, method);
    if (res.success) {
      await refreshBalance();
      await fetchHistory();
      return true;
    }
    state = state.copyWith(isLoading: false);
    return false;
  }
}

final walletControllerProvider = StateNotifierProvider<WalletNotifier, UserWalletState>((ref) {
  return WalletNotifier(ref.watch(restApiRepositoryProvider));
});

// --- SHUTTLE PROVIDER ---

class ShuttleState {
  final bool isLoading;
  final List<ShuttleRoute> routes;
  final ShuttleTracking? tracking;

  ShuttleState({this.isLoading = false, this.routes = const [], this.tracking});

  ShuttleState copyWith({bool? isLoading, List<ShuttleRoute>? routes, ShuttleTracking? tracking}) {
    return ShuttleState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      tracking: tracking ?? this.tracking,
    );
  }
}

class ShuttleController extends StateNotifier<ShuttleState> {
  final RestApiRepository _repo;

  ShuttleController(this._repo) : super(ShuttleState());

  Future<void> fetchRoutes() async {
    state = state.copyWith(isLoading: true);
    final res = await _repo.getShuttleRoutes();
    state = state.copyWith(isLoading: false, routes: res.data ?? []);
  }

  Future<void> track(String id) async {
    final res = await _repo.trackShuttle(id);
    if (res.success) {
      state = state.copyWith(tracking: res.data);
    }
  }
}

final shuttleControllerProvider = StateNotifierProvider<ShuttleController, ShuttleState>((ref) {
  return ShuttleController(ref.watch(restApiRepositoryProvider));
});

// --- NOTIFICATION PROVIDER ---

final notificationListProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (authService.currentUser == null) {
    return [];
  }
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getNotifications();
  return res.data ?? [];
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationListProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final bannersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getCMSContent('banner');
  return res.data ?? [];
});

final featuredBannersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getCMSContent('featured_banner');
  return res.data ?? [];
});

final offersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getCMSContent('offer');
  return res.data ?? [];
});

final couponsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getCMSContent('coupon');
  return res.data ?? [];
});

final recentBookingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getBookingHistory(limit: 3);
  return res.data ?? [];
});

final bookingsHistoryProvider = FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final repo = ref.watch(restApiRepositoryProvider);
  final res = await repo.getBookingHistory(limit: 50);
  return res.data ?? [];
});

