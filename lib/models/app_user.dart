/// Usuário cadastrado no aplicativo.
///
/// A senha nunca é guardada em texto puro: apenas o hash (SHA-256) e o salt
/// usado para gerá-lo ficam salvos no banco.
class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({int? id}) {
    return AppUser(
      id: id ?? this.id,
      name: name,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: createdAt,
    );
  }

  /// Primeiro nome, usado na saudação da tela inicial.
  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}
