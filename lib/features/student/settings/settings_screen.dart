import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/widgets/premium_card.dart';
import '../../../core/theme/theme_provider.dart';
import '../../admin/widgets/admin_page_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/student_page_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notifKey = 'notifications_enabled';

  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPrefsProvider);
      setState(() => notificationsEnabled = prefs.getBool(_notifKey) ?? true);
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_notifKey, value);
    setState(() => notificationsEnabled = value);

    if (value) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final user = ref.watch(authNotifierProvider).user;

    final segments = <({AppThemePreference pref, IconData icon, String label})>[
      (pref: AppThemePreference.system, icon: Icons.brightness_auto_rounded, label: 'System'),
      (pref: AppThemePreference.light, icon: Icons.light_mode_rounded, label: 'Light'),
      (pref: AppThemePreference.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
    ];

    final list = ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s40),
        children: [
          Text(
            'Make TestSprint feel like home.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s20),
          const SectionHeader(title: 'Experience', subtitle: 'Appearance and notifications'),
          PremiumCard(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.s12),
                SegmentedButton<AppThemePreference>(
                  segments: segments
                      .map(
                        (s) => ButtonSegment<AppThemePreference>(
                          value: s.pref,
                          label: Text(s.label),
                          icon: Icon(s.icon, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {
                    switch (themeMode) {
                      ThemeMode.light => AppThemePreference.light,
                      ThemeMode.dark => AppThemePreference.dark,
                      ThemeMode.system => AppThemePreference.system,
                    },
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) async {
                    await ref.read(themeControllerProvider.notifier).setPreference(selection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
              title: const Text('Notifications'),
              subtitle: const Text('Local reminders (push can be wired later).'),
              value: notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Announcements'),
              subtitle: const Text('In-app messages from your institute'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/notifications'),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const SectionHeader(title: 'Account', subtitle: 'Security and session'),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/password'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                  title: Text('Log out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
    );

    if (user != null && !user.isStudent) {
      return AdminPageScaffold(title: 'Settings', body: list);
    }
    return StudentPageScaffold(title: 'Settings', body: list);
  }
}
