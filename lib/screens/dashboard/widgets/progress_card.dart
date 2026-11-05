import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProgressCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onRefresh;

  const ProgressCard({
    super.key,
    required this.stats,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = stats['totalCount'] ?? 0;
    final totalCompleted = stats['totalCompleted'] ?? 0;
    final percentage = (stats['totalPercentage'] as int?) ?? 0;
    final pendingCount = totalCount - totalCompleted;

    String motivationalText;
    if (totalCount == 0) {
      motivationalText = 'No tasks created yet. Tap + to begin!';
    } else if (percentage == 100) {
      motivationalText = 'Outstanding! All tasks completed today! 🎉';
    } else if (percentage >= 50) {
      motivationalText = 'Great momentum! Over halfway there.';
    } else {
      motivationalText = 'Ready to conquer your day? Take on the next task.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.primaryAmber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage == 100
                      ? AppTheme.accentGreen.withOpacity(0.15)
                      : AppTheme.primaryAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: percentage == 100 ? AppTheme.accentGreen : AppTheme.primaryAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: totalCount > 0 ? (totalCompleted / totalCount) : 0),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.lightSurfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage == 100 ? AppTheme.accentGreen : AppTheme.primaryAmber,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Micro Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalCompleted of $totalCount completed',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$pendingCount pending',
                style: TextStyle(
                  color: pendingCount > 0 ? AppTheme.primaryAmber : AppTheme.accentGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            motivationalText,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
