import 'package:flutter_test/flutter_test.dart';
import 'package:tarefas_app/utils/validators.dart';

void main() {
  group('Validators', () {
    test('e-mail', () {
      expect(Validators.email(''), 'E-mail é obrigatório');
      expect(Validators.email('abc'), 'E-mail inválido');
      expect(Validators.email('a@b'), 'E-mail inválido');
      expect(Validators.email('ana@email.com'), isNull);
    });

    test('senha e confirmação', () {
      expect(Validators.password(''), 'Senha é obrigatória');
      expect(Validators.password('123'), contains('6 caracteres'));
      expect(Validators.password('123456'), isNull);
      expect(Validators.loginPassword(''), 'Senha é obrigatória');
      expect(Validators.confirmPassword('x', 'y'), 'As senhas não coincidem');
      expect(Validators.confirmPassword('123456', '123456'), isNull);
    });

    test('nome e título', () {
      expect(Validators.name('  '), 'Nome é obrigatório');
      expect(Validators.name('Al'), contains('3 caracteres'));
      expect(Validators.taskTitle(''), 'Título é obrigatório');
      expect(Validators.taskTitle('ab'), contains('3 caracteres'));
      expect(Validators.taskTitle('a' * 81), contains('80'));
      expect(Validators.taskTitle('Estudar Flutter'), isNull);
      expect(Validators.taskDescription('a' * 501), contains('500'));
    });
  });
}
