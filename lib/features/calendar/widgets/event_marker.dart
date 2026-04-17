// lib/features/calendar/widgets/event_marker.dart
// Design Ref: §6 EventMarker — 구성원 색상 점 마커 (최대 3개 + +N)

import 'package:flutter/material.dart';

import '../../../models/calendar_event.dart';

/// 날짜 하단에 표시되는 구성원 색상 점 마커.
///
/// - 고유 createdBy 기준 최대 [maxVisible]개 색상 점 표시
/// - 초과 시 "+N" 텍스트 추가
/// - memberColors에 없는 userId는 [fallbackColor]로 표시
class EventMarker extends StatelessWidget {
  const EventMarker({
    super.key,
    required this.events,
    required this.memberColors,
    this.maxVisible = 3,
    this.size = 6.0,
  });

  final List<CalendarEvent> events;
  final Map<String, Color> memberColors;
  final int maxVisible;
  final double size;

  /// userId 해시 기반 결정론적 HSL 색상 (memberColors에 없을 때 사용)
  static Color fallbackColor(String userId) {
    final hash = userId.codeUnits.fold(0, (a, b) => a + b);
    final hue = (hash * 137.508) % 360; // 황금각 분포
    return HSLColor.fromAHSL(1.0, hue, 0.55, 0.50).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    // 고유 createdBy만 추출 (이미 나타난 사람은 중복 마커 제외)
    final seen = <String>{};
    final uniqueCreators = <String>[];
    for (final e in events) {
      if (seen.add(e.createdBy)) {
        uniqueCreators.add(e.createdBy);
      }
    }

    final visibleCreators = uniqueCreators.take(maxVisible).toList();
    final overflow = uniqueCreators.length - visibleCreators.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final userId in visibleCreators) ...[
          _Dot(
            color: memberColors[userId] ?? fallbackColor(userId),
            size: size,
          ),
          const SizedBox(width: 2),
        ],
        if (overflow > 0)
          Text(
            '+$overflow',
            style: TextStyle(
              fontSize: size - 1,
              color: Colors.grey.shade600,
              height: 1,
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
