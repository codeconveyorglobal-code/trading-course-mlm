import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/course_model.dart';

class CourseProvider extends ChangeNotifier {
  final ApiService _api;
  List<CourseModel> _courses = [];
  List<CourseModel> _myCourses = [];
  bool _loading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedCategory;

  CourseProvider(this._api);

  List<CourseModel> get courses => _courses;
  List<CourseModel> get myCourses => _myCourses;
  bool get loading => _loading;
  bool get hasMore => _currentPage < _totalPages;

  Future<void> fetchCourses({String? category, String? search, bool reset = true}) async {
    if (reset) { _currentPage = 1; _courses = []; }
    _loading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{'page': _currentPage, 'limit': 12};
      if (category != null && category != 'All') params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final res = await _api.getCourses(params: params);
      final newCourses = (res.data['courses'] as List).map((c) => CourseModel.fromJson(c)).toList();
      _courses = reset ? newCourses : [..._courses, ...newCourses];
      _totalPages = res.data['pagination']['pages'] ?? 1;
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchMyCourses() async {
    try {
      final res = await _api.getMyCourses();
      _myCourses = (res.data['enrollments'] as List)
          .map((e) => CourseModel.fromJson(e['courseId']))
          .where((c) => c.id.isNotEmpty)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<CourseModel?> getCourse(String id) async {
    try {
      final res = await _api.getCourse(id);
      return CourseModel.fromJson(res.data['course']);
    } catch (_) {
      return null;
    }
  }

  void loadMore(String? category) {
    if (!_loading && hasMore) {
      _currentPage++;
      fetchCourses(category: category, reset: false);
    }
  }
}
