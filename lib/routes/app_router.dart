import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/admin/admin_access.dart';
import '../features/admin/admin_placeholder_screens.dart';
import '../features/admin/courses/course_screens.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/admin/promos/promo_screens.dart';
import '../features/admin/notifications/compose_notification_screen.dart';
import '../features/admin/questions/bulk_import_questions_screen.dart';
import '../features/admin/questions/question_screens.dart';
import '../features/admin/results/admin_results_screen.dart';
import '../features/admin/settings/admin_app_settings_screen.dart';
import '../features/admin/staff/add_edit_staff_screen.dart';
import '../features/admin/staff/manage_staff_screen.dart';
import '../features/admin/students/add_edit_student_screen.dart';
import '../features/admin/students/edit_student_screen.dart';
import '../features/admin/students/manage_students_screen.dart';
import '../features/admin/students/student_details_screen.dart';
import '../features/admin/subjects/subject_screens.dart';
import '../features/admin/tests/test_screens.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/change_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/student/dashboard/student_dashboard_screen.dart';
import '../features/student/notifications/notifications_screen.dart';
import '../features/student/profile/profile_screen.dart';
import '../features/student/rankings/rankings_screen.dart';
import '../features/student/results/result_screen.dart';
import '../features/student/results/student_results_screen.dart';
import '../features/student/settings/settings_screen.dart';
import '../features/student/tests/available_tests_screen.dart';
import '../features/student/tests/test_attempt_screen.dart';
import '../features/student/tests/test_instructions_screen.dart';

/// Root navigator for [GoRouter]; sub-routes use [parentNavigatorKey] for full-screen pushes.
final GlobalKey<NavigatorState> _adminRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminRoot');

/// Notifies [GoRouter] when auth changes without recreating the router (avoids stack resets / stale UI).
class GoRouterAuthRefresh extends ChangeNotifier {
  GoRouterAuthRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final goRouterAuthRefreshProvider = Provider<GoRouterAuthRefresh>((ref) {
  final listenable = GoRouterAuthRefresh(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(goRouterAuthRefreshProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authNotifierProvider);
    var path = state.uri.path;
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final isPublic = path == '/splash' || path == '/login' || path == '/forgot-password';

    if (auth.phase == AuthPhase.loading) {
      if (path != '/splash') return '/splash';
      return null;
    }

    if (auth.phase == AuthPhase.guest) {
      if (isPublic) return null;
      return '/login';
    }

    final user = auth.user;
    if (user == null) return '/login';

    if (path == '/login' || path == '/splash') {
      return user.isStudent ? '/student/dashboard' : '/admin/dashboard';
    }

    if (!user.isStudent) {
      final denied = AdminAccess.redirectIfForbidden(user.role, path);
      if (denied != null) return denied;
    }

    if (user.isStudent) {
      if (path.startsWith('/admin')) return '/student/dashboard';
      return null;
    }

    if (path.startsWith('/student')) return '/admin/dashboard';

    return null;
  }

  return GoRouter(
    navigatorKey: _adminRootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordInfoScreen()),

      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/dashboard',
      ),

      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/settings/password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),

