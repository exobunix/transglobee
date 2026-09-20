import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';

enum ChatMessageType { text, voice }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final ChatMessageType type;
  final String? senderId;
  final String? receiverId;
  final bool isEdited;
  final bool isDeleted;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.type = ChatMessageType.text,
    this.senderId,
    this.receiverId,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String currentUserId) {
    DateTime parsedTime = DateTime.now();
    final timeStr = map['timestamp'] ?? map['createdAt'];
    if (timeStr != null) {
      try {
        parsedTime = DateTime.parse(timeStr.toString());
      } catch (_) {}
    }

    final senderId = map['senderId']?.toString();
    final senderRole = map['senderRole']?.toString();

    return ChatMessage(
      id: map['_id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: map['message'] ?? '',
      isUser: senderId == currentUserId || senderRole == 'user',
      time: parsedTime,
      type: map['type'] == 'voice' ? ChatMessageType.voice : ChatMessageType.text,
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
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      time: time,
      type: type,
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

  void initChat(String receiverId, String userId) {
    _currentReceiverId = receiverId;
    final socketService = ref.read(socketServiceProvider);
    
    final userName = ref.read(userProfileProvider).value;
    socketService.connect(userId, name: userName);
    socketService.fetchHistory(userId, receiverId);

    _messageSubscription?.cancel();
    _messageSubscription = socketService.messageStream.listen((data) {
      print("[CHAT-DEBUG] [USER] Received message: $data");
      print("[CHAT-DEBUG] [USER] Checking match: receiverId=$receiverId, userId=$userId");

      final currentDbId = ref.read(fullUserProfileProvider).value?.id;
      final currentFbId = ref.read(authServiceProvider).currentUser?.uid;
      
      bool isMe(String? id) => id != null && (id == currentDbId || id == currentFbId || id == userId);
      bool isOther(String? id) => id != null && id == receiverId;

      final msgSender = data['senderId']?.toString();
      final msgReceiver = data['receiverId']?.toString();
      
      if ((isOther(msgSender) && isMe(msgReceiver)) ||
          (isMe(msgSender) && isOther(msgReceiver))) {
        print("[CHAT-DEBUG] [USER] Message MATCHED context. Adding to state.");
        final newMsg = ChatMessage.fromMap(data, userId);
        
        final index = state.indexWhere((m) => m.id == newMsg.id || (m.id.startsWith('temp-') && m.text == newMsg.text));

        if (index != -1) {
          final newState = List<ChatMessage>.from(state);
          newState[index] = newMsg;
          state = newState;
        } else {
          state = [...state, newMsg];
        }
      } else {
        print("[CHAT-DEBUG] [USER] Message did NOT match context.");
      }
    });

    _historySubscription?.cancel();
    _historySubscription = socketService.historyStream.listen((history) {
       final messages = history.map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m), userId)).toList();
       state = messages;
    });

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

  Future<void> sendMessage(String text) async {
    if (_currentReceiverId == null) return;
    
    final userProfile = ref.read(fullUserProfileProvider).value;
    final userId = userProfile?.id; // This is the MongoDB _id
    final userName = userProfile?.name ?? 'User';
    
    // Fallback to Firebase if MongoDB ID is missing
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final effectiveUserId = (userId != null && userId.isNotEmpty) 
        ? userId 
        : authService.currentUser?.uid;

    if (effectiveUserId == null) return;

    ref.read(socketServiceProvider).sendMessage(
      effectiveUserId,
      _currentReceiverId!,
      text,
      senderName: userName,
      senderRole: 'user',
    );

    final msg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      time: DateTime.now(),
      senderId: effectiveUserId,
      receiverId: _currentReceiverId,
    );
    state = [...state, msg];
  }

  void clearChat() {
    state = [];
    _currentReceiverId = null;
    _messageSubscription?.cancel();
    _historySubscription?.cancel();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);
