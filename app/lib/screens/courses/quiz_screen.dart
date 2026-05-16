import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String quizId;
  const QuizScreen({super.key, required this.courseId, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? _quiz;
  bool _loading = true;
  bool _submitted = false;
  Map<int, dynamic> _answers = {};
  Map<String, dynamic>? _result;
  int _currentQ = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.getCourseQuizzes(widget.courseId);
      final quizzes = res.data['quizzes'] as List? ?? [];
      final quiz = quizzes.firstWhere((q) => q['_id'] == widget.quizId, orElse: () => null);
      if (mounted) setState(() { _quiz = quiz; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final questions = (_quiz!['questions'] as List);
    final answers = questions.asMap().entries.map((e) => {'questionIndex': e.key, 'selectedAnswer': _answers[e.key]}).toList();
    try {
      final api = context.read<ApiService>();
      final res = await api.submitQuiz(widget.quizId, {'answers': answers});
      if (mounted) setState(() { _result = res.data; _submitted = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit quiz')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.dark, body: Center(child: CircularProgressIndicator()));
    if (_quiz == null) return Scaffold(backgroundColor: AppColors.dark, body: Center(child: Text('Quiz not found', style: TextStyle(color: AppColors.textSecondary))));

    if (_submitted && _result != null) return _ResultScreen(result: _result!, quiz: _quiz!, onRetry: () => setState(() { _submitted = false; _result = null; _answers = {}; _currentQ = 0; }));

    final questions = _quiz!['questions'] as List;
    final q = questions[_currentQ];
    final options = List<String>.from(q['options'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: Text(_quiz!['title'] ?? 'Quiz'),
        backgroundColor: AppColors.dark,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQ + 1) / questions.length,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${_currentQ + 1} of ${questions.length}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Text(q['question'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5)),
            ),
            const SizedBox(height: 20),
            ...options.asMap().entries.map((e) {
              final selected = _answers[_currentQ] == e.key;
              return GestureDetector(
                onTap: () => setState(() => _answers[_currentQ] = e.key),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.gradientPrimary : null,
                    color: selected ? null : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                    boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 12)] : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? Colors.white.withOpacity(0.2) : AppColors.border),
                      child: Center(child: Text(String.fromCharCode(65 + e.key), style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value, style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary))),
                  ]),
                ),
              );
            }),
            const Spacer(),
            Row(children: [
              if (_currentQ > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentQ--), style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(0, 52)), child: const Text('Previous'))),
              if (_currentQ > 0) const SizedBox(width: 12),
              Expanded(
                child: _currentQ < questions.length - 1
                    ? GradientButton(label: 'Next', onPressed: _answers.containsKey(_currentQ) ? () => setState(() => _currentQ++) : null)
                    : GradientButton(label: 'Submit Quiz', onPressed: _answers.length == questions.length ? _submit : null),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final Map<String, dynamic> quiz;
  final VoidCallback onRetry;
  const _ResultScreen({required this.result, required this.quiz, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final attempt = result['attempt'] ?? {};
    final passed = attempt['passed'] ?? false;
    final percentage = (attempt['percentage'] ?? 0).toDouble();
    final score = attempt['score'] ?? 0;
    final total = quiz['totalMarks'] ?? quiz['questions']?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(title: const Text('Result'), backgroundColor: AppColors.dark),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: passed ? AppColors.gradientPrimary : const LinearGradient(colors: [AppColors.danger, Color(0xFFFF6B6B)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (passed ? AppColors.primary : AppColors.danger).withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Center(child: Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, size: 56, color: Colors.white)),
              ),
              const SizedBox(height: 24),
              Text(passed ? 'Congratulations!' : 'Keep Trying!', style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(passed ? 'You passed the quiz' : 'You didn\'t pass this time', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  _ResultRow('Score', '$score / $total'),
                  _ResultRow('Percentage', '${percentage.toStringAsFixed(1)}%'),
                  _ResultRow('Status', passed ? 'Passed ✓' : 'Failed ✗'),
                ]),
              ),
              const SizedBox(height: 32),
              if (!passed) GradientButton(label: 'Retry Quiz', onPressed: onRetry),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.border), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back to Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
    ]),
  );
}