      GoRoute(path: '/student/dashboard', builder: (context, state) => const StudentDashboardScreen()),
      GoRoute(path: '/student/tests', builder: (context, state) => const AvailableTestsScreen()),
      GoRoute(
        path: '/student/tests/:testId/instructions',
        builder: (context, state) {
          final id = state.pathParameters['testId']!;
          return TestInstructionsScreen(testId: id);
        },
      ),
      GoRoute(
        path: '/student/tests/:testId/attempt',
        builder: (context, state) {
          final id = state.pathParameters['testId']!;
          return TestAttemptScreen(testId: id);
        },
      ),
      GoRoute(path: '/student/results', builder: (context, state) => const StudentResultsScreen()),
      GoRoute(
        path: '/student/results/:resultId',
        builder: (context, state) {
          final id = state.pathParameters['resultId']!;
          return ResultScreen(resultId: id);
        },
      ),
      GoRoute(path: '/student/rankings', builder: (context, state) => const RankingsScreen()),
      GoRoute(path: '/student/profile', builder: (context, state) => const ProfileScreen()),

      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/students', builder: (context, state) => const ManageStudentsScreen()),
      GoRoute(path: '/admin/students/new', builder: (context, state) => const AddEditStudentScreen()),
      GoRoute(
        path: '/admin/students/:studentId/edit',
        builder: (context, state) {
          final id = state.pathParameters['studentId']!;
          return EditStudentScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/admin/students/:studentId',
        builder: (context, state) {
          final id = state.pathParameters['studentId']!;
          return StudentDetailsScreen(studentId: id);
        },
      ),

      GoRoute(path: '/admin/staff', builder: (context, state) => const ManageStaffScreen()),
      GoRoute(path: '/admin/staff/new', builder: (context, state) => const AddEditStaffScreen()),
      GoRoute(
        path: '/admin/staff/:staffId/edit',
        builder: (context, state) {
          final id = state.pathParameters['staffId']!;
          return AddEditStaffScreen(staffId: id);
        },
      ),

      GoRoute(path: '/admin/courses', builder: (context, state) => const ManageCoursesScreen()),
      GoRoute(path: '/admin/courses/new', builder: (context, state) => const AddEditCourseScreen()),
      GoRoute(
        path: '/admin/courses/:courseId/edit',
        builder: (context, state) {
          final id = state.pathParameters['courseId']!;
          return AddEditCourseScreen(courseId: id);
        },
      ),

      GoRoute(path: '/admin/subjects', builder: (context, state) => const ManageSubjectsScreen()),
      GoRoute(path: '/admin/subjects/new', builder: (context, state) => const AddEditSubjectScreen()),
      GoRoute(
        path: '/admin/subjects/:subjectId/edit',
        builder: (context, state) {
          final id = state.pathParameters['subjectId']!;
          return AddEditSubjectScreen(subjectId: id);
        },
      ),

      GoRoute(path: '/admin/tests', builder: (context, state) => const ManageTestsScreen()),
      GoRoute(path: '/admin/tests/new', builder: (context, state) => const AddEditTestScreen()),
      GoRoute(
        path: '/admin/tests/:testId/edit',
        builder: (context, state) {
          final id = state.pathParameters['testId']!;
          return AddEditTestScreen(testId: id);
        },
      ),

      GoRoute(
        path: '/admin/questions',
        builder: (context, state) => const ManageQuestionsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _adminRootNavigatorKey,
            builder: (context, state) => const AddEditQuestionScreen(),
          ),
          GoRoute(
            path: 'bulk',
            parentNavigatorKey: _adminRootNavigatorKey,
            builder: (context, state) => const BulkImportQuestionsScreen(),
          ),
          GoRoute(
            path: ':questionId/edit',
            parentNavigatorKey: _adminRootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['questionId']!;
              return AddEditQuestionScreen(questionId: id);
            },
          ),
        ],
      ),

      GoRoute(path: '/admin/notifications/compose', builder: (context, state) => const ComposeNotificationScreen()),

      GoRoute(path: '/admin/promos', builder: (context, state) => const ManagePromosScreen()),
      GoRoute(path: '/admin/promos/new', builder: (context, state) => const AddEditPromoScreen()),
      GoRoute(
        path: '/admin/promos/:promoId/edit',
        builder: (context, state) {
          final id = state.pathParameters['promoId']!;
          return AddEditPromoScreen(promoId: id);
        },
      ),

      GoRoute(path: '/admin/results', builder: (context, state) => const AdminResultsScreen()),
      GoRoute(path: '/admin/app-settings', builder: (context, state) => const AdminAppSettingsScreen()),
    ],
  );
});
