import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../services/database_helper.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_screen.dart';
import 'views/today_view.dart';
import 'views/completed_view.dart';
import 'views/repeated_view.dart';
import 'widgets/settings_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final GlobalKey<TodayViewState> _todayKey = GlobalKey<TodayViewState>();
  final GlobalKey<CompletedViewState> _completedKey = GlobalKey<CompletedViewState>();
  final GlobalKey<RepeatedViewState> _repeatedKey = GlobalKey<RepeatedViewState>();

  void _refreshAllViews() {
    _todayKey.currentState?.refresh();
    _completedKey.currentState?.refresh();
    _repeatedKey.currentState?.refresh();
  }

  void _showAddTaskSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddTaskSheet(
        onTaskCreated: () {
          _refreshAllViews();
        },
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(
        onSettingsChanged: () {
          setState(() {});
          _refreshAllViews();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titles = ['Today Tasks', 'Completed Tasks', 'Recurring Routines'];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: const TextStyle(
                color: AppTheme.primaryAmber,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titles[_currentIndex],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // 1. Settings & Export Button (Theme, Sounds, PDF/Email Export)
          IconButton(
            tooltip: 'Settings & Export',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryAmber, size: 22),
            onPressed: _showSettingsSheet,
          ),
          // 2. Bell Test Notification Button
          IconButton(
            tooltip: 'Send Test Notification',
            icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryAmber, size: 22),
            onPressed: () async {
              final success = await NotificationService.instance.sendInstantNotification(
                title: 'TaskFlow Reminder',
                body: 'Push notifications are working with your selected audio alert!',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '🔔 Notification sent! Check your phone status bar.'
                          : '⚠️ Please grant notification permission in Settings > Apps.',
                    ),
                    backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          // 3. Sign Out
          IconButton(
            tooltip: 'Sign Out',
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              size: 22,
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayView(key: _todayKey),
          CompletedView(key: _completedKey),
          RepeatedView(key: _repeatedKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: AppTheme.primaryAmber,
        foregroundColor: AppTheme.primaryDark,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _refreshAllViews();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_rounded),
            activeIcon: Icon(Icons.today_rounded, color: AppTheme.primaryAmber),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            activeIcon: Icon(Icons.check_circle_rounded, color: AppTheme.primaryAmber),
            label: 'Completed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat_rounded),
            activeIcon: Icon(Icons.repeat_on_rounded, color: AppTheme.primaryAmber),
            label: 'Repeated',
          ),
        ],
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final VoidCallback onTaskCreated;

  const _AddTaskSheet({required this.onTaskCreated});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  String _repeatType = 'none';
  int _priority = 1; // Medium
  int _reminderBeforeMinutes = 15; // 15 mins before

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primaryAmber,
                    onPrimary: AppTheme.primaryDark,
                    surface: AppTheme.darkSurface,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryAmber,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: isDark
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.primaryAmber,
                      onPrimary: AppTheme.primaryDark,
                      surface: AppTheme.darkSurface,
                    ),
                  )
                : ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppTheme.primaryAmber,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
                  ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newTask = Task(
      title: title,
      description: _descController.text.trim(),
      dueDate: _selectedDate,
      isCompleted: false,
      repeatType: _repeatType,
      priority: _priority,
      reminderBeforeMinutes: _reminderBeforeMinutes,
    );

    final id = await DatabaseHelper.instance.insertTask(newTask);
    final taskWithId = newTask.copyWith(id: id);

    // Schedule advance alert notification for the new task
    await NotificationService.instance.scheduleTaskNotification(taskWithId);

    widget.onTaskCreated();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: 'Task Title',
                prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primaryAmber),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Description or notes (optional)',
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Due Date & Time Picker Tile
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded, color: AppTheme.primaryAmber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date & Time',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, MMM d • h:mm a').format(_selectedDate),
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Advance Notification Alert Selector
            DropdownButtonFormField<int>(
              value: _reminderBeforeMinutes,
              dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Advance Notification Alert',
                prefixIcon: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryAmber, size: 20),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Alert at due time')),
                DropdownMenuItem(value: 10, child: Text('Alert 10 mins before')),
                DropdownMenuItem(value: 15, child: Text('Alert 15 mins before (Recommended)')),
                DropdownMenuItem(value: 30, child: Text('Alert 30 mins before')),
                DropdownMenuItem(value: 60, child: Text('Alert 1 hour before')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _reminderBeforeMinutes = val);
              },
            ),
            const SizedBox(height: 16),

            // Repeat Setting & Priority Selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _repeatType,
                    dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(
                        Icons.repeat_rounded,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        size: 20,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('No Repeat')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _repeatType = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _priority,
                    dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(
                        Icons.flag_rounded,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                        size: 20,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Low')),
                      DropdownMenuItem(value: 1, child: Text('Medium')),
                      DropdownMenuItem(value: 2, child: Text('High')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveTask,
              child: const Text('Save Task with Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
