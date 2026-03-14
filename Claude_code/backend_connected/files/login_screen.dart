import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/desktop_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dt.bgPage,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Brand ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Dt.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.biotech_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Researcher',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Dt.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                const Text('Sign in to your workspace',
                    style: Dt.pageTitle),
                const SizedBox(height: 6),
                const Text(
                  'Enter your credentials to access the research platform.',
                  style: Dt.bodyMd,
                ),
                const SizedBox(height: 32),

                // ── Email ──────────────────────────────────────────────
                const Text('Email', style: Dt.bodyMd),
                const SizedBox(height: 6),
                _inputField(
                  controller: _emailCtrl,
                  hint:       'you@example.com',
                  type:       TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // ── Password ───────────────────────────────────────────
                const Text('Password', style: Dt.bodyMd),
                const SizedBox(height: 6),
                _inputField(
                  controller: _passCtrl,
                  hint:       '••••••••',
                  obscure:    true,
                  onSubmit:   () => _enter(context),
                ),
                const SizedBox(height: 24),

                // ── Button ─────────────────────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : () => _enter(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Dt.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dt.inputRadius),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    'Authentication is optional — credentials are not validated.',
                    style: Dt.bodySm.copyWith(color: Dt.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    VoidCallback? onSubmit,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        onSubmitted: onSubmit != null ? (_) => onSubmit() : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 13, color: Dt.textMuted),
          filled: true,
          fillColor: Dt.bgInput,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dt.inputRadius),
            borderSide: const BorderSide(color: Dt.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dt.inputRadius),
            borderSide: const BorderSide(color: Dt.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dt.inputRadius),
            borderSide:
                const BorderSide(color: Dt.borderFocus, width: 1.5),
          ),
        ),
        style:
            const TextStyle(fontSize: 13, color: Dt.textPrimary),
      );

  void _enter(BuildContext context) {
    setState(() => _loading = true);
    // Backend has no auth requirement — navigate directly after a brief delay.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _loading = false);
        context.go('/desktop/dashboard');
      }
    });
  }
}
