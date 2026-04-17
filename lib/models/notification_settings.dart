// lib/models/notification_settings.dart
// Design Ref: §2.1 Model — family_members.notification_settings JSONB

class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.calendar = true,
    this.todo = true,
    this.chat = true,
    this.memberChange = true,
    this.dndEnabled = false,
    this.dndStart = '23:00',
    this.dndEnd = '07:00',
    this.eventReminder = true,
    this.reminderMinutesBefore = 30,
  });

  final bool enabled;
  final bool calendar;
  final bool todo;
  final bool chat;
  final bool memberChange;
  final bool dndEnabled;
  final String dndStart; // "HH:mm"
  final String dndEnd;
  final bool eventReminder;
  final int reminderMinutesBefore;

  static const defaultSettings = NotificationSettings();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      calendar: json['calendar'] as bool? ?? true,
      todo: json['todo'] as bool? ?? true,
      chat: json['chat'] as bool? ?? true,
      memberChange: json['memberChange'] as bool? ?? true,
      dndEnabled: json['dndEnabled'] as bool? ?? false,
      dndStart: json['dndStart'] as String? ?? '23:00',
      dndEnd: json['dndEnd'] as String? ?? '07:00',
      eventReminder: json['eventReminder'] as bool? ?? true,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'calendar': calendar,
        'todo': todo,
        'chat': chat,
        'memberChange': memberChange,
        'dndEnabled': dndEnabled,
        'dndStart': dndStart,
        'dndEnd': dndEnd,
        'eventReminder': eventReminder,
        'reminderMinutesBefore': reminderMinutesBefore,
      };

  NotificationSettings copyWith({
    bool? enabled,
    bool? calendar,
    bool? todo,
    bool? chat,
    bool? memberChange,
    bool? dndEnabled,
    String? dndStart,
    String? dndEnd,
    bool? eventReminder,
    int? reminderMinutesBefore,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        calendar: calendar ?? this.calendar,
        todo: todo ?? this.todo,
        chat: chat ?? this.chat,
        memberChange: memberChange ?? this.memberChange,
        dndEnabled: dndEnabled ?? this.dndEnabled,
        dndStart: dndStart ?? this.dndStart,
        dndEnd: dndEnd ?? this.dndEnd,
        eventReminder: eventReminder ?? this.eventReminder,
        reminderMinutesBefore:
            reminderMinutesBefore ?? this.reminderMinutesBefore,
      );
}
