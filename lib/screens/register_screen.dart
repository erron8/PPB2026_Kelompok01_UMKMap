import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_exception.dart';
import '../utils/constants.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final success = await context.read<AuthProvider>().register(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted || !success) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Pendaftaran berhasil, silakan masuk')),
    );
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storefront,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buat akun',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Daftar untuk mulai mendata UMKM Anda',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Nama lengkap',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Kata sandi',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(AppColors.oliveGrey),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _AuthErrorMessage(
                        message: auth.errorMessage!,
                        onRetry:
                            AppException.isOfflineMessage(auth.errorMessage)
                            ? _submit
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Daftar',
                      isLoading: auth.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => context.go('/login'),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthErrorMessage extends StatelessWidget {
  const _AuthErrorMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOffline = AppException.isOfflineMessage(message);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOffline
            ? const Color(AppColors.statusRejectedFill)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
      ),
      child: Padding(
        padding: EdgeInsets.all(isOffline ? 12 : 0),
        child: Row(
          children: [
            if (isOffline) ...[
              Icon(Icons.wifi_off, color: colorScheme.error),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isOffline ? colorScheme.error : colorScheme.error,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ],
        ),
      ),
    );
  }
}
