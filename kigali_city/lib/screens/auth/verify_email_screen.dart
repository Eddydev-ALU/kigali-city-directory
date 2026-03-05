import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _resendCooldown = false;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds. When the user has clicked the link:
    //  1. reload() pulls the latest emailVerified flag from Firebase.
    //  2. getIdToken(true) forces a token refresh which causes the
    //     idTokenChanges() stream (used by authStateChangesProvider) to
    //     re-emit with the updated user, so AuthWrapper navigates home.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed?.emailVerified == true) {
        _timer?.cancel();
        // Force idTokenChanges stream to emit the now-verified user.
        await refreshed?.getIdToken(true);
        // Invalidate the Riverpod auth provider so AuthWrapper re-evaluates
        // with the fresh emailVerified = true state.
        if (mounted) ref.invalidate(authStateChangesProvider);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _resendCooldown = true);
    await ref.read(authNotifierProvider.notifier).resendVerification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    // Keep cooldown for 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _resendCooldown = false);
    });
  }

  Future<void> _checkManually() async {
    setState(() => _checking = true);
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    if (refreshed?.emailVerified == true) {
      // Force idTokenChanges stream to emit the now-verified user.
      await refreshed?.getIdToken(true);
      // Invalidate so AuthWrapper immediately re-routes to HomeScreen.
      if (mounted) ref.invalidate(authStateChangesProvider);
    } else if (mounted) {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not yet verified. Please check your inbox.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 120),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 56,
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to:\n${user?.email ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your inbox and click the link to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMedium),
              ),
              const SizedBox(height: 40),
              _checking
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _checkManually,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('I\'ve Verified My Email'),
                    ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _resendCooldown ? null : _resend,
                child: Text(
                  _resendCooldown
                      ? 'Email Sent (wait 30s)'
                      : 'Resend Verification Email',
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
