import 'package:flutter/material.dart';
import '../../../services/export_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/theme_service.dart';
import '../../../theme/app_theme.dart';

class SettingsSheet extends StatefulWidget {
  final VoidCallback onSettingsChanged;

  const SettingsSheet({super.key, required this.onSettingsChanged});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late NotificationSoundOption _selectedSound;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedSound = NotificationService.instance.selectedSound;
  }

  void _handleSoundChange(NotificationSoundOption sound) {
    setState(() => _selectedSound = sound);
    NotificationService.instance.setSoundPreference(sound);
    NotificationService.instance.sendInstantNotification(
      title: 'Sound Selected',
      body: 'This sound is now configured for your task alerts.',
      customSound: sound,
    );
  }

  Future<void> _handlePdfExport() async {
    setState(() => _isExporting = true);
    final success = await ExportService.instance.exportTasksToPdf();
    setState(() => _isExporting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ PDF generated and ready to share!' : '❌ Failed to generate PDF.'),
          backgroundColor: AppTheme.surface,
        ),
      );
    }
  }

  Future<void> _handleEmailExport() async {
    setState(() => _isExporting = true);
    final success = await ExportService.instance.exportTasksToEmail();
    setState(() => _isExporting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✉️ Email draft created!' : '❌ Failed to prepare email.'),
          backgroundColor: AppTheme.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preferences & Export',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Theme Customization (Dark / Light)
            Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.primaryAmber,
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.instance.themeModeNotifier,
              builder: (context, currentMode, _) {
                return Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildThemeOption(
                        title: 'Dark Mode',
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () {
                          ThemeService.instance.setThemeMode(ThemeMode.dark);
                          widget.onSettingsChanged();
                        },
                      ),
                      _buildThemeOption(
                        title: 'Light Mode',
                        icon: Icons.light_mode_rounded,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () {
                          ThemeService.instance.setThemeMode(ThemeMode.light);
                          widget.onSettingsChanged();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Notification Sound Selection
            Text(
              'NOTIFICATION SOUND',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.primaryAmber,
              ),
            ),
            const SizedBox(height: 10),
            _buildSoundRadioTile(
              title: 'Standard Notification',
              subtitle: 'Default system tone',
              icon: Icons.notifications_rounded,
              value: NotificationSoundOption.systemDefault,
            ),
            _buildSoundRadioTile(
              title: 'High-Priority Alarm',
              subtitle: 'Loud alarm for urgent deadlines',
              icon: Icons.alarm_rounded,
              value: NotificationSoundOption.alarm,
            ),
            _buildSoundRadioTile(
              title: 'Silent Alert',
              subtitle: 'Haptic vibration only',
              icon: Icons.vibration_rounded,
              value: NotificationSoundOption.silent,
            ),
            const SizedBox(height: 24),

            // 3. Export Data (PDF & Email)
            Text(
              'DATA EXPORT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.primaryAmber,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _handlePdfExport,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryAmber,
                      side: const BorderSide(color: AppTheme.primaryAmber, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleEmailExport,
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: const Text('Email Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryAmber : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundRadioTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required NotificationSoundOption value,
  }) {
    final isSelected = _selectedSound == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _handleSoundChange(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAmber
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? AppTheme.primaryAmber : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryAmber, size: 20),
          ],
        ),
      ),
    );
  }
}
