import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/mlm_model.dart';

class MLMProvider extends ChangeNotifier {
  final ApiService _api;
  MLMStats? _stats;
  MLMTreeNode? _tree;
  List<Commission> _commissions = [];
  bool _loading = false;

  MLMProvider(this._api);

  MLMStats? get stats => _stats;
  MLMTreeNode? get tree => _tree;
  List<Commission> get commissions => _commissions;
  bool get loading => _loading;

  Future<void> fetchStats() async {
    try {
      final res = await _api.getMLMStats();
      _stats = MLMStats.fromJson(res.data['stats']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchTree() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.getMLMTree();
      if (res.data['tree'] != null) {
        _tree = MLMTreeNode.fromJson(res.data['tree']);
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchCommissions() async {
    try {
      final res = await _api.getCommissions();
      _commissions = (res.data['commissions'] as List).map((c) => Commission.fromJson(c)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> requestWithdrawal(Map<String, dynamic> data) async {
    try {
      await _api.requestWithdrawal(data);
      await fetchStats();
      return true;
    } catch (_) {
      return false;
    }
  }
}
