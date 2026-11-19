import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/app_user.dart';
import '../models/task.dart';

/// Acesso à base de dados SQLite.
///
/// - Android/iOS: plugin nativo `sqflite`.
/// - Web: `sqflite_common_ffi_web` (SQLite compilado para WebAssembly,
///   carregado de `web/sqlite3.wasm`,
///   persistido no IndexedDB do navegador).
/// - Desktop/testes: `sqflite_common_ffi`.
class DatabaseService {
  static const _dbName = 'tarefas_app.db';
  static const _dbVersion = 2;

  final DatabaseFactory _factory;
  final String? _pathOverride;
  Database? _db;

  /// [factory] e [path] permitem injetar um banco em memória nos testes.
  DatabaseService({DatabaseFactory? factory, String? path})
      : _factory = factory ?? _defaultFactory(),
        _pathOverride = path;

  static DatabaseFactory _defaultFactory() {
    if (kIsWeb) return databaseFactoryFfiWebNoWebWorker;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return databaseFactorySqflitePlugin;
      default:
        sqfliteFfiInit();
        return databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final path = _pathOverride ??
        (kIsWeb ? _dbName : p.join(await _factory.getDatabasesPath(), _dbName));
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        priority INTEGER NOT NULL DEFAULT 1,
        due_date TEXT,
        duration_minutes INTEGER,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tasks_user ON tasks(user_id)');
  }

  /// Atualiza bancos criados em versões anteriores do app sem perder dados.
  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Versão 2: duração estimada da tarefa.
      await db.execute('ALTER TABLE tasks ADD COLUMN duration_minutes INTEGER');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---------------------------------------------------------------- Usuários

  Future<AppUser> insertUser(AppUser user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> findUserById(int id) async {
    final db = await database;
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  // ----------------------------------------------------------- Tarefas (CRUD)

  /// Create
  Future<Task> insertTask(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  /// Read: tarefas do usuário, pendentes primeiro, depois por prioridade.
  Future<List<Task>> getTasks(int userId) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_done ASC, priority DESC, created_at DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  /// Update. O filtro por `user_id` impede alterar tarefas de outro usuário.
  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [task.id, task.userId],
    );
  }

  /// Delete
  Future<int> deleteTask({required int id, required int userId}) async {
    final db = await database;
    return db.delete(
      'tasks',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
