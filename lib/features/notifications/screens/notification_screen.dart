// lib/features/notifications/screens/notification_screen.dart
// Design Ref: §F-08 알림 센터 — DB 기반 알림 목록 + 읽음 처리 + 선택 삭제

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/error_message.dart';
import '../../../models/notification_item.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _selectionMode = false;
  bool _isNavigating = false;
  final Set<String> _selectedIds = {};

  void _enterSelectionMode() => setState(() {
        _selectionMode = true;
        _selectedIds.clear();
      });

  void _exitSelectionMode() => setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });

  void _toggleItem(String id) => setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      });

  void _toggleAll(List<NotificationItem> all) => setState(() {
        if (_selectedIds.length == all.length) {
          _selectedIds.clear();
        } else {
          _selectedIds
            ..clear()
            ..addAll(all.map((n) => n.id));
        }
      });

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    _exitSelectionMode();
    await ref
        .read(notificationNotifierProvider.notifier)
        .deleteNotifications(ids);
  }

  Future<void> _navigateTo(NotificationItem item) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final route = switch (item.type) {
        'event_create' || 'event_update' => '/home/calendar',
        'todo_create' || 'todo_done' => '/home/todo',
        'chat' => '/home/chat',
        _ => null,
      };
      if (route == null) return;

      final activeFamily = ref.read(activeFamilyProvider);
      if (activeFamily?.id != item.familyId) {
        await ref
            .read(familyNotifierProvider.notifier)
            .switchFamily(item.familyId);
      }

      if (!mounted) return;
      GoRouter.of(context).go(route);
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final theme = ShadTheme.of(context);

    // familyId → "이모지 이름" 맵
    final familyState = ref.watch(familyNotifierProvider).valueOrNull;
    final familyLabelMap = {
      for (final f in familyState?.families ?? []) f.id: f.displayLabel
    };

    return Scaffold(
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 56, color: theme.colorScheme.mutedForeground),
                  const SizedBox(height: 12),
                  Text('알림이 없습니다',
                      style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 15)),
                ],
              ),
            );
          }

          final hasUnread = notifications.any((n) => !n.isRead);
          final allSelected = _selectedIds.length == notifications.length;

          return Column(
            children: [
              // ── 상단 액션 바 ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: theme.colorScheme.border, width: 0.5),
                  ),
                ),
                child: _selectionMode
                    ? _SelectionBar(
                        selectedCount: _selectedIds.length,
                        allSelected: allSelected,
                        onToggleAll: () => _toggleAll(notifications),
                        onDelete: _selectedIds.isNotEmpty
                            ? _deleteSelected
                            : null,
                        onCancel: _exitSelectionMode,
                      )
                    : _NormalBar(
                        hasUnread: hasUnread,
                        onMarkAllRead: () => ref
                            .read(notificationNotifierProvider.notifier)
                            .markAllRead(),
                        onSelectDelete: _enterSelectionMode,
                      ),
              ),
              // ── 알림 리스트 ──
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: theme.colorScheme.border,
                  ),
                  itemBuilder: (context, i) {
                    final item = notifications[i];
                    final isSelected = _selectedIds.contains(item.id);

                    final familyLabel = familyLabelMap[item.familyId];

                    if (_selectionMode) {
                      // 선택 모드: 체크박스 + 탭으로 선택/해제
                      return _NotificationTile(
                        item: item,
                        familyLabel: familyLabel,
                        selectionMode: true,
                        isSelected: isSelected,
                        onTap: () => _toggleItem(item.id),
                      );
                    }

                    // 일반 모드: 스와이프 삭제 + 탭 이동
                    return Slidable(
                      key: ValueKey(item.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.22,
                        children: [
                          SlidableAction(
                            onPressed: (_) => ref
                                .read(notificationNotifierProvider.notifier)
                                .deleteNotification(item.id),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline,
                            label: '삭제',
                          ),
                        ],
                      ),
                      child: _NotificationTile(
                        item: item,
                        familyLabel: familyLabel,
                        onTap: () async {
                          if (!item.isRead) {
                            ref
                                .read(notificationNotifierProvider.notifier)
                                .markRead(item.id);
                          }
                          await _navigateTo(item);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 일반 모드 상단 바 ──
class _NormalBar extends StatelessWidget {
  const _NormalBar({
    required this.hasUnread,
    required this.onMarkAllRead,
    required this.onSelectDelete,
  });
  final bool hasUnread;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSelectDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasUnread)
          TextButton.icon(
            onPressed: onMarkAllRead,
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('모두 읽음', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          ),
        TextButton.icon(
          onPressed: onSelectDelete,
          icon: const Icon(Icons.checklist, size: 16, color: Colors.red),
          label: const Text('선택 삭제',
              style: TextStyle(fontSize: 13, color: Colors.red)),
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
      ],
    );
  }
}

// ── 선택 모드 상단 바 ──
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
    required this.onDelete,
    required this.onCancel,
  });
  final int selectedCount;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback? onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 전체 선택/해제
        TextButton.icon(
          onPressed: onToggleAll,
          icon: Icon(
            allSelected
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            size: 16,
          ),
          label: Text(
            allSelected ? '전체 해제' : '전체 선택',
            style: const TextStyle(fontSize: 13),
          ),
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
        const Spacer(),
        // 선택 삭제
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
          label: Text(
            selectedCount > 0 ? '삭제 ($selectedCount)' : '삭제',
            style: TextStyle(
              fontSize: 13,
              color: onDelete != null ? Colors.red : Colors.grey,
            ),
          ),
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        ),
        // 취소
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          child: const Text('취소', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

// ── 알림 타일 ──
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    this.familyLabel,
    this.selectionMode = false,
    this.isSelected = false,
  });
  final NotificationItem item;
  final VoidCallback onTap;
  final String? familyLabel; // "🌿 가족" 형태
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final timeLabel = _formatTime(item.createdAt);
    final iconColor = item.isRead
        ? theme.colorScheme.mutedForeground
        : theme.colorScheme.primary;

    Color bgColor;
    if (isSelected) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
    } else if (!item.isRead) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.06);
    } else {
      bgColor = Colors.transparent;
    }

    return Ink(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택 모드: 체크박스, 일반 모드: 아이콘 원
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.mutedForeground,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isRead
                      ? theme.colorScheme.muted
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(_iconForType(item.type),
                    size: 18, color: iconColor),
              ),
            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.mutedForeground),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(timeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.mutedForeground)),
                      if (familyLabel != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.muted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            familyLabel!,
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.mutedForeground),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 읽지 않음 점 (일반 모드에서만)
            if (!item.isRead && !selectionMode)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'event_create' || 'event_update' => Icons.calendar_month,
        'todo_create' || 'todo_done' => Icons.check_box,
        'chat' => Icons.chat_bubble,
        'member_join' => Icons.person_add,
        _ => Icons.notifications,
      };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M월 d일', 'ko_KR').format(dt.toLocal());
  }
}
