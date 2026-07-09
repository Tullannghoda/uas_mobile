import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_management_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(userManagementProvider.notifier).loadHelpdesks());
  }

  void _showAddHelpdeskDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Helpdesk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ref
                    .read(userManagementProvider.notifier)
                    .createHelpdesk(
                      name: nameCtrl.text,
                      email: emailCtrl.text,
                      password: passCtrl.text,
                    );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Berhasil menambah helpdesk')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(userManagementProvider.notifier).loadHelpdesks(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHelpdeskDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah'),
      ),
      body: state.isLoading
          ? const AppLoadingIndicator()
          : state.error != null
              ? AppErrorView(message: state.error!)
              : state.helpdesks.isEmpty
                  ? const AppEmptyState(
                      message: 'Tidak ada staff helpdesk',
                      icon: Icons.people_outline,
                    )
                  : ListView.builder(
                      itemCount: state.helpdesks.length,
                      itemBuilder: (context, index) {
                        final user = state.helpdesks[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.secondary,
                            child: Text(user.name[0]),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Detail User'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nama: ${user.name}'),
                                    const SizedBox(height: 8),
                                    Text('Email: ${user.email}'),
                                    const SizedBox(height: 8),
                                    Text('Role: ${user.roleLabel}'),
                                    const SizedBox(height: 8),
                                    Text('Telepon: ${user.phone ?? "-"}'),
                                    const SizedBox(height: 8),
                                    Text('Departemen: ${user.department ?? "-"}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Tutup'),
                                  ),
                                ],
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.block, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Nonaktifkan User?'),
                                  content: Text('Apakah Anda yakin ingin menonaktifkan ${user.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        ref.read(userManagementProvider.notifier).deleteHelpdesk(user.id);
                                      },
                                      child: const Text('Nonaktifkan'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
