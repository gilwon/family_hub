// lib/features/home/home_screen.dart
// Design Ref: §6.1 라우트 구조 — HomeScreen BottomNavigation 허브
// M4~M6 탭 순차 활성화

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/theme_provider.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/todo/screens/todo_screen.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.tab});
  final String tab; // 'calendar' | 'todo' | 'chat' | 'notifications'

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int get _currentIndex => switch (widget.tab) {
        'todo' => 1,
        'chat' => 2,
        'notifications' => 3,
        _ => 0,
      };

  void _onTabTapped(int index) {
    final path = switch (index) {
      1 => '/home/todo',
      2 => '/home/chat',
      3 => '/home/notifications',
      _ => '/home/calendar',
    };
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final activeFamily = ref.watch(activeFamilyProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final unreadChatCount = ref.watch(unreadChatCountProvider);

    ref.listen(familyNotifierProvider, (prev, next) {
      if (next.hasError && context.mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('그룹 로드 실패'),
            description: Text(next.error.toString()),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showFamilySwitcher(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activeFamily?.displayLabel ?? 'Family Hub',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        elevation: 0,
        actions: [
          // 그룹 추가/합류 — 자주 쓰는 액션이라 바로 노출
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: '그룹 추가',
            onPressed: () => _showGroupActions(context),
          ),
          // 나머지 메뉴는 overflow로 정리
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'notifications':
                  context.push('/settings/notifications');
                case 'cover':
                  context.push('/settings/splash');
                case 'theme':
                  ref.read(themeModeProvider.notifier).toggle();
                case 'logout':
                  await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
            itemBuilder: (ctx) {
              final mode = ref.read(themeModeProvider);
              final isDark = mode == ThemeMode.dark ||
                  (mode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(ctx) ==
                          Brightness.dark);
              return [
                const PopupMenuItem(
                  value: 'notifications',
                  child: _MenuItem(
                      icon: Icons.notifications_outlined, label: '알림 설정'),
                ),
                const PopupMenuItem(
                  value: 'cover',
                  child: _MenuItem(
                      icon: Icons.wallpaper_outlined, label: '커버 이미지'),
                ),
                PopupMenuItem(
                  value: 'theme',
                  child: _MenuItem(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDark ? '라이트 모드' : '다크 모드',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: _MenuItem(
                      icon: Icons.logout, label: '로그아웃', danger: true),
                ),
              ];
            },
          ),
        ],
      ),
      body: switch (_currentIndex) {
        0 => const CalendarScreen(),
        1 => const TodoScreen(),
        2 => const ChatScreen(),
        3 => const NotificationScreen(),
        _ => const CalendarScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          const NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: '할 일',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: '채팅',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications),
            ),
            label: '알림',
          ),
        ],
      ),
    );
  }

  void _showFamilySwitcher(BuildContext context) {
    final state = ref.read(familyNotifierProvider).value;
    if (state == null) return;
    final theme = ShadTheme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '가족 그룹 선택',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: theme.colorScheme.foreground,
                ),
              ),
            ),
            ...state.families.map((f) => ListTile(
                  leading: Text(f.emoji,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(f.name),
                  trailing: f.id == state.activeFamilyId
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () {
                    ref
                        .read(familyNotifierProvider.notifier)
                        .switchFamily(f.id);
                    Navigator.pop(context);
                  },
                )),
            Divider(color: theme.colorScheme.border),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('그룹 추가'),
              onTap: () {
                Navigator.pop(context);
                _showGroupActions(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showGroupActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BottomSheetHandle(),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? ShadTheme.of(context).colorScheme.destructive
        : ShadTheme.of(context).colorScheme.foreground;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: ShadTheme.of(context).colorScheme.muted,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
