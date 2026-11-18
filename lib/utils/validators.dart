/// Validações reutilizadas pelos formulários. Cada função devolve `null`
/// quando o valor é válido ou a mensagem de erro a ser exibida.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field é obrigatório';
    }
    return null;
  }

  static String? name(String? value) {
    final error = required(value, field: 'Nome');
    if (error != null) return error;
    if (value!.trim().length < 3) return 'Nome deve ter ao menos 3 caracteres';
    return null;
  }

  static String? email(String? value) {
    final error = required(value, field: 'E-mail');
    if (error != null) return error;
    if (!_emailRegex.hasMatch(value!.trim())) return 'E-mail inválido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    if (value.length < 6) return 'Senha deve ter ao menos 6 caracteres';
    return null;
  }

  /// No login só exigimos que a senha seja informada.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Senha é obrigatória';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirme a senha';
    if (value != original) return 'As senhas não coincidem';
    return null;
  }

  static String? taskTitle(String? value) {
    final error = required(value, field: 'Título');
    if (error != null) return error;
    final length = value!.trim().length;
    if (length < 3) return 'Título deve ter ao menos 3 caracteres';
    if (length > 80) return 'Título deve ter no máximo 80 caracteres';
    return null;
  }

  static String? taskDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Descrição deve ter no máximo 500 caracteres';
    }
    return null;
  }
}
