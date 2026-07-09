import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'helpdesk': return AppTheme.secondary;
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) return const SizedBox();
    final rColor = _roleColor(user.role);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08)),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: rColor,
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: rColor, shape: BoxShape.circle),
                          child: Icon(
                            user.isAdmin ? Icons.admin_panel_settings : user.isHelpdesk ? Icons.support_agent : Icons.person,
                            size: 16, color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: rColor, borderRadius: BorderRadius.circular(12)),
                    child: Text(user.roleLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
            // --- Info ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(icon: Icons.badge, label: 'ID Pengguna', value: user.id),
                        const Divider(height: 1),
                        _InfoTile(icon: Icons.email, label: 'Email', value: user.email),
                        const Divider(height: 1),
                        _InfoTile(icon: Icons.phone, label: 'Telepon', value: user.phone ?? '-'),
                        const Divider(height: 1),
                        _InfoTile(icon: Icons.business, label: 'Departemen', value: user.department ?? '-'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Pengaturan Aplikasi'),
                      subtitle: const Text('Tampilan, notifikasi, dan lainnya'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, ref),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Keluar', style: TextStyle(color: Colors.red, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text('E-Helpdesk v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}