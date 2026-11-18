import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/error_banner.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('Erro: $e\n$st');
      setState(() => _error = 'Não foi possível cadastrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Criar conta',
      subtitle: 'Cadastre-se para começar a organizar suas tarefas',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('register_name'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: Validators.name,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('register_email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('register_password'),
              controller: _passwordController,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            PasswordField(
              key: const Key('register_confirm'),
              controller: _confirmController,
              label: 'Confirmar senha',
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordController.text),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('register_submit'),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cadastrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context, AppRoutes.login),
              child: const Text('Já tem conta? Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
