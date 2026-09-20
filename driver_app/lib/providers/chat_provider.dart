import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/utils/id_generator.dart';
import 'package:driver_app/services/socket_service.dart';
import 'package:driver_app/services/driver_service.dart';
import 'dart:async';

enum ChatMessageType { text, voice }

class ChatMessage {
  final String id;
  final String text;
  final bool isDriver;
  final DateTime time;
  final bool isTyping;
  final ChatMessageType type;
  final String? audioUrl;
  final int? durationSeconds;
  final String? senderId;
  final String? receiverId;
  final bool isEdited;
  final bool isDeleted;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isDriver,
    required this.time,
    this.isTyping = false,
    this.type = ChatMessageType.text,
    this.audioUrl,
    this.durationSeconds,
    this.senderId,
    this.receiverId,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String currentDriverId) {
    DateTime parsedTime = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final timeStr = map['timestamp'] ?? map['createdAt'];
    if (timeStr != null) {
      try {
        parsedTime = DateTime.parse(timeStr.toString()).toUtc().add(const Duration(hours: 5, minutes: 30));
      } catch (_) {}
    }

    final senderId = map['senderId']?.toString();
    final senderRole = map['senderRole']?.toString();

    return ChatMessage(
      id: map['_id'] ?? IdGenerator.generateMessageId(),
      text: map['message'] ?? '',
      isDriver: senderId == currentDriverId || senderRole == 'driver',
      time: parsedTime,
      type: map['type'] == 'voice' ? ChatMessageType.voice : ChatMessageType.text,
      durationSeconds: map['duration'], 
      senderId: senderId,
      receiverId: map['receiverId']?.toString(),
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  ChatMessage copyWith({
    String? text,
    bool? isEdited,
    bool? isDeleted,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isDriver: isDriver,
      time: time,
      isTyping: isTyping ?? this.isTyping,
      type: type,
      audioUrl: audioUrl,
      durationSeconds: durationSeconds,
      senderId: senderId,
      receiverId: receiverId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ChatNotifier extends Notifier<List<ChatMessage>> {
  StreamSubscription? _messageSubscription;
  StreamSubscription? _historySubscription;
  String? _currentReceiverId;

  @override
  List<ChatMessage> build() => [];

  void initChat(String receiverId, String driverId) {
    _currentReceiverId = receiverId;
    final socketService = ref.read(socketServiceProvider);
    
    final driverName = ref.read(driverProfileProvider).value?.name;
    socketService.connect(driverId, name: driverName);
    socketService.fetchHistory(driverId, receiverId);

    _messageSubscription?.cancel();
    _messageSubscription = socketService.messageStream.listen((data) {
      print("[CHAT-DEBUG] [DRIVER] Received message: $data");
      print("[CHAT-DEBUG] [DRIVER] Checking match: receiverId=$receiverId, driverId=$driverId");
      
      final currentDbId = ref.read(driverProfileProvider).value?.id;
      final currentFbId = ref.read(driverProfileProvider).value?.firebaseId;
      
      bool isMe(String? id) => id != null && (id == currentDbId || id == currentFbId || id == driverId);
      bool isOther(String? id) => id != null && id == receiverId;

      final msgSender = data['senderId']?.toString();
      final msgReceiver = data['receiverId']?.toString();

      if ((isOther(msgSender) && isMe(msgReceiver)) ||
          (isMe(msgSender) && isOther(msgReceiver))) {
        print("[CHAT-DEBUG] [DRIVER] Message MATCHED context. Adding to state.");
        final newMsg = ChatMessage.fromMap(data, driverId);
        
        // Find if we have an optimistic version of this message
        final index = state.indexWhere((m) {
          if (m.id == newMsg.id) return true;
          if (m.id.startsWith('temp-') && m.text == newMsg.text) return true;
          return false;
        });

        if (index != -1) {
          final newState = List<ChatMessage>.from(state);
          newState[index] = newMsg;
          state = newState;
        } else {
          state = [...state, newMsg];
        }
      } else {
        print("[CHAT-DEBUG] [DRIVER] Message did NOT match context.");
      }
    });

    _historySubscription?.cancel();
    _historySubscription = socketService.historyStream.listen((history) {
       final messages = history.map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m), driverId)).toList();
       state = messages;
    });

    // Handle Edit/Delete Socket Updates - Clear old listeners first
    socketService.socket?.off("message_edited");
    socketService.socket?.off("message_deleted");

    socketService.socket?.on("message_edited", (data) {
      final msgId = data['messageId'];
      final newText = data['newMessage'];
      state = state.map((m) => m.id == msgId ? m.copyWith(text: newText, isEdited: true) : m).toList();
    });

    socketService.socket?.on("message_deleted", (data) {
      final msgId = data['messageId'];
      state = state.map((m) => m.id == msgId ? m.copyWith(text: "This message was deleted", isDeleted: true) : m).toList();
    });
  }

  void sendMessage(String text) {
    if (_currentReceiverId == null) return;
    final driverProfile = ref.read(driverProfileProvider).value;
    if (driverProfile == null) return;

    final driverId = driverProfile.id;
    final socketService = ref.read(socketServiceProvider);

    socketService.sendMessage(
      driverId,
      _currentReceiverId!,
      text,
      senderName: driverProfile.name,
    );

    // Optimistic Update
    final msg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isDriver: true,
      time: DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)),
      senderId: driverId,
      receiverId: _currentReceiverId,
    );
    state = [...state, msg];
  }

  void sendVoiceMessage(int durationSeconds) {
    if (_currentReceiverId == null) return;
    final driverProfile = ref.read(driverProfileProvider).value;
    if (driverProfile == null) return;

    final driverId = driverProfile.id;
    final socketService = ref.read(socketServiceProvider);

    socketService.socket?.emit("send_message", {
      "senderId": driverId,
      "receiverId": _currentReceiverId!,
      "message": "Voice Message (${durationSeconds}s)",
      "type": "voice",
      "duration": durationSeconds,
      "senderRole": "driver",
      "senderName": driverProfile.name
    });

    // Optimistic Update
    final msg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: "Voice Message (${durationSeconds}s)",
      isDriver: true,
      time: DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)),
      type: ChatMessageType.voice,
      durationSeconds: durationSeconds,
      senderId: driverId,
      receiverId: _currentReceiverId,
    );
    state = [...state, msg];
  }

  void editMessage(String messageId, String newText) {
    if (_currentReceiverId == null) return;
    ref.read(socketServiceProvider).socket?.emit("edit_message", {
      "messageId": messageId,
      "newMessage": newText,
      "receiverId": _currentReceiverId,
    });
    // Optimistic Update
    state = state.map((m) => m.id == messageId ? ChatMessage(
      id: m.id, text: newText, isDriver: m.isDriver, time: m.time, isEdited: true, senderId: m.senderId, receiverId: m.receiverId,
    ) : m).toList();
  }

  void deleteMessage(String messageId) {
    if (_currentReceiverId == null) return;
    ref.read(socketServiceProvider).socket?.emit("delete_message", {
      "messageId": messageId,
      "receiverId": _currentReceiverId,
    });
    // Optimistic Update
    state = state.map((m) => m.id == messageId ? ChatMessage(
      id: m.id, text: "This message was deleted", isDriver: m.isDriver, time: m.time, isDeleted: true, senderId: m.senderId, receiverId: m.receiverId,
    ) : m).toList();
  }

  void clearChat() {
    state = [];
    _currentReceiverId = null;
  }

  void _cancelSubscriptions() {
    _messageSubscription?.cancel();
    _historySubscription?.cancel();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);
