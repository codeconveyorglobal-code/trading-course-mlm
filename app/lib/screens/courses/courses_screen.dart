import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/course_provider.dart';
import '../../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  final _categories = ['All', 'Forex', 'Crypto', 'Stocks', 'Options', 'Futures', 'Technical Analysis', 'Risk Management', 'Beginner'];
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<CourseProvider>().loadMore(_selectedCategory == 'All' ? null : _selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _search() {
    context.read<CourseProvider>().fetchCourses(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      search: _searchCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CourseProvider>();
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: AppColors.dark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: IconButton(icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary), onPressed: _search),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    context.read<CourseProvider>().fetchCourses(category: cat == 'All' ? null : cat, search: _searchCtrl.text);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.gradientPrimary : null,
                      color: selected ? null : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                    ),
                    child: Text(cat, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: cp.loading && cp.courses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : cp.courses.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.school_outlined, size: 60, color: AppColors.textHint), const SizedBox(height: 12), Text('No courses found', style: TextStyle(color: AppColors.textSecondary))]))
                    : ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: cp.courses.length + (cp.loading ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          if (i == cp.courses.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          return CourseCard(course: cp.courses[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
