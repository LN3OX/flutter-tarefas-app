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

  /// Horas da duração: opcional, apenas números, até 999.
  static String? durationHours(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final hours = int.tryParse(text);
    if (hours == null || hours < 0) return 'Use apenas números';
    if (hours > 999) return 'Máximo 999 h';
    return null;
  }

  /// Minutos da duração: opcional, apenas números, de 0 a 59.
  static String? durationMinutes(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final minutes = int.tryParse(text);
    if (minutes == null || minutes < 0) return 'Use apenas números';
    if (minutes > 59) return 'De 0 a 59';
    return null;
  }
}
