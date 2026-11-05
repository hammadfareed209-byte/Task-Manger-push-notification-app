import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/task_model.dart';
import '../../../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? (isDark ? AppTheme.darkBorder.withOpacity(0.4) : AppTheme.lightBorder.withOpacity(0.5))
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onToggleStatus(task.isCompleted),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Checkbox
                GestureDetector(
                  onTap: () => onToggleStatus(task.isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(top: 2, right: 14),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? AppTheme.primaryAmber : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.isCompleted
                            ? AppTheme.primaryAmber
                            : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                        width: 1.8,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: AppTheme.primaryDark)
                        : null,
                  ),
                ),

                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted
                              ? (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted)
                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Due Date badge
                          _buildChip(
                            icon: Icons.calendar_today_rounded,
                            label: dateFormat.format(task.dueDate),
                            color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                                ? AppTheme.accentRed
                                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          ),
                          // Advance notification alert badge
                          if (task.reminderBeforeMinutes > 0)
                            _buildChip(
                              icon: Icons.notifications_active_rounded,
                              label: '${task.reminderBeforeMinutes}m alert',
                              color: AppTheme.accentBlue,
                            ),
                          // Repeat rule badge
                          if (task.repeatType != 'none')
                            _buildChip(
                              icon: Icons.repeat_rounded,
                              label: task.repeatType.toUpperCase(),
                              color: AppTheme.primaryAmber,
                            ),
                          // Priority badge
                          _buildChip(
                            icon: Icons.flag_rounded,
                            label: _priorityLabel(task.priority),
                            color: _priorityColor(task.priority),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete Action Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  onPressed: onDelete,
                  splashRadius: 20,
                  tooltip: 'Delete task',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 2:
        return 'HIGH';
      case 1:
        return 'MED';
      default:
        return 'LOW';
    }
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return AppTheme.accentRed;
      case 1:
        return AppTheme.primaryAmber;
      default:
        return AppTheme.accentGreen;
    }
  }
}
