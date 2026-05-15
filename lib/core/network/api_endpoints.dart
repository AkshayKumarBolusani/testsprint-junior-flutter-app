class ApiEndpoints {
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';
  static const authChangePassword = '/api/auth/change-password';

  static const studentDashboard = '/api/dashboard/student';
  static const adminDashboard = '/api/dashboard/admin';

  static const testsAvailable = '/api/tests/student/available';
  static String testById(String id) => '/api/tests/$id';

  static const resultsSubmit = '/api/results/submit';
  static const resultsMy = '/api/results/my';
  static String resultById(String id) => '/api/results/$id';
  static String rankingsByTest(String testId) => '/api/rankings/test/$testId';

  static const promosStudent = '/api/promos/student';

  static const students = '/api/students';
  static const studentsCreate = '/api/students/create';
  static String studentById(String id) => '/api/students/$id';
  static String studentStatus(String id) => '/api/students/$id/status';
  static String studentPassword(String id) => '/api/students/$id/password';

  static const users = '/api/users';
  static const usersCreate = '/api/users/create';
  static String userById(String id) => '/api/users/$id';
  static String userStatus(String id) => '/api/users/$id/status';
  static String userPassword(String id) => '/api/users/$id/password';
  static String userAccess(String id) => '/api/users/$id/access';

  static String courseById(String id) => '/api/courses/$id';
  static String subjectById(String id) => '/api/subjects/$id';
  static String questionById(String id) => '/api/questions/$id';
  static String testPublish(String id) => '/api/tests/$id/publish';
  static String resultsForTest(String testId) => '/api/results/test/$testId';
  static const courses = '/api/courses';
  static const subjects = '/api/subjects';
  static const tests = '/api/tests';
  static const questions = '/api/questions';
  static const questionsBulk = '/api/questions/bulk';
  static const questionsBulkDelete = '/api/questions/bulk-delete';
  static String questionApprove(String id) => '/api/questions/$id/approve';
  static const promos = '/api/promos';
  static const notifications = '/api/notifications';
  static const settingsApp = '/api/settings/app';
  static const seedDatabase = '/api/seed';
}
