// lib/config/routes.dart
// Design Ref: §6 내비게이션 설계 — GoRouter + 인증 가드
// Plan SC-1: 인증 상태에 따른 자동 리다이렉트

import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/family/screens/create_family_screen.dart';
import '../features/family/screens/join_family_screen.dart';
import '../features/calendar/screens/event_form_screen.dart';
import '../features/calendar/screens/event_detail_screen.dart';
import '../features/todo/screens/todo_form_screen.dart';
import '../features/settings/screens/notification_settings_screen.dart';
import '../features/settings/screens/splash_image_screen.dart';
import '../features/splash/splash_screen.dart';
import '../core/push/push_handler.dart';
import '../models/calendar_event.dart';
import '../models/todo.dart';

final appRouter = GoRouter(
  navigatorKey: PushHandler.instance.navigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    // Plan SC-1: GoRouter 인증 가드 — auth.currentSession 확인
    final location = state.matchedLocation;

    // 스플래시는 항상 허용
    if (location == '/splash') return null;

    final isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;
    final isAuthRoute =
        location == '/login' || location == '/signup';

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/home/calendar';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    // HomeScreen — BottomNavigation 허브 (M4~M6 탭)
    GoRoute(
      path: '/home',
      redirect: (context2, state2) => '/home/calendar',
    ),
    GoRoute(
      path: '/home/calendar',
      builder: (context, state) => const HomeScreen(tab: 'calendar'),
    ),
    GoRoute(
      path: '/home/todo',
      builder: (context, state) => const HomeScreen(tab: 'todo'),
    ),
    GoRoute(
      path: '/home/chat',
      builder: (context, state) => const HomeScreen(tab: 'chat'),
    ),
    GoRoute(
      path: '/home/notifications',
      builder: (context, state) =>
          const HomeScreen(tab: 'notifications'),
    ),
    // 가족 그룹
    GoRoute(
      path: '/family/create',
      builder: (context, state) => const CreateFamilyScreen(),
    ),
    GoRoute(
      path: '/family/join',
      builder: (context, state) => const JoinFamilyScreen(),
    ),
    // 캘린더 일정
    GoRoute(
      path: '/calendar/event/new',
      builder: (context, state) => EventFormScreen(
        initialDate: state.extra as DateTime?,
      ),
    ),
    GoRoute(
      path: '/calendar/event/:id',
      builder: (context, state) => EventDetailScreen(
        event: state.extra as CalendarEvent,
      ),
    ),
    GoRoute(
      path: '/calendar/event/:id/edit',
      builder: (context, state) => EventFormScreen(
        event: state.extra as CalendarEvent,
      ),
    ),
    // 할 일
    GoRoute(
      path: '/todo/new',
      builder: (context, state) => const TodoFormScreen(),
    ),
    GoRoute(
      path: '/todo/edit/:id',
      builder: (context, state) => TodoFormScreen(
        todo: state.extra as Todo,
      ),
    ),
    // 알림 설정
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    // 스플래시 이미지 설정
    GoRoute(
      path: '/settings/splash',
      builder: (context, state) => const SplashImageScreen(),
    ),
  ],
);
