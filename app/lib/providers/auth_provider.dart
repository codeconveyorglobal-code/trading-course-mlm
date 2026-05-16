import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  UserModel? _user;
  bool _loading = false;
  bool _initialized = false;

  AuthProvider(this._api) {
    _init();
  }

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  bool get initialized => _initialized;

  Future<void> _init() async {
    final token = await _api.getToken();
    if (token != null) {
      try {
        final res = await _api.getMe();
        _user = UserModel.fromJson(res.data['user']);
      } catch (_) {
        await _api.clearToken();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.login(email, password);
      await _api.setToken(res.data['token']);
      _user = UserModel.fromJson(res.data['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.register(data);
      await _api.setToken(res.data['token']);
      _user = UserModel.fromJson(res.data['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final res = await _api.getMe();
      _user = UserModel.fromJson(res.data['user']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }
}
