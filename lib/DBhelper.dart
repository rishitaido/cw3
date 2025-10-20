// database_helper.dart
// Database Helper Class for Task Manager App
// Handles all SQLite database operations

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Task Model
class Task {
  int? id;
  String name;
  bool isCompleted;

  Task({
    this.id,
    required this.name,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Create Task from database Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');

    // Create settings table for theme preference
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value INTEGER NOT NULL
      )
    ''');
  }

  // CREATE: Insert task into database
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  // READ: Get all tasks from database
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'id ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // UPDATE: Update task in database
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // DELETE: Remove task from database
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save theme preference to database
  Future<void> saveThemePreference(bool isDark) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'isDarkMode', 'value': isDark ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Load theme preference from database
  Future<bool> getThemePreference() async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['isDarkMode'],
    );
    if (maps.isEmpty) return false;
    return maps.first['value'] == 1;
  }

  // Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}