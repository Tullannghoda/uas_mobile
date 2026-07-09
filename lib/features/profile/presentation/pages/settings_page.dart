import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tampilan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.amber : Colors.blueGrey),
                    title: Text(isDark ? 'Mode Gelap' : 'Mode Terang'),
                    subtitle: const Text('Ganti tampilan aplikasi'),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
                      activeThumbColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifikasi Push'),
                    subtitle: const Text('Terima pemberitahuan perubahan tiket'),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeThumbColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tentang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Versi Aplikasi'),
                    subtitle: Text('E-Helpdesk v2.0.0'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text('Universitas'),
                    subtitle: Text('DIV Teknik Informatika - Universitas Airlangga'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
