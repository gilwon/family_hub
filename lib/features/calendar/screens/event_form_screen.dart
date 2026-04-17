// lib/features/calendar/screens/event_form_screen.dart
// Design Ref: §F-03 일정 CRUD — 생성/수정 폼

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/utils/error_message.dart';
import '../../../models/calendar_event.dart';
import '../../../providers/event_provider.dart';
import '../widgets/calendar_builders_helper.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.initialDate, this.event});
  final DateTime? initialDate;
  final CalendarEvent? event;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  String? _recurrenceType;
  bool _isLoading = false;
  late CalendarStyle _calStyle;
  late CalendarBuilders _calBuilders;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _memoController = TextEditingController(text: event?.memo ?? '');
    _selectedDate = event?.date ?? widget.initialDate ?? DateTime.now();
    _recurrenceType = event?.recurrence?.type;

    if (event?.time != null) {
      final parts = event!.time!.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shadTheme = ShadTheme.of(context);
    _calStyle = buildThemeCalendarStyle(
      primary: shadTheme.colorScheme.primary,
      primaryFg: shadTheme.colorScheme.primaryForeground,
    );
    _calBuilders = buildKoreanWeekendBuilders(
      defaultFg: shadTheme.colorScheme.foreground,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final mutedColor = ShadTheme.of(context).colorScheme.muted;
    final shadBg = ShadTheme.of(context).colorScheme.background;

    DateTime tempDay = _selectedDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: shadBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mutedColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  locale: 'ko_KR',
                  focusedDay: tempDay,
                  selectedDayPredicate: (d) => isSameDay(d, tempDay),
                  onDaySelected: (selected, _) =>
                      setModal(() => tempDay = selected),
                  calendarFormat: CalendarFormat.month,
                  headerStyle:
                      const HeaderStyle(formatButtonVisible: false),
                  calendarStyle: _calStyle,
                  calendarBuilders: _calBuilders,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ShadButton.outline(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShadButton(
                        onPressed: () => Navigator.pop(ctx, tempDay),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickRecurrence() async {
    FocusScope.of(context).unfocus();
    const options = [
      (null, '반복 없음'),
      ('daily', '매일'),
      ('weekly', '매주'),
      ('monthly', '매월'),
    ];
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('반복'),
        actions: options
            .map(
              (opt) => CupertinoActionSheetAction(
                isDefaultAction: opt.$1 == _recurrenceType,
                onPressed: () {
                  setState(() => _recurrenceType = opt.$1);
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
    );
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final init = _selectedTime ?? TimeOfDay.now();
    const interval = 5;
    final roundedMinute = (init.minute ~/ interval) * interval;
    var tempDt = DateTime(2000, 1, 1, init.hour, roundedMinute);
    TimeOfDay? result;

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
                    result = TimeOfDay(
                        hour: tempDt.hour, minute: tempDt.minute);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: tempDt,
                use24hFormat: false,
                minuteInterval: 5,
                onDateTimeChanged: (dt) => tempDt = dt,
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) setState(() => _selectedTime = result);
  }

  String? _timeString() {
    if (_selectedTime == null) return null;
    final h = _selectedTime!.hour.toString().padLeft(2, '0');
    final m = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final recurrence = _recurrenceType != null
          ? RecurrenceRule(type: _recurrenceType!)
          : null;

      final memo = _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim();
      if (isEditing) {
        await ref.read(eventNotifierProvider.notifier).updateEvent(
              widget.event!.id,
              title: _titleController.text.trim(),
              date: _selectedDate,
              time: _timeString(),
              memo: memo,
              recurrence: recurrence,
              clearRecurrence: _recurrenceType == null,
            );
      } else {
        await ref.read(eventNotifierProvider.notifier).createEvent(
              title: _titleController.text.trim(),
              date: _selectedDate,
              time: _timeString(),
              memo: memo,
              recurrence: recurrence,
            );
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('저장 실패'),
          description: Text(friendlyError(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '일정 수정' : '새 일정'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton(
              size: ShadButtonSize.sm,
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 제목
                  ShadInputFormField(
                    id: 'title',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    label: const Text('일정 제목'),
                    placeholder: const Text('일정 제목을 입력하세요'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.event_note, size: 16),
                    ),
                    autofocus: !isEditing,
                    validator: (v) {
                      if (v.trim().isEmpty) return '제목을 입력해주세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 날짜 · 시간 카드
                  ShadCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: theme.colorScheme.foreground,
                          ),
                          title: Text(
                            '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              const Icon(Icons.chevron_right, size: 18),
                          onTap: _pickDate,
                        ),
                        Divider(height: 1, color: theme.colorScheme.border),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: Icon(
                            Icons.access_time,
                            size: 18,
                            color: theme.colorScheme.foreground,
                          ),
                          title: Text(
                            _selectedTime != null ? _timeString()! : '시간 없음',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedTime != null
                                  ? theme.colorScheme.foreground
                                  : theme.colorScheme.mutedForeground,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedTime != null)
                                IconButton(
                                  icon:
                                      const Icon(Icons.clear, size: 16),
                                  onPressed: () =>
                                      setState(() => _selectedTime = null),
                                  visualDensity: VisualDensity.compact,
                                ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 반복
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '반복',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickRecurrence,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.colorScheme.border),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                switch (_recurrenceType) {
                                  'daily' => '매일',
                                  'weekly' => '매주',
                                  'monthly' => '매월',
                                  _ => '반복 없음',
                                },
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: theme.colorScheme.mutedForeground),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 메모
                  ShadInputFormField(
                    id: 'memo',
                    controller: _memoController,
                    textInputAction: TextInputAction.done,
                    label: const Text('메모 (선택)'),
                    placeholder: const Text('추가 메모를 입력하세요'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.notes, size: 16),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _submit(),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ShadButton(
            width: double.infinity,
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditing ? '일정 수정' : '일정 저장'),
          ),
        ),
      ),
    );
  }
}
