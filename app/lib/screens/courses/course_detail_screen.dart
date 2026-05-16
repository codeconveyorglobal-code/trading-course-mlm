import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../config/app_config.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseModel? _course;
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final course = await context.read<CourseProvider>().getCourse(widget.courseId);
    if (mounted) setState(() { _course = course; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (_loading) return const Scaffold(backgroundColor: AppColors.dark, body: Center(child: CircularProgressIndicator()));
    if (_course == null) return Scaffold(backgroundColor: AppColors.dark, body: Center(child: Text('Course not found', style: TextStyle(color: AppColors.textSecondary))));

    final course = _course!;
    final isPurchased = course.isPurchased || (user?.hasCourse(course.id) ?? false);

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.dark,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  course.thumbnail != null
                      ? Image.network('${AppConfig.uploadUrl}/${course.thumbnail}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ThumbnailPlaceholder())
                      : _ThumbnailPlaceholder(),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, AppColors.dark]))),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _CategoryChip(course.category),
                    const SizedBox(width: 8),
                    _LevelChip(course.level),
                    const Spacer(),
                    if (course.hasDiscount) ...[
                      Text('\$${course.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, decoration: TextDecoration.lineThrough, fontSize: 14)),
                      const SizedBox(width: 6),
                    ],
                    ShaderMask(
                      shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                      child: Text('\$${course.effectivePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(course.shortDescription, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _InfoBadge(Icons.people_outline, '${course.enrolledCount} students'),
                    const SizedBox(width: 16),
                    _InfoBadge(Icons.library_books_outlined, '${course.materials.length} lessons'),
                    if (course.duration != null) ...[const SizedBox(width: 16), _InfoBadge(Icons.access_time_outlined, course.duration!)],
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _TabBtn(label: 'Overview', active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                      const SizedBox(width: 8),
                      _TabBtn(label: 'Lessons', active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                      const SizedBox(width: 8),
                      _TabBtn(label: 'Quizzes', active: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_tabIndex == 0) _OverviewTab(course: course),
                  if (_tabIndex == 1) _LessonsTab(course: course, isPurchased: isPurchased),
                  if (_tabIndex == 2) _QuizzesTab(course: course, isPurchased: isPurchased),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isPurchased
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
              child: GradientButton(label: 'Continue Learning', onPressed: () {}),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border))),
              child: GradientButton(label: 'Buy for \$${course.effectivePrice.toStringAsFixed(2)}', onPressed: () => context.push('/payment/${course.id}')),
            ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(decoration: const BoxDecoration(gradient: AppColors.gradientPrimary), child: const Center(child: Icon(Icons.candlestick_chart_rounded, size: 64, color: Colors.white38)));
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip(this.label);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primary.withOpacity(0.3))), child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12)));
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip(this.level);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.secondary.withOpacity(0.3))), child: Text(level, style: const TextStyle(color: AppColors.secondary, fontSize: 12)));
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))]);
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(gradient: active ? AppColors.gradientPrimary : null, color: active ? null : AppColors.cardLight, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  final CourseModel course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('About this course', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
    const SizedBox(height: 8),
    Text(course.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
    if (course.whatYouLearn.isNotEmpty) ...[
      const SizedBox(height: 20),
      const Text('What you\'ll learn', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ...course.whatYouLearn.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text(item, style: const TextStyle(color: AppColors.textSecondary)))]))),
    ],
    if (course.requirements.isNotEmpty) ...[
      const SizedBox(height: 20),
      const Text('Requirements', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      ...course.requirements.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.circle, size: 6, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(item, style: const TextStyle(color: AppColors.textSecondary)))]))),
    ],
  ]);
}

class _LessonsTab extends StatelessWidget {
  final CourseModel course;
  final bool isPurchased;
  const _LessonsTab({required this.course, required this.isPurchased});

  @override
  Widget build(BuildContext context) => Column(
    children: course.materials.map((mat) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: _matColor(mat.type).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_matIcon(mat.type), size: 20, color: _matColor(mat.type))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mat.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          Text(mat.type.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ])),
        if (!isPurchased && !mat.isPreview)
          const Icon(Icons.lock_outline, size: 18, color: AppColors.textHint)
        else
          const Icon(Icons.play_circle_outline, size: 20, color: AppColors.primary),
      ]),
    )).toList(),
  );

  Color _matColor(String type) {
    switch (type) {
      case 'video': return AppColors.primary;
      case 'pdf': return AppColors.danger;
      case 'quiz': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  IconData _matIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'quiz': return Icons.quiz_outlined;
      default: return Icons.article_outlined;
    }
  }
}

class _QuizzesTab extends StatelessWidget {
  final CourseModel course;
  final bool isPurchased;
  const _QuizzesTab({required this.course, required this.isPurchased});

  @override
  Widget build(BuildContext context) {
    if (!isPurchased) return Center(child: Column(children: [const Icon(Icons.lock_outline, size: 48, color: AppColors.textHint), const SizedBox(height: 8), Text('Purchase course to access quizzes', style: TextStyle(color: AppColors.textSecondary))]));
    if (course.quizzes.isEmpty) return Center(child: Text('No quizzes available', style: TextStyle(color: AppColors.textSecondary)));
    return Column(
      children: course.quizzes.map((qId) => GestureDetector(
        onTap: () => context.push('/courses/${course.id}/quiz/$qId'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.quiz_outlined, color: AppColors.warning)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Take Quiz', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          ]),
        ),
      )).toList(),
    );
  }
}
