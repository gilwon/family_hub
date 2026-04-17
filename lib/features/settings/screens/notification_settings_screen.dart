// lib/features/settings/screens/notification_settings_screen.dart
// Design Ref: §F-08 알림 설정 — 그룹별 알림 토글 + DND 설정

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/utils/error_message.dart';
import '../../../models/notification_settings.dart';
import '../../../providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정'), elevation: 0),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});
  final NotificationSettings settings;

  void _update(WidgetRef ref, NotificationSettings updated) {
    ref.read(notificationSettingsNotifierProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 마스터 스위치
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '알림 받기',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '모든 알림을 켜거나 끕니다',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              ShadSwitch(
                value: settings.enabled,
                onChanged: (v) => _update(ref, settings.copyWith(enabled: v)),
              ),
            ],
          ),
        ),
        Divider(color: theme.colorScheme.border),

        // 알림 항목
        _SectionHeader(label: '알림 항목'),
        _SwitchRow(
          icon: Icons.calendar_month_outlined,
          label: '일정',
          value: settings.calendar && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(calendar: v)),
        ),
        _SwitchRow(
          icon: Icons.check_box_outlined,
          label: '할 일',
          value: settings.todo && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(todo: v)),
        ),
        _SwitchRow(
          icon: Icons.chat_bubble_outline,
          label: '채팅',
          value: settings.chat && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(chat: v)),
        ),
        _SwitchRow(
          icon: Icons.group_outlined,
          label: '멤버 변경',
          value: settings.memberChange && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(memberChange: v)),
        ),
        Divider(color: theme.colorScheme.border),

        // 일정 미리 알림
        _SectionHeader(label: '일정 미리 알림'),
        _SwitchRow(
          icon: Icons.alarm_outlined,
          label: '일정 시작 전 알림',
          value: settings.eventReminder && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(eventReminder: v)),
        ),
        if (settings.eventReminder && settings.enabled)
          _ReminderMinutesTile(
            value: settings.reminderMinutesBefore,
            onChanged: (v) =>
                _update(ref, settings.copyWith(reminderMinutesBefore: v ?? 30)),
          ),
        Divider(color: theme.colorScheme.border),

        // 방해금지 시간
        _SectionHeader(label: '방해금지 시간'),
        _SwitchRow(
          icon: Icons.bedtime_outlined,
          label: '방해금지 모드',
          subtitle: settings.dndEnabled
              ? '${settings.dndStart} ~ ${settings.dndEnd}'
              : null,
          value: settings.dndEnabled && settings.enabled,
          enabled: settings.enabled,
          onChanged: (v) => _update(ref, settings.copyWith(dndEnabled: v)),
        ),
        if (settings.dndEnabled && settings.enabled) ...[
          _TimeTile(
            label: '시작 시간',
            time: settings.dndStart,
            onChanged: (t) => _update(ref, settings.copyWith(dndStart: t)),
          ),
          _TimeTile(
            label: '종료 시간',
            time: settings.dndEnd,
            onChanged: (t) => _update(ref, settings.copyWith(dndEnd: t)),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.mutedForeground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          ShadSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _ReminderMinutesTile extends StatelessWidget {
  const _ReminderMinutesTile({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int?> onChanged;

  static const _options = [
    (10, '10분 전'),
    (30, '30분 전'),
    (60, '1시간 전'),
    (120, '2시간 전'),
  ];

  String get _label => switch (value) {
        10 => '10분 전',
        30 => '30분 전',
        60 => '1시간 전',
        120 => '2시간 전',
        _ => '$value분 전',
      };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 20, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 12),
          const Expanded(
              child: Text('미리 알림 시간', style: TextStyle(fontSize: 14))),
          GestureDetector(
            onTap: () => showCupertinoModalPopup<void>(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                title: const Text('미리 알림 시간'),
                actions: _options
                    .map(
                      (opt) => CupertinoActionSheetAction(
                        isDefaultAction: opt.$1 == value,
                        onPressed: () {
                          onChanged(opt.$1);
                          Navigator.pop(ctx);
                        },
                        child: Text(opt.$2),
                      ),
                    )
                    .toList(),
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 18, color: theme.colorScheme.mutedForeground),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile(
      {required this.label,
      required this.time,
      required this.onChanged});
  final String label;
  final String time; // "HH:mm"
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: GestureDetector(
        onTap: () async {
          final parts = time.split(':');
          var tempDt = DateTime(
            2000,
            1,
            1,
            int.tryParse(parts[0]) ?? 0,
            int.tryParse(parts[1]) ?? 0,
          );
          String? result;

          await showCupertinoModalPopup<void>(
            context: context,
            builder: (ctx) => Container(
              height: 320,
              color: CupertinoColors.systemBackground.resolveFrom(ctx),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('취소'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      CupertinoButton(
                        child: const Text('확인'),
                        onPressed: () {
                          final hh =
                              tempDt.hour.toString().padLeft(2, '0');
                          final mm =
                              tempDt.minute.toString().padLeft(2, '0');
                          result = '$hh:$mm';
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: tempDt,
                      use24hFormat: true,
                      minuteInterval: 30,
                      onDateTimeChanged: (dt) => tempDt = dt,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (result != null) onChanged(result!);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}
