import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String category;
  final String title;
  final String body;
  final bool isRead;
  final DateTime time;

  const NotificationModel({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.isRead,
    required this.time,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      category: json['category'] ?? json['type'] ?? 'general',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      time: json['time'] != null 
          ? DateTime.parse(json['time']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  @override
  List<Object?> get props => [id, category, title, body, isRead, time];
}

class NotificationResponseModel extends Equatable {
  final int unreadCount;
  final List<NotificationModel> notifications;

  const NotificationResponseModel({
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    var list = json['notifications'] as List? ?? [];
    List<NotificationModel> notificationsList =
        list.map((i) => NotificationModel.fromJson(i)).toList();

    return NotificationResponseModel(
      unreadCount: json['unreadCount'] ?? 0,
      notifications: notificationsList,
    );
  }

  @override
  List<Object?> get props => [unreadCount, notifications];
}
