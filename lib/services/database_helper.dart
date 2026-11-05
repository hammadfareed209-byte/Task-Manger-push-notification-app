import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';
    const intType = 'INTEGER NOT NULL DEFAULT 1';

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        title $textType,
        description $textNullable,
        due_date $textType,
        is_completed $boolType,
        repeat_type $textType,
        priority $intType,
        reminder_before_minutes INTEGER NOT NULL DEFAULT 15,
        created_at $textType
      )
    ''');

    await _insertInitialData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE tasks ADD COLUMN reminder_before_minutes INTEGER NOT NULL DEFAULT 15',
        );
      } catch (_) {
        // Column may already exist
      }
    }
  }

  Future<void> _insertInitialData(Database db) async {
    final now = DateTime.now();
    final todayDue = DateTime(now.year, now.month, now.day, 17, 0);

    final initialTasks = [
      Task(
        title: 'Review Project Architecture',
        description: 'Finalize database schema & push notification service.',
        dueDate: todayDue,
        isCompleted: true,
        repeatType: 'none',
        priority: 2,
        reminderBeforeMinutes: 15,
      ),
      Task(
        title: 'Daily Standup Call',
        description: 'Sync with product and engineering teams.',
        dueDate: todayDue,
        isCompleted: true,
        repeatType: 'daily',
        priority: 1,
        reminderBeforeMinutes: 10,
      ),
      Task(
        title: 'Submit Weekly Timesheet',
        description: 'Log sprint hours before Friday 6 PM.',
        dueDate: todayDue.add(const Duration(hours: 3)),
        isCompleted: false,
        repeatType: 'weekly',
        priority: 0,
        reminderBeforeMinutes: 30,
      ),
      Task(
        title: 'Client Demo Presentation',
        description: 'Showcase live task progress and PDF export feature.',
        dueDate: todayDue.add(const Duration(hours: 5)),
        isCompleted: false,
        repeatType: 'none',
        priority: 2,
        reminderBeforeMinutes: 60,
      ),
    ];

    for (var task in initialTasks) {
      await db.insert('tasks', task.toMap());
    }
  }

  // --- CRUD Operations ---

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleTaskStatus(int id, bool currentStatus) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_completed': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Progress & Statistics ---

  Future<Map<String, dynamic>> getCompletionStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final allTasks = await db.query('tasks');
    final todayTasks = await db.query(
      'tasks',
      where: 'due_date >= ? AND due_date <= ?',
      whereArgs: [startOfToday, endOfToday],
    );

    final totalCount = allTasks.length;
    final totalCompleted = allTasks.where((t) => t['is_completed'] == 1).length;

    final todayCount = todayTasks.length;
    final todayCompleted = todayTasks.where((t) => t['is_completed'] == 1).length;

    final todayPercentage = todayCount > 0 ? ((todayCompleted / todayCount) * 100).round() : 0;
    final totalPercentage = totalCount > 0 ? ((totalCompleted / totalCount) * 100).round() : 0;

    return {
      'totalCount': totalCount,
      'totalCompleted': totalCompleted,
      'todayCount': todayCount,
      'todayCompleted': todayCompleted,
      'todayPercentage': todayPercentage,
      'totalPercentage': totalPercentage,
    };
  }

  // --- Views / Filtering Queries ---

  Future<List<Task>> getTodayTasks() async {
    final db = await database;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'tasks',
      where: 'is_completed = 0 AND due_date <= ?',
      whereArgs: [endOfToday],
      orderBy: 'priority DESC, due_date ASC',
    );

    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getCompletedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'is_completed = 1',
      orderBy: 'due_date DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getRepeatedTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: "repeat_type != 'none'",
      orderBy: 'repeat_type ASC, priority DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'due_date ASC');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
