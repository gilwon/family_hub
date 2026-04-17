// lib/features/calendar/screens/event_detail_screen.dart
// Design Ref: §F-03 일정 상세 + 수정/삭제

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../models/calendar_event.dart';
import '../../../providers/event_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.mutedForeground;

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/calendar/event/${event.id}/edit', extra: event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, theme),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 제목 헤더
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_note, color: primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 상세 정보 카드
          ShadCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // 날짜
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: '날짜',
                  value:
                      '${event.date.year}년 ${event.date.month}월 ${event.date.day}일',
                  iconColor: primary,
                ),
                if (event.time != null) ...[
                  Divider(height: 1, color: theme.colorScheme.border),
                  _DetailRow(
                    icon: Icons.access_time_outlined,
                    label: '시간',
                    value: event.time!,
                    iconColor: primary,
                  ),
                ],
                if (event.recurrence != null) ...[
                  Divider(height: 1, color: theme.colorScheme.border),
                  _DetailRow(
                    icon: Icons.repeat_outlined,
                    label: '반복',
                    value: switch (event.recurrence!.type) {
                      'daily' => '매일',
                      'weekly' => '매주',
                      'monthly' => '매월',
                      _ => event.recurrence!.type,
                    },
                    iconColor: primary,
                  ),
                ],
              ],
            ),
          ),

          if (event.memo != null && event.memo!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ShadCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_outlined, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Text(
                        '메모',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.memo!,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 수정 버튼
          ShadButton.outline(
            width: double.infinity,
            onPressed: () =>
                context.push('/calendar/event/${event.id}/edit', extra: event),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, size: 16),
                SizedBox(width: 6),
                Text('일정 수정'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 삭제 버튼
          ShadButton.destructive(
            width: double.infinity,
            onPressed: () => _confirmDelete(context, ref, theme),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 16),
                SizedBox(width: 6),
                Text('일정 삭제'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ShadThemeData theme) {
    showShadDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('일정 삭제'),
        description: Text('"${event.title}" 일정을 삭제하시겠습니까?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(eventNotifierProvider.notifier)
                  .deleteEvent(event.id);
              if (context.mounted) context.pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).colorScheme.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
