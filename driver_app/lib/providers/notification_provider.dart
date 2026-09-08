import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/services/socket_service.dart';
import 'package:driver_app/services/driver_service.dart';
import 'dart:async';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category; // booking, earning, system, chat
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.time,
    this.isRead = false,
  });
}

class NotificationNotifier extends Notifier<List<AppNotification>> {
  StreamSubscription? _socketSubscription;

  @override
  List<AppNotification> build() {
    // Watch profile once and setup listener
    final profileAsync = ref.watch(driverProfileProvider);
    final myId = profileAsync.value?.id;
    
    if (myId != null) {
      _setupSocketListener(myId);
    }

    return [
      AppNotification(id: 'N1', title: 'New Booking Request', body: 'Priya Sharma wants a Sedan ride to Pari Chowk.', category: 'booking', time: DateTime.now().subtract(const Duration(minutes: 2))),
      // ... default notifications
    ];
  }

  void _setupSocketListener(String myId) {
    _socketSubscription?.cancel();
    
    // Watch socket service
    final socketService = ref.read(socketServiceProvider);
    
    _socketSubscription = socketService.messageStream.listen((data) {
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];
      final message = data['message'] ?? '';

      // If it's for us and not from us
      if (receiverId == myId && senderId != myId) {
        addNotification(AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: data['senderName'] ?? 'New Message',
          body: message,
          category: 'chat',
          time: DateTime.now(),
        ));
      }
    });
  }

  void markRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          category: n.category,
          time: n.time,
          isRead: true,
        );
      }
      return n;
    }).toList();
  }

  void markCategoryRead(String category) {
    state = state.map((n) {
      if (n.category == category) {
         return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          category: n.category,
          time: n.time,
          isRead: true,
        );
      }
      return n;
    }).toList();
  }

  void addNotification(AppNotification n) {
    state = [n, ...state];
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void markAllRead() {
    state = state.map((n) => AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      category: n.category,
      time: n.time,
      isRead: true,
    )).toList();
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider);
  return notifs.where((n) => !n.isRead).length;
});

final chatUnreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider);
  return notifs.where((n) => !n.isRead && n.category == 'chat').length;
});
