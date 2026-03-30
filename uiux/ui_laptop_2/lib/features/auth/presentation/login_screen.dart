import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';


const bool kEnableAuth = false;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut));
    _slideIn = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut)));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Email auth ────────────────────────────────────────────────────────────

   Future<void> _submitEmail() async {
    /// ✅ BYPASS
    if (!kEnableAuth) {
      if (mounted) context.go('/initialise');
      return;
    }

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        await auth.signInWithEmail(email, password);
      } else {
        await auth.createAccountWithEmail(email, password);
      }
      if (mounted) context.go('/initialise');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(
          () => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google auth ───────────────────────────────────────────────────────────

  Future<void> _submitGoogle() async {
    /// ✅ BYPASS
    if (!kEnableAuth) {
      if (mounted) context.go('/initialise');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await ref.read(authServiceProvider).signInWithGoogle();
      if (result != null && mounted) context.go('/initialise');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (_) {
      setState(() =>
          _errorMessage = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),

                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryText,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: AppColors.background, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('Researcher',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                              letterSpacing: -0.3,
                              fontFamily: 'GeneralSans')),
                    ],
                  ),
                  const SizedBox(height: 56),

                  // Headline
                  Text(
                    _isLogin ? 'Welcome\nback.' : 'Create\naccount.',
                    style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -1.5,
                        height: 1.05,
                        fontFamily: 'GeneralSans'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Sign in to continue your research.'
                        : 'Start your AI-powered research journey.',
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                        height: 1.4,
                        fontFamily: 'GeneralSans'),
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  _label('Email'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  _label('Password'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _passwordCtrl,
                    hint: '••••••••',
                    obscureText: !_passwordVisible,
                    suffix: GestureDetector(
                      onTap: () => setState(
                          () => _passwordVisible = !_passwordVisible),
                      child: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),

                  // Forgot password
                  if (_isLogin) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          final email = _emailCtrl.text.trim();
                          if (email.isEmpty) {
                            setState(() => _errorMessage =
                                'Enter your email first.');
                            return;
                          }
                          try {
                            await ref
                                .read(authServiceProvider)
                                .sendPasswordResetEmail(email);
                            if (mounted) {
                              setState(() => _errorMessage =
                                  'Reset email sent to $email');
                            }
                          } catch (_) {
                            setState(() => _errorMessage =
                                'Could not send reset email.');
                          }
                        },
                        child: const Text('Forgot password?',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                                fontFamily: 'GeneralSans')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _errorMessage!.startsWith('Reset')
                            ? AppColors.success.withAlpha(25)
                            : AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _errorMessage!.startsWith('Reset')
                              ? AppColors.success.withAlpha(76)
                              : AppColors.error.withAlpha(76),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.startsWith('Reset')
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            size: 15,
                            color: _errorMessage!.startsWith('Reset')
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _errorMessage!.startsWith('Reset')
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontFamily: 'GeneralSans')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Primary CTA
                  PrimaryButton(
                    label: _isLogin ? 'Sign in' : 'Create account',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submitEmail,
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                          child:
                              Divider(color: AppColors.border, height: 1)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                                fontFamily: 'GeneralSans')),
                      ),
                      const Expanded(
                          child:
                              Divider(color: AppColors.border, height: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google sign-in
                  PrimaryButton(
                    label: 'Continue with Google',
                    variant: PrimaryButtonVariant.outlined,
                    icon: Icons.g_mobiledata_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submitGoogle,
                  ),
                  const SizedBox(height: 32),

                  // Toggle auth mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                            fontFamily: 'GeneralSans'),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                        }),
                        child: Text(
                          _isLogin ? 'Sign up' : 'Sign in',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                              fontFamily: 'GeneralSans'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryText,
          letterSpacing: 0.2,
          fontFamily: 'GeneralSans'));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
            fontSize: 15,
            color: AppColors.primaryText,
            fontFamily: 'GeneralSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              fontFamily: 'GeneralSans'),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: suffix)
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}
