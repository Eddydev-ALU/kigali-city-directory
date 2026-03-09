import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final authStateAsync = ref.watch(authStateChangesProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Profile Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: userAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                  error: (e, _) => authStateAsync.when(
                    data: (user) => _ProfileInfo(
                      name: user?.displayName ?? 'User',
                      email: user?.email ?? '',
                      createdAt: null,
                    ),
                    loading: () =>
                        const CircularProgressIndicator(color: AppColors.white),
                    error: (e, _) => const Text(
                      'Could not load profile',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ),
                  data: (user) {
                    if (user == null) {
                      final firebaseUser = authStateAsync.asData?.value;
                      return _ProfileInfo(
                        name: firebaseUser?.displayName ?? 'User',
                        email: firebaseUser?.email ?? '',
                        createdAt: null,
                      );
                    }
                    return _ProfileInfo(
                      name: user.displayName,
                      email: user.email,
                      createdAt: user.createdAt,
                    );
                  },
                ),
              ),

              // Email verification status
              authStateAsync.when(
                data: (user) {
                  if (user == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: user.emailVerified
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: user.emailVerified
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user.emailVerified
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          color: user.emailVerified
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          user.emailVerified
                              ? 'Email verified'
                              : 'Email not verified',
                          style: TextStyle(
                            color: user.emailVerified
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Settings Sections
              _SectionHeader(title: 'Notifications'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.accentYellow,
                title: 'Location Notifications',
                subtitle: settings.notificationsEnabled
                    ? 'Enabled – you will receive nearby alerts'
                    : 'Disabled – enable to get nearby alerts',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (v) => ref
                      .read(settingsNotifierProvider.notifier)
                      .toggleNotifications(v),
                  activeThumbColor: AppColors.primaryBlue,
                  activeTrackColor: AppColors.lightBlue.withAlpha(100),
                ),
              ),

              const SizedBox(height: 8),
              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.lightBlue,
                title: 'Email Address',
                subtitle: authStateAsync.asData?.value?.email ?? '—',
              ),
              _SettingsTile(
                icon: Icons.person_outlined,
                iconColor: AppColors.primaryBlue,
                title: 'Display Name',
                subtitle: authStateAsync.asData?.value?.displayName ?? '—',
              ),

              const SizedBox(height: 8),
              _SectionHeader(title: 'App'),
              _SettingsTile(
                icon: Icons.info_outlined,
                iconColor: AppColors.textMedium,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.location_city_rounded,
                iconColor: AppColors.primaryBlue,
                title: 'About',
                subtitle: 'Kigali City Directory – Discover services & places',
              ),

              const SizedBox(height: 16),

              // Sign Out
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: authState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(30),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 28,
                                      ),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF0A2463),
                                            Color(0xFF1E3B96),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(25),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withAlpha(
                                                  60,
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.logout_rounded,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Sign Out',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Body
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        24,
                                        24,
                                        8,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Are you sure you want to sign out of your account?',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.grey.shade600,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      side: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFD32F2F),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: const Text(
                                                    'Sign Out',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                          if (confirm == true) {
                            ref.read(authNotifierProvider.notifier).signOut();
                          }
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final String name;
  final String email;
  final DateTime? createdAt;

  const _ProfileInfo({
    required this.name,
    required this.email,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.accentYellow,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.white.withAlpha(200),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Member since ${DateFormat('MMM y').format(createdAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withAlpha(160),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
