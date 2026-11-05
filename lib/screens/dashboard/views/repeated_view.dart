import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../services/database_helper.dart';
import '../../../theme/app_theme.dart';
import '../widgets/task_tile.dart';

class RepeatedView extends StatefulWidget {
  const RepeatedView({super.key});

  @override
  State<RepeatedView> createState() => RepeatedViewState();
}

class RepeatedViewState extends State<RepeatedView> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    setState(() {
      _tasksFuture = DatabaseHelper.instance.getRepeatedTasks();
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

        if (tasks.isEmpty) {
          return _buildEmptyState(
            isDark: isDark,
            icon: Icons.repeat_rounded,
            title: 'No Recurring Tasks',
            subtitle: 'Add daily, weekly, or monthly repeating routines to see them here.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
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
