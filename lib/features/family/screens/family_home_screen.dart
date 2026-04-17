// lib/features/family/screens/family_home_screen.dart
// Design Ref: §6 내비게이션 — AppBar 탭으로 그룹 전환 (BottomSheet)
// Plan SC-2: 초대 코드로 합류 후 즉시 공유 가능

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/error_message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';

class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyState = ref.watch(familyNotifierProvider);
    final activeFamily = ref.watch(activeFamilyProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showFamilySwitcher(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(activeFamily?.displayLabel ?? 'Family Hub'),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: familyState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (state) {
          if (state.families.isEmpty) {
            return _EmptyFamilyView();
          }
          return _FamilyDashboard(familyId: state.activeFamilyId!);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFamilyActions(context, ref),
        icon: const Icon(Icons.group_add),
        label: const Text('그룹 추가'),
      ),
    );
  }

  void _showFamilySwitcher(BuildContext context, WidgetRef ref) {
    final state = ref.read(familyNotifierProvider).value;
    if (state == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => _FamilySwitcherSheet(
        families: state.families,
        activeFamilyId: state.activeFamilyId,
        onSwitch: (id) {
          ref.read(familyNotifierProvider.notifier).switchFamily(id);
          Navigator.pop(context);
        },
        onAdd: () {
          Navigator.pop(context);
          _showFamilyActions(context, ref);
        },
      ),
    );
  }

  void _showFamilyActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('새 가족 그룹 만들기'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/family/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_outlined),
              title: const Text('초대 코드로 합류하기'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/family/join');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilySwitcherSheet extends StatelessWidget {
  const _FamilySwitcherSheet({
    required this.families,
    required this.activeFamilyId,
    required this.onSwitch,
    required this.onAdd,
  });

  final List families;
  final String? activeFamilyId;
  final void Function(String) onSwitch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('가족 그룹 선택',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...families.map((f) => ListTile(
                leading: Text(f.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(f.name),
                trailing: f.id == activeFamilyId
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => onSwitch(f.id),
              )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('그룹 추가'),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _EmptyFamilyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('아직 가족 그룹이 없어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('새 그룹을 만들거나 초대 코드로 합류하세요',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/family/create'),
            icon: const Icon(Icons.add),
            label: const Text('그룹 만들기'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/family/join'),
            icon: const Icon(Icons.group_add),
            label: const Text('초대 코드로 합류'),
          ),
        ],
      ),
    );
  }
}

class _FamilyDashboard extends ConsumerWidget {
  const _FamilyDashboard({required this.familyId});
  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(familyMembersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 구성원 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('구성원',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                membersAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text(friendlyError(e)),
                  data: (members) => Wrap(
                    spacing: 8,
                    children: members
                        .map((m) => Chip(label: Text(m.displayName)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // M4~M6 구현 전 플레이스홀더
        _PlaceholderCard(
            icon: Icons.calendar_month, title: '캘린더', subtitle: 'M4 구현 예정'),
        const SizedBox(height: 8),
        _PlaceholderCard(
            icon: Icons.check_box_outlined, title: '할 일', subtitle: 'M5 구현 예정'),
        const SizedBox(height: 8),
        _PlaceholderCard(
            icon: Icons.chat_bubble_outline, title: '채팅', subtitle: 'M6 구현 예정'),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        title: Text(title),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
