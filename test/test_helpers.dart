import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarefas_app/services/database_service.dart';

/// Banco SQLite real, porém em memória, isolado para cada teste.
DatabaseService createTestDatabase() {
  sqfliteFfiInit();
  SharedPreferences.setMockInitialValues({});
  return DatabaseService(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
  );
}
