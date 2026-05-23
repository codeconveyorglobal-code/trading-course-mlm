import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        handler.next(e);
      },
    ));
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // Auth
  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/auth/profile', data: data);

  Future<Response> changePassword(String current, String newPw) =>
      _dio.put('/auth/change-password', data: {'currentPassword': current, 'newPassword': newPw});

  // Courses
  Future<Response> getCourses({Map<String, dynamic>? params}) =>
      _dio.get('/courses', queryParameters: params);

  Future<Response> getCourse(String id) => _dio.get('/courses/$id');

  Future<Response> getMyCourses() => _dio.get('/courses/my-courses');

  Future<Response> updateProgress(String courseId, Map<String, dynamic> data) =>
      _dio.put('/courses/$courseId/progress', data: data);

  // Quizzes
  Future<Response> getCourseQuizzes(String courseId) =>
      _dio.get('/quizzes/course/$courseId');

  Future<Response> submitQuiz(String quizId, Map<String, dynamic> data) =>
      _dio.post('/quizzes/$quizId/submit', data: data);

  Future<Response> getMyAttempts(String quizId) =>
      _dio.get('/quizzes/$quizId/attempts');

  // MLM
  Future<Response> getMLMTree() => _dio.get('/mlm/tree');
  Future<Response> getMLMStats() => _dio.get('/mlm/stats');
  Future<Response> getCommissions({Map<String, dynamic>? params}) =>
      _dio.get('/mlm/commissions', queryParameters: params);
  Future<Response> getMyTeam({Map<String, dynamic>? params}) =>
      _dio.get('/mlm/team', queryParameters: params);
  Future<Response> requestWithdrawal(Map<String, dynamic> data) =>
      _dio.post('/mlm/withdraw', data: data);
  Future<Response> getMLMSettings() => _dio.get('/mlm/settings');
  Future<Response> getReferralInfo(String code) =>
      _dio.get('/mlm/referral/$code');

  // Payments
  Future<Response> initiatePayment(String courseId, String payCurrency) =>
      _dio.post('/payments/initiate', data: {'courseId': courseId, 'payCurrency': payCurrency});

  Future<Response> checkPaymentStatus(String paymentId) =>
      _dio.get('/payments/status/$paymentId');

  Future<Response> getTransactionHistory({Map<String, dynamic>? params}) =>
      _dio.get('/payments/history', queryParameters: params);

  Future<Response> getSupportedCurrencies() =>
      _dio.get('/payments/currencies');

  Future<Response> getWallet() => _dio.get('/payments/wallet');

  Future<Response> saveWalletAddress(String address) =>
      _dio.put('/payments/wallet/address', data: {'cryptoWalletAddress': address});

  Future<Response> getEstimate(double amount, String currency) =>
      _dio.get('/payments/estimate', queryParameters: {'amount': amount, 'currency': currency});
}
