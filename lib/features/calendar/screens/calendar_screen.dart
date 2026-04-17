// lib/features/calendar/screens/calendar_screen.dart
// Design Ref: §F-03 캘린더 — table_calendar 월간 뷰 + Realtime 동기화
// Plan SC-2: 구성원 일정 즉시 공유

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/utils/error_message.dart';
import '../../../models/calendar_event.dart';
import '../../../providers/event_provider.dart';
import '../../../providers/family_provider.dart';
import '../widgets/calendar_builders_helper.dart';
import '../widgets/event_marker.dart';
import '../widgets/member_filter_bar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  late CalendarStyle _calendarStyle;
  late CalendarBuilders<CalendarEvent> _calendarBuilders;

  void _goToToday() {
    final today = DateTime.now();
    setState(() => _selectedDay = today);
    ref.read(focusedMonthProvider.notifier).setMonth(today);
  }

  Widget _headerTitle(BuildContext context, DateTime day) {
    const monthLabels = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    final theme = ShadTheme.of(context);
    final today = DateTime.now();
    final isToday = day.year == today.year && day.month == today.month;

    return Row(
      children: [
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${day.year}년 ${monthLabels[day.month - 1]}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: isToday ? null : _goToToday,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: isToday
                ? theme.colorScheme.mutedForeground
                : theme.colorScheme.primary,
          ),
          child: const Text('오늘', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shadTheme = ShadTheme.of(context);
    final primary = shadTheme.colorScheme.primary;
    final primaryFg = shadTheme.colorScheme.primaryForeground;
    final defaultFg = shadTheme.colorScheme.foreground;
    _calendarStyle = buildThemeCalendarStyle(primary: primary, primaryFg: primaryFg);
    _calendarBuilders = buildKoreanWeekendBuilders<CalendarEvent>(
      defaultFg: defaultFg,
      headerTitleBuilder: _headerTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventNotifierProvider);
    final focusedMonth = ref.watch(focusedMonthProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    // Design Ref: §5.3/5.4/5.5 — 파생 providers 사용으로 build() 간소화
    final memberColors = ref.watch(familyMemberColorMapProvider);
    final eventMap = ref.watch(monthlyEventMapProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);

    final members = membersAsync.valueOrNull ?? [];

    final selectedEvents = filteredEvents
        .where((e) =>
            e.date.year == _selectedDay.year &&
            e.date.month == _selectedDay.month &&
            e.date.day == _selectedDay.day)
        .toList();

    final shadTheme = ShadTheme.of(context);
    // zinc primary = near-black (#18181B). 캘린더 마커/선택에 사용
    final primaryColor = shadTheme.colorScheme.primary;
    final mutedColor = shadTheme.colorScheme.muted;

    return Scaffold(
      body: Column(
        children: [
          eventsAsync.when(
            loading: () => TableCalendar<CalendarEvent>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              locale: 'ko_KR',
              focusedDay: focusedMonth,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() => _selectedDay = selected);
                ref.read(focusedMonthProvider.notifier).setMonth(focused);
              },
              onPageChanged: (focused) {
                ref.read(focusedMonthProvider.notifier).setMonth(focused);
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: false,
                ),
              calendarStyle: _calendarStyle,
              calendarBuilders: _calendarBuilders,
            ),
            error: (e, _) => Text(friendlyError(e)),
            data: (_) {
              // Design Ref: §5.6 — helper의 markerBuilder 파라미터 사용 (단일 진입점)
              final shadTheme = ShadTheme.of(context);
              final buildersWithMarkers =
                  buildKoreanWeekendBuilders<CalendarEvent>(
                defaultFg: shadTheme.colorScheme.foreground,
                headerTitleBuilder: _headerTitle,
                markerBuilder: (ctx, day, dayEvents) {
                  if (dayEvents.isEmpty) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 4,
                    child: EventMarker(
                      events: dayEvents,
                      memberColors: memberColors,
                    ),
                  );
                },
              );

              return TableCalendar<CalendarEvent>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                locale: 'ko_KR',
                focusedDay: focusedMonth,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() => _selectedDay = selected);
                  ref.read(focusedMonthProvider.notifier).setMonth(focused);
                },
                onPageChanged: (focused) {
                  ref.read(focusedMonthProvider.notifier).setMonth(focused);
                },
                // Design Ref: §5.4 monthlyEventMapProvider — O(1) eventLoader
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return eventMap[key] ?? [];
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: false,
                ),
                calendarStyle: _calendarStyle,
                calendarBuilders: buildersWithMarkers,
              );
            },
          ),
          // 구성원 필터 바 — AppBar 아래 항상 표시
          if (members.isNotEmpty)
            MemberFilterBar(
              members: members,
              memberColors: memberColors,
            ),
          Divider(height: 1, color: shadTheme.colorScheme.border),

          // 선택된 날짜의 일정 목록
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: shadTheme.colorScheme.mutedForeground
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '일정이 없습니다',
                          style: TextStyle(
                            color: shadTheme.colorScheme.mutedForeground,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (context2, i2) => Divider(
                      indent: 16,
                      endIndent: 16,
                      color: shadTheme.colorScheme.border,
                    ),
                    itemBuilder: (context, i) {
                      final event = selectedEvents[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: mutedColor,
                          child: Icon(
                            Icons.event,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(event.title),
                        subtitle: _EventSubtitle(event: event, muted: shadTheme.colorScheme.mutedForeground),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: shadTheme.colorScheme.mutedForeground,
                        ),
                        onTap: () => context.push(
                          '/calendar/event/${event.id}',
                          extra: event,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/calendar/event/new', extra: _selectedDay),
        backgroundColor: shadTheme.colorScheme.primary,
        foregroundColor: shadTheme.colorScheme.primaryForeground,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EventSubtitle extends StatelessWidget {
  const _EventSubtitle({required this.event, required this.muted});
  final CalendarEvent event;
  final Color muted;

  bool get _hasMemo => event.memo != null && event.memo!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (event.time == null && !_hasMemo) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.time != null)
          Text(event.time!, style: TextStyle(color: muted, fontSize: 13)),
        if (_hasMemo)
          Row(
            children: [
              Icon(Icons.notes_outlined, size: 12, color: muted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  event.memo!,
                  style: TextStyle(color: muted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
