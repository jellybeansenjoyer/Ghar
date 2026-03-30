import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const bool _showPhoneAuth = false; // Keep phone flow in code, hide in UI for now.
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+91$phone'; // Default to India, adjust as needed
    }

    await ref.read(authProvider.notifier).sendOtp(phone);

    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error == null) {
      context.push('/otp-verify', extra: phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final isNew = await ref.read(authProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      if (isNew || !auth.user!.hasFamily) {
        context.go('/family-setup');
      } else {
        context.go('/home');
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(auth.error!),
            backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final name = _nameController.text.trim().isEmpty ? null : _nameController.text.trim();
    final isNew = await ref.read(authProvider.notifier).signInWithEmail(email, name: name);

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      if (isNew || !auth.user!.hasFamily) {
        context.go('/family-setup');
      } else {
        context.go('/home');
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo & Title
              const Center(
                child: Text('🏠', style: TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Welcome to Ghar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Get notified when visitors arrive',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showPhoneAuth) ...[
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter your phone number',
                          prefixText: '+91  ',
                        ),
                        validator: (value) {
                          if (!_showPhoneAuth) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.trim().length < 10) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _sendOtp,
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send OTP'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Your name (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _signInWithEmail,
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continue with Email'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),

              // Google Sign In
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  icon: const Text('G',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
