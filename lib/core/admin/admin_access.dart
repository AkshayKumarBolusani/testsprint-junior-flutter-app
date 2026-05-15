import '../../features/auth/providers/auth_provider.dart';

/// Mirrors backend `authorizeRoles` / controller checks so the app does not
/// navigate staff into routes that always return 403.
abstract final class AdminAccess {
  static const superAdmin = 'SUPER_ADMIN';
  static const admin = 'ADMIN';
  static const contentManager = 'CONTENT_MANAGER';
  static const supportStaff = 'SUPPORT_STAFF';

  static bool isPrivilegedStaff(UserModel? u) =>
      u != null && (u.isStaff || u.role == superAdmin);

  /// Strips trailing slashes so `/admin/courses/` matches allowlists.
  static String normalizeAdminPath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  /// Routes a role may open (prefix match for sub-routes).
  static bool canOpenAdminPath(String role, String path) {
    path = normalizeAdminPath(path);
    if (path == '/admin' || path == '/admin/dashboard') return true;

    if (role == contentManager) {
      return _cmAllowed.any((p) => path == p || path.startsWith('$p/'));
    }
    if (role == supportStaff) {
      return _supportAllowed.any((p) => path == p || path.startsWith('$p/'));
    }
    if (role == admin) {
      return _adminAllowed.any((p) => path == p || path.startsWith('$p/'));
    }
    if (role == superAdmin) return true;
    return false;
  }

  static const _adminAllowed = <String>{
    '/admin/dashboard',
    '/admin/students',
    '/admin/courses',
    '/admin/subjects',
    '/admin/questions',
    '/admin/questions/bulk',
    '/admin/notifications/compose',
    '/admin/tests',
    '/admin/promos',
    '/admin/results',
    '/admin/app-settings',
  };

  static const _cmAllowed = <String>{
    '/admin/dashboard',
    '/admin/courses',
    '/admin/subjects',
    '/admin/questions',
    '/admin/questions/bulk',
    '/admin/tests',
  };

  static const _supportAllowed = <String>{
    '/admin/dashboard',
    '/admin/students',
    '/admin/results',
  };

  static String? redirectIfForbidden(String role, String path) {
    path = normalizeAdminPath(path);
    if (!path.startsWith('/admin')) return null;
    if (canOpenAdminPath(role, path)) return null;
    return '/admin/dashboard';
  }

  // —— Feature flags for UI (FABs, drawer items) ——

  static bool showStaff(UserModel? u) => u?.role == superAdmin;

  static bool showStudents(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin || r == supportStaff;
  }

  static bool canCreateStudent(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin;
  }

  static bool canEditStudentProfile(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin;
  }

  static bool showCoursesSubjectsQuestionsTests(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin || r == contentManager;
  }

  /// Support can open list screens per backend list endpoints but cannot author.
  static bool canAuthorCourseSubjectQuestionTest(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin || r == contentManager;
  }

  static bool showPromos(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin;
  }

  static bool showAdminResults(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin || r == supportStaff;
  }

  static bool showAppSettings(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin;
  }

  static bool showSeedDatabase(UserModel? u) => u?.role == superAdmin;

  static bool canCreatePromo(UserModel? u) => showPromos(u);

  static bool showComposeNotification(UserModel? u) {
    final r = u?.role;
    return r == superAdmin || r == admin;
  }
}
