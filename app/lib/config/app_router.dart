import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/courses/quiz_screen.dart';
import '../screens/mlm/mlm_dashboard_screen.dart';
import '../screens/mlm/binary_tree_screen.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/payment/payment_result_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/withdraw_screen.dart';
import '../screens/main_shell.dart';

class AppRouter {
  static GoRouter router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final isAuthRoute = state.matchedLocation.startsWith('/auth');
        final isSplash = state.matchedLocation == '/splash';

        if (isSplash) return null;
        if (!isLoggedIn && !isAuthRoute) return '/auth/login';
        if (isLoggedIn && isAuthRoute) return '/home';
        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
          path: '/auth',
          redirect: (_, state) => state.matchedLocation == '/auth' ? '/auth/login' : null,
          routes: [
            GoRoute(path: 'login', builder: (_, __) => const LoginScreen()),
            GoRoute(path: 'register', builder: (_, s) => RegisterScreen(referralCode: s.uri.queryParameters['ref']), ),
          ],
        ),
        ShellRoute(
          builder: (ctx, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
            GoRoute(path: '/courses/:id', builder: (_, s) => CourseDetailScreen(courseId: s.pathParameters['id']!)),
            GoRoute(path: '/courses/:id/quiz/:quizId', builder: (_, s) => QuizScreen(courseId: s.pathParameters['id']!, quizId: s.pathParameters['quizId']!)),
            GoRoute(path: '/mlm', builder: (_, __) => const MLMDashboardScreen()),
            GoRoute(path: '/mlm/tree', builder: (_, __) => const BinaryTreeScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(path: '/profile/withdraw', builder: (_, __) => const WithdrawScreen()),
          ],
        ),
        GoRoute(path: '/payment/:courseId', builder: (_, s) => PaymentScreen(courseId: s.pathParameters['courseId']!)),
        GoRoute(path: '/payment/result', builder: (_, s) => PaymentResultScreen(status: s.uri.queryParameters['status'] ?? 'pending', paymentId: s.uri.queryParameters['paymentId'])),
      ],
    );
  }
}
