// lib/features/calendar/widgets/member_filter_bar.dart
// Design Ref: §6 MemberFilterBar — AppBar 아래 항상 표시, 구성원 색상 칩

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/family.dart';
import '../../../providers/event_filter_provider.dart';
import 'event_marker.dart';

class MemberFilterBar extends ConsumerWidget {
  const MemberFilterBar({
    super.key,
    required this.members,
    required this.memberColors,
  });

  final List<FamilyMember> members;

  /// userId → Color 맵 (EventMarker와 동일한 소스 사용)
  final Map<String, Color> memberColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (members.isEmpty) return const SizedBox.shrink();

    final filterIds = ref.watch(eventFilterProvider);
    final theme = ShadTheme.of(context);

    return Container(
      height: 44,
      color: theme.colorScheme.background,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: members.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final member = members[i];
          final color = memberColors[member.userId] ??
              EventMarker.fallbackColor(member.userId);
          final isActive = filterIds.isEmpty || filterIds.contains(member.userId);

          return _MemberChip(
            member: member,
            color: color,
            isActive: isActive,
            onTap: () => ref.read(eventFilterProvider.notifier).toggle(member.userId),
          );
        },
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final FamilyMember member;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                member.emoji ?? member.displayName.substring(0, 1),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 3),
              Text(
                member.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? color : color.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
