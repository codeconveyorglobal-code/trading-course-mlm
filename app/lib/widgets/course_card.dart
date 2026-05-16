import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../models/course_model.dart';
import '../config/app_config.dart';

class CourseCard extends StatelessWidget {
  final CourseModel course;
  const CourseCard({super.key, required this.course});

  Color get _levelColor {
    switch (course.level) {
      case 'Advanced': return AppColors.danger;
      case 'Intermediate': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/courses/${course.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: course.thumbnail != null
                  ? Image.network(
                      '${AppConfig.uploadUrl}/${course.thumbnail}',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(course.level, style: TextStyle(color: _levelColor, fontSize: 10, fontWeight: FontWeight.w600))),
                      if (course.isPurchased) ...[
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('Enrolled', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600))),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(course.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (course.hasDiscount) ...[
                        Text('\$${course.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 6),
                      ],
                      ShaderMask(
                        shaderCallback: (b) => AppColors.gradientPrimary.createShader(b),
                        child: Text('\$${course.effectivePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      const Spacer(),
                      Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('${course.enrolledCount}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20)),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 100, height: 100,
    decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
    child: const Icon(Icons.candlestick_chart_rounded, color: Colors.white38, size: 36),
  );
}
