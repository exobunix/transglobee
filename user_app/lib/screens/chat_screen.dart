import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? senderId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.senderId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = ref.read(authServiceProvider);
      await authService.waitForSession();
      if (!mounted) return;

      final userProfile = ref.read(fullUserProfileProvider).asData?.value;
      final userId = userProfile?.id;
      final firebaseId = authService.currentUser?.uid;
      
      final effectiveUserId = (widget.senderId != null && widget.senderId!.isNotEmpty)
          ? widget.senderId
          : ((userId != null && userId.isNotEmpty) ? userId : firebaseId);
      
      if (effectiveUserId != null) {
        ref.read(chatProvider.notifier).initChat(widget.receiverId, effectiveUserId);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    unawaited(ref.read(chatProvider.notifier).sendMessage(txt));
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    
    // Auto-scroll on new messages
    ref.listen<List<ChatMessage>>(chatProvider, (prev, next) {
      if (prev != null && next.length > prev.length) {
        _scrollToBottom();
      }
    });

    // Re-init chat if MongoDB ID becomes available later
    ref.listen(fullUserProfileProvider, (prev, next) {
      final oldId = prev?.asData?.value?.id;
      final newId = next.asData?.value?.id;
      if (newId != null && newId.isNotEmpty && oldId != newId) {
        _initChat();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Driver', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _ChatBubble(msg: msg);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: context.theme.primaryColor),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;

  const _ChatBubble({required this.msg});
  
  String _formatTime(DateTime time) {
    String hour = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    String period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser ? context.theme.primaryColor : context.theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 16),
          ),
          border: msg.isUser ? null : Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.type == ChatMessageType.voice)
               _VoiceMessageBubble(msg: msg, isUser: msg.isUser)
            else
              Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.white : context.colors.textPrimary,
                  fontSize: 14,
                  fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.time),
              style: TextStyle(
                color: msg.isUser ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceMessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final bool isUser;
  const _VoiceMessageBubble({required this.msg, required this.isUser});

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  bool _isPlaying = false;
  double _progress = 0.0;

  void _togglePlay() async {
    if (_isPlaying) {
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    if (mounted) {
      setState(() {
        _isPlaying = true;
        _progress = 0.0;
      });
    }

    final duration = 5; 
    for (int i = 0; i <= 100; i++) {
      if (!_isPlaying || !mounted) break;
      await Future.delayed(Duration(milliseconds: (duration * 10)));
      if (mounted) setState(() => _progress = i / 100);
    }
    
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUser ? Colors.white : Theme.of(context).primaryColor;
    final secondaryColor = widget.isUser ? Colors.white70 : Colors.grey;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: color, size: 32),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(height: 3, decoration: BoxDecoration(color: secondaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0:05', style: TextStyle(color: secondaryColor, fontSize: 10)),
                    Icon(Icons.mic, size: 12, color: secondaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
