// lib/models/calendar_event.dart
// Design Ref: §2.1 Model 클래스 설계

class RecurrenceRule {
  const RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.endDate,
  });

  final String type; // 'daily' | 'weekly' | 'monthly'
  final int interval;
  final DateTime? endDate;

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
        type: json['type'] as String,
        interval: (json['interval'] as num?)?.toInt() ?? 1,
        endDate: json['end_date'] != null
            ? DateTime.parse(json['end_date'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'interval': interval,
        'end_date': endDate?.toIso8601String().substring(0, 10),
      };
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.familyId,
    required this.createdBy,
    required this.title,
    required this.date,
    this.time,
    this.memo,
    this.recurrence,
    required this.createdAt,
  });

  final String id;
  final String familyId;
  final String createdBy;
  final String title;
  final DateTime date;
  final String? time; // "09:00"
  final String? memo;
  final RecurrenceRule? recurrence;
  final DateTime createdAt;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        createdBy: json['created_by'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        time: json['time'] as String?,
        memo: json['memo'] as String?,
        recurrence: json['recurrence'] != null
            ? RecurrenceRule.fromJson(
                json['recurrence'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'created_by': createdBy,
        'title': title,
        'date': date.toIso8601String().substring(0, 10),
        'time': time,
        'memo': memo,
        'recurrence': recurrence?.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  CalendarEvent copyWith({
    String? title,
    DateTime? date,
    String? time,
    String? memo,
    RecurrenceRule? recurrence,
  }) =>
      CalendarEvent(
        id: id,
        familyId: familyId,
        createdBy: createdBy,
        title: title ?? this.title,
        date: date ?? this.date,
        time: time ?? this.time,
        memo: memo ?? this.memo,
        recurrence: recurrence ?? this.recurrence,
        createdAt: createdAt,
      );
}
