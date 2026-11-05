import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/task_model.dart';
import 'database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  /// Generates a PDF report and opens the system share dialog (Email, Drive, Files)
  Future<bool> exportTasksToPdf() async {
    try {
      final tasks = await DatabaseHelper.instance.getAllTasks();
      final stats = await DatabaseHelper.instance.getCompletionStats();

      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
      final exportDate = DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TASKFLOW REPORT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#E5A93C'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on $exportDate',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1E1E1E'),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      '${stats['totalPercentage']}% COMPLETED',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#E5A93C'),
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),

              // Summary Stats Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8F9FA'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Tasks', '${stats['totalCount']}'),
                    _buildStatItem('Completed', '${stats['totalCompleted']}'),
                    _buildStatItem('Pending Today', '${stats['todayCount'] - stats['todayCompleted']}'),
                    _buildStatItem('Overall Progress', '${stats['totalPercentage']}%'),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Tasks Table
              pw.Text(
                'Task Breakdown',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEEEEE')),
                headers: ['Status', 'Title & Notes', 'Priority', 'Due Date', 'Repeat'],
                data: tasks.map((task) {
                  return [
                    task.isCompleted ? '[X] Done' : '[ ] Pending',
                    task.description.isNotEmpty
                        ? '${task.title}\n(${task.description})'
                        : task.title,
                    task.priority == 2 ? 'HIGH' : task.priority == 1 ? 'MED' : 'LOW',
                    dateFormat.format(task.dueDate),
                    task.repeatType.toUpperCase(),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TaskFlow Productivity App • Keep moving forward',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ];
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/TaskFlow_Export_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share via system share sheet (User can choose Gmail, Email, Drive, WhatsApp, etc.)
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'TaskFlow Export Report (PDF)',
        text: 'Here is my exported TaskFlow report generated on $exportDate.',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  /// Exports tasks as a formatted email message via Android share sheet / mail client
  Future<bool> exportTasksToEmail() async {
    try {
      final tasks = await DatabaseHelper.instance.getAllTasks();
      final stats = await DatabaseHelper.instance.getCompletionStats();
      final dateFormat = DateFormat('MMM d, h:mm a');
      final exportDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

      final buffer = StringBuffer();
      buffer.writeln('📋 TASKFLOW PRODUCTIVITY REPORT');
      buffer.writeln('Date: $exportDate');
      buffer.writeln('----------------------------------------');
      buffer.writeln('📊 PROGRESS SUMMARY:');
      buffer.writeln('• Overall Completion: ${stats['totalPercentage']}%');
      buffer.writeln('• Total Tasks: ${stats['totalCount']}');
      buffer.writeln('• Finished: ${stats['totalCompleted']}');
      buffer.writeln('• Pending: ${stats['totalCount'] - stats['totalCompleted']}');
      buffer.writeln('----------------------------------------\n');

      final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
      final completedTasks = tasks.where((t) => t.isCompleted).toList();

      if (pendingTasks.isNotEmpty) {
        buffer.writeln('⏳ PENDING TASKS (${pendingTasks.length}):');
        for (var t in pendingTasks) {
          final priority = t.priority == 2 ? '🔴 HIGH' : t.priority == 1 ? '🟡 MED' : '🟢 LOW';
          buffer.writeln('• [ ] ${t.title} ($priority)');
          buffer.writeln('  Due: ${dateFormat.format(t.dueDate)} | Repeat: ${t.repeatType}');
          if (t.description.isNotEmpty) buffer.writeln('  Notes: ${t.description}');
          buffer.writeln();
        }
      }

      if (completedTasks.isNotEmpty) {
        buffer.writeln('✅ COMPLETED TASKS (${completedTasks.length}):');
        for (var t in completedTasks) {
          buffer.writeln('• [x] ${t.title} (Completed)');
        }
        buffer.writeln();
      }

      buffer.writeln('----------------------------------------');
      buffer.writeln('Generated with TaskFlow Mobile App');

      await Share.share(
        buffer.toString(),
        subject: 'My TaskFlow Productivity Summary - $exportDate',
      );

      return true;
    } catch (_) {
      return false;
    }
  }
}
