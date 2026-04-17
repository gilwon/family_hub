// lib/features/chat/screens/chat_screen.dart
// Design Ref: §F-06 채팅 — 실시간 메시지 + 페이지네이션 + 이미지 전송
// Plan SC-3: 메시지 목록 + 전송 입력창 + 읽음 처리

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/utils/error_message.dart';
import '../../../models/chat_message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/family_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱 포그라운드 복귀 시 읽음 처리
    if (state == AppLifecycleState.resumed) {
      ref.read(chatNotifierProvider.notifier).markCurrentRead();
    }
  }

  void _onScroll() {
    // 목록 끝(오래된 메시지 방향) 도달 시 추가 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();
    try {
      await ref.read(chatNotifierProvider.notifier).sendText(text);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final familyId = ref.read(activeFamilyProvider)?.id;
    if (familyId == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(chatNotifierProvider.notifier)
          .sendImage(familyId, File(picked.path));
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('전송 실패'),
            description: Text('이미지 전송에 실패했습니다'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatNotifierProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(friendlyError(e))),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      '첫 메시지를 보내보세요!',
                      style: TextStyle(
                          color: ShadTheme.of(context).colorScheme.mutedForeground),
                    ),
                  );
                }

                // 최신 메시지가 앞(index 0) — 역순 ListView로 자연스럽게 아래에 표시
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;

                    // 날짜 구분선: 이전 메시지와 날짜 다를 때
                    final showDateSeparator = i == messages.length - 1 ||
                        !isSameDay(msg.createdAt, messages[i + 1].createdAt);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(date: msg.createdAt),
                        _MessageBubble(
                          message: msg,
                          isMe: isMe,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 입력창
          _InputBar(
            controller: _textController,
            isSending: _isSending,
            onSendText: _sendText,
            onPickImage: _pickAndSendImage,
          ),
        ],
      ),
    );
  }

}

// --- 날짜 구분선 ---

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: ShadTheme.of(context).colorScheme.mutedForeground),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// --- 메시지 버블 ---

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
  });
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final mutedColor = ShadTheme.of(context).colorScheme.mutedForeground;
    final timeStyle = TextStyle(fontSize: 10, color: mutedColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(
              name: message.senderName,
              avatarUrl: message.senderAvatarUrl,
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe && message.senderName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(
                    message.senderName!,
                    style: TextStyle(fontSize: 11, color: mutedColor),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: Text(timeLabel, style: timeStyle),
                    ),
                  _BubbleContent(message: message, isMe: isMe),
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(timeLabel, style: timeStyle),
                    ),
                ],
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    final bgColor = isMe
        ? shadTheme.colorScheme.primary
        : shadTheme.colorScheme.secondary;
    final textColor = isMe
        ? shadTheme.colorScheme.primaryForeground
        : shadTheme.colorScheme.secondaryForeground;

    if (message.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.imageUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context2, err, stack) => const Icon(Icons.broken_image),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : null,
            bottomLeft: !isMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 15),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.name, this.avatarUrl});
  final String? name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }
    final initial =
        (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';
    final shadTheme = ShadTheme.of(context);
    return CircleAvatar(
      radius: 16,
      backgroundColor: shadTheme.colorScheme.muted,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 12,
          color: shadTheme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

// --- 입력창 ---

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSendText,
    required this.onPickImage,
  });
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSendText;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: shadTheme.colorScheme.background,
          border: Border(top: BorderSide(color: shadTheme.colorScheme.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_outlined),
              tooltip: '이미지 첨부',
              onPressed: isSending ? null : onPickImage,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
            isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded),
                    tooltip: '전송',
                    onPressed: onSendText,
                  ),
          ],
        ),
      ),
    );
  }
}
