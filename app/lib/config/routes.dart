import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/onboarding/create_or_join_family_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/qr_code_screen.dart';
import '../screens/family/manage_members_screen.dart';
import '../screens/family/add_member_screen.dart';
import '../screens/visitor/incoming_visitor_screen.dart';
import '../screens/visitor/visitor_history_screen.dart';
import '../screens/visitor/visitor_detail_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/family-setup',
        builder: (context, state) => const CreateOrJoinFamilyScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/qr-code',
        builder: (context, state) => const QrCodeScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const ManageMembersScreen(),
      ),
      GoRoute(
        path: '/add-member',
        builder: (context, state) => const AddMemberScreen(),
      ),
      GoRoute(
        path: '/incoming-visitor',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return IncomingVisitorScreen(visitorData: data);
        },
      ),
      GoRoute(
        path: '/visitor-history',
        builder: (context, state) => const VisitorHistoryScreen(),
      ),
      GoRoute(
        path: '/visitor/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VisitorDetailScreen(visitorId: id);
        },
      ),
      GoRoute(
        path: '/chat/:visitorId',
        builder: (context, state) {
          final visitorId = state.pathParameters['visitorId']!;
          final visitorName = state.extra as String? ?? 'Visitor';
          return ChatScreen(visitorId: visitorId, visitorName: visitorName);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
