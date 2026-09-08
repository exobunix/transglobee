import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String driverId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.driverId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  bool _isRecording = false;
  int _recordSeconds = 0;
  bool _isCancelled = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initChat(widget.receiverId, widget.driverId);
      ref.read(notificationProvider.notifier).markCategoryRead('chat');
    });
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _send() {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(txt);
    _msgCtrl.clear();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!mounted) return;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _isCancelled = false;
      _dragOffset = 0;
    });
    _timer();
  }

  void _timer() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) break;
      setState(() => _recordSeconds++);
    }
  }

  void _stopRecording() {
    if (!_isRecording) return;
    final duration = _recordSeconds;
    final cancelled = _isCancelled;

    setState(() {
      _isRecording = false;
    });

    if (!cancelled && duration > 0) {
      ref.read(chatProvider.notifier).sendVoiceMessage(duration);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<ChatMessage>>(chatProvider, (previous, next) {
      if (previous != null && next.length > previous.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove default back button
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.cabBlue,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.receiverName,
                      style: const TextStyle(
                        color: AppTheme.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ID: ${widget.receiverId.substring(0, widget.receiverId.length > 8 ? 8 : widget.receiverId.length)}',
                          style: const TextStyle(
                            color: AppTheme.darkTextSecondary,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.neonGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(color: AppTheme.neonGreen, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.neonGreen, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => _ChatBubble(msg: messages[i]),
            ),
          ),

          if (!_isRecording) ...[
            _buildEmojiBar(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: ["I'm on my way", "5 min away", "Please wait", "At your location", "Running late"].map((r) =>
                  GestureDetector(
                    onTap: () { ref.read(chatProvider.notifier).sendMessage(r); Future.delayed(const Duration(milliseconds: 100), _scrollToBottom); },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.darkDivider)),
                      child: Text(r, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  )
                ).toList(),
              ),
            ),
          ],

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmojiBar() {
    final emojis = ["👍", "❤️", "😂", "🚗", "🚲", "👋", "OK", "📍"];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            ref.read(chatProvider.notifier).sendMessage(emojis[index]);
            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkDivider.withOpacity(0.5)),
            ),
            child: Text(emojis[index], style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: AppTheme.darkSurface,
      child: Row(
        children: [
          if (_isRecording) ...[
            const Icon(Icons.mic, color: AppTheme.offlineRed, size: 24),
            const SizedBox(width: 12),
            Text(
              '0:${_recordSeconds.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            Text(
              _dragOffset < -80 ? 'Release to Cancel' : 'Slide to Cancel <',
              style: TextStyle(color: _dragOffset < -80 ? AppTheme.offlineRed : AppTheme.darkTextSecondary, fontSize: 14),
            ),
            const Spacer(),
          ] else ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.darkDivider)),
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: AppTheme.darkTextPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.darkTextSecondary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            onLongPressMoveUpdate: (details) {
              setState(() {
                _dragOffset = details.localPosition.dx;
                if (_dragOffset < -100) _isCancelled = true;
              });
            },
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(_isRecording ? 18 : 14),
              decoration: BoxDecoration(
                gradient: _isRecording ? const LinearGradient(colors: [AppTheme.offlineRed, Color(0xFFFF5252)]) : AppTheme.onlineGradient,
                shape: BoxShape.circle,
                boxShadow: _isRecording ? [BoxShadow(color: AppTheme.offlineRed.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)] : [],
              ),
              child: Icon(
                _isRecording ? Icons.mic : (_msgCtrl.text.isEmpty ? Icons.mic : Icons.send),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  String _formatTime(DateTime time) {
    String hour = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    String period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    if (!msg.isDriver || msg.isDeleted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppTheme.neonGreen),
            title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppTheme.offlineRed),
            title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              ref.read(chatProvider.notifier).deleteMessage(msg.id);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(chatProvider.notifier).editMessage(msg.id, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver = msg.isDriver;
    final isVoice = msg.type == ChatMessageType.voice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showOptions(context, ref),
        child: Row(
          mainAxisAlignment: isDriver ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isDriver) ...[
              const CircleAvatar(backgroundColor: AppTheme.cabBlue, radius: 14, child: Icon(Icons.person, color: Colors.white, size: 14)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isDriver ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isDriver ? const LinearGradient(colors: [AppTheme.neonGreen, AppTheme.neonGreenDim]) : null,
                      color: isDriver ? null : AppTheme.darkCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isDriver ? 18 : 4),
                        bottomRight: Radius.circular(isDriver ? 4 : 18),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: isVoice 
                      ? _VoiceMessageBubble(msg: msg, isDriver: isDriver)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text, 
                              style: TextStyle(
                                color: isDriver ? AppTheme.darkBg : AppTheme.darkTextPrimary, 
                                fontSize: 14,
                                fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                              )
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isEdited && !msg.isDeleted)
                        Text('Edited • ', style: TextStyle(color: AppTheme.darkTextSecondary.withOpacity(0.6), fontSize: 9)),
                      Text(_formatTime(msg.time), style: TextStyle(color: AppTheme.darkTextSecondary.withOpacity(0.6), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            if (isDriver) ...[
              const SizedBox(width: 8),
              const CircleAvatar(backgroundColor: AppTheme.neonGreen, radius: 14, child: Icon(Icons.person, color: Colors.white, size: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceMessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final bool isDriver;
  const _VoiceMessageBubble({required this.msg, required this.isDriver});

  @override
  State<_VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<_VoiceMessageBubble> {
  bool _isPlaying = false;
  double _progress = 0.0;

  void _togglePlay() async {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isPlaying = true;
      _progress = 0.0;
    });

    final duration = widget.msg.durationSeconds ?? 5;
    for (int i = 0; i <= 100; i++) {
      if (!_isPlaying) break;
      await Future.delayed(Duration(milliseconds: (duration * 10)));
      setState(() => _progress = i / 100);
    }
    
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDriver ? AppTheme.darkBg : AppTheme.darkTextPrimary;
    final secondaryColor = widget.isDriver ? AppTheme.darkBg.withOpacity(0.5) : AppTheme.darkTextSecondary;

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
                    Text('0:${widget.msg.durationSeconds?.toString().padLeft(2, '0') ?? "00"}', style: TextStyle(color: secondaryColor, fontSize: 10)),
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
