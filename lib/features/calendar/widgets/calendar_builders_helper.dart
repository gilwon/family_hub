// lib/features/calendar/widgets/calendar_builders_helper.dart
// 캘린더 공통 빌더 — 한글 요일 + 토(파란색)/일(빨간색) 색상

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// 일정 있는 날 마커 — primary(거의 검정)와 구분되도록 딥 오렌지 고정색 사용
const _markerColor = Color(0xFFFF6B35);

CalendarStyle buildThemeCalendarStyle({
  required Color primary,
  required Color primaryFg,
}) {
  return CalendarStyle(
    markerDecoration: const BoxDecoration(
      color: _markerColor,
      shape: BoxShape.circle,
    ),
    markerSize: 7.0,
    markersMaxCount: 3,
    markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
    todayDecoration: BoxDecoration(
      color: primary.withValues(alpha: 0.15),
      shape: BoxShape.circle,
    ),
    todayTextStyle: TextStyle(color: primary),
    selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
    selectedTextStyle: TextStyle(color: primaryFg),
  );
}

/// Design Ref: §5.6 — markerBuilder 파라미터 추가로 단일 진입점 유지
CalendarBuilders<T> buildKoreanWeekendBuilders<T>({
  required Color defaultFg,
  Widget Function(BuildContext, DateTime)? headerTitleBuilder,
  Widget Function(BuildContext, DateTime, List<T>)? markerBuilder,
}) {
  return CalendarBuilders<T>(
    headerTitleBuilder: headerTitleBuilder,
    markerBuilder: markerBuilder,
    dowBuilder: (context, day) {
      const labels = ['월', '화', '수', '목', '금', '토', '일'];
      final text = labels[day.weekday - 1];
      final color = switch (day.weekday) {
        DateTime.saturday => Colors.blue,
        DateTime.sunday => Colors.red,
        _ => defaultFg,
      };
      return Center(
        child: Text(text, style: TextStyle(fontSize: 13, color: color)),
      );
    },
    defaultBuilder: (context, day, _) {
      if (day.weekday == DateTime.saturday) {
        return Center(
          child: Text('${day.day}', style: const TextStyle(color: Colors.blue)),
        );
      }
      if (day.weekday == DateTime.sunday) {
        return Center(
          child: Text('${day.day}', style: const TextStyle(color: Colors.red)),
        );
      }
      return null;
    },
    outsideBuilder: (context, day, _) {
      if (day.weekday == DateTime.saturday) {
        return Center(
          child: Text('${day.day}',
              style: TextStyle(color: Colors.blue.withValues(alpha: 0.4))),
        );
      }
      if (day.weekday == DateTime.sunday) {
        return Center(
          child: Text('${day.day}',
              style: TextStyle(color: Colors.red.withValues(alpha: 0.4))),
        );
      }
      return null;
    },
  );
}
