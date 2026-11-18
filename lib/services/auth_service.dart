import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'database_service.dart';

/// Erro de autenticação com mensagem pronta para exibir ao usuário.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Autenticação local com e-mail e senha.
///
/// - Cadastro grava o usuário na tabela `users` com a senha transformada em
///   hash SHA-256 + salt aleatório.
/// - Login confere o hash.
/// - A sessão (id do usuário logado) é mantida no `SharedPreferences`, então
///   o usuário continua logado ao reabrir o app até fazer logout.
class AuthService extends ChangeNotifier {
  static const _sessionKey = 'session_user_id';
  static const _hashRounds = 1000;

  final DatabaseService _db;
  AppUser? _currentUser;
  bool _initialized = false;

  AuthService(this._db);

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _initialized;

  /// Restaura a sessão salva (se houver). Chamado na abertura do app.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionKey);
    if (userId != null) {
      _currentUser = await _db.findUserById(userId);
      if (_currentUser == null) await prefs.remove(_sessionKey);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Preencha todos os campos');
    }
    if (await _db.findUserByEmail(normalizedEmail) != null) {
      throw const AuthException('Este e-mail já está cadastrado');
    }

    final salt = _generateSalt();
    final user = await _db.insertUser(AppUser(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    ));
    await _startSession(user);
    return user;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Informe e-mail e senha');
    }
    final user = await _db.findUserByEmail(email);
    // Mesma mensagem para e-mail inexistente e senha errada, para não revelar
    // quais e-mails estão cadastrados.
    if (user == null || hashPassword(password, user.salt) != user.passwordHash) {
      throw const AuthException('E-mail ou senha inválidos');
    }
    await _startSession(user);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _startSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id!);
    _currentUser = user;
    notifyListeners();
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// SHA-256 iterado sobre `salt + senha`.
  @visibleForTesting
  static String hashPassword(String password, String salt) {
    var digest = utf8.encode('$salt$password');
    for (var i = 0; i < _hashRounds; i++) {
      digest = Uint8List.fromList(sha256.convert(digest).bytes);
    }
    return base64.encode(digest);
  }
}
