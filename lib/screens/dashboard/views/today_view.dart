import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../services/database_helper.dart';
import '../../../theme/app_theme.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_tile.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => TodayViewState();
}

class TodayViewState extends State<TodayView> {
  late Future<List<Task>> _tasksFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    setState(() {
      _tasksFuture = DatabaseHelper.instance.getTodayTasks();
      _statsFuture = DatabaseHelper.instance.getCompletionStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading tasks: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.accentRed),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        return FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? {
              'totalCount': 0,
              'totalCompleted': 0,
              'todayCount': 0,
              'todayCompleted': 0,
              'todayPercentage': 0,
              'totalPercentage': 0,
            };

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Progress Tracking Card with live completion rate
                SliverToBoxAdapter(
                  child: ProgressCard(
                    stats: stats,
                    onRefresh: refresh,
                  ),
                ),

                // 2. Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TODAY\'S TASKS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                          ),
                        ),
                        Text(
                          '${tasks.length} remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Task List or Empty State
                if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      isDark: isDark,
                      icon: Icons.check_circle_outline_rounded,
                      title: 'All Done for Today!',
                      subtitle: 'You have cleared all scheduled tasks. Tap + to add a new task.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return TaskTile(
                            task: task,
                            onToggleStatus: (isCompleted) async {
                              await DatabaseHelper.instance.toggleTaskStatus(task.id!, isCompleted);
                              refresh();
                            },
                            onDelete: () async {
                              await DatabaseHelper.instance.deleteTask(task.id!);
                              refresh();
                            },
                          );
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryAmber.withOpacity(0.8)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
