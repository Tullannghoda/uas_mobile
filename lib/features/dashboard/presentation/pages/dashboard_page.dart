import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../tickets/presentation/pages/ticket_detail_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../main_wrapper.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).user;

    Future.microtask(() {
      if (user != null && dashboard.data == null && !dashboard.isLoading) {
        ref.read(dashboardProvider.notifier).load(user.id, user.role);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (user != null)
              Text(
                'Halo, ${user.name.split(' ').first}!',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          if (user != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  user.roleLabel,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: dashboard.isLoading
          ? const AppLoadingIndicator(message: 'Memuat dashboard...')
          : dashboard.error != null
          ? AppErrorView(
        message: dashboard.error!,
        onRetry: () {
          if (user != null) {
            ref.read(dashboardProvider.notifier).load(user.id, user.role);
          }
        },
      )
          : _buildBody(context, ref, dashboard.data!, user),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Map<String, dynamic> data, dynamic user) {
    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await ref.read(dashboardProvider.notifier).load(user.id, user.role);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Stat Cards ---
            SectionHeader(title: 'Ringkasan Tiket'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  label: 'Total',
                  value: data['total'] ?? 0,
                  color: Colors.blueGrey,
                  icon: Icons.confirmation_number,
                ),
                _StatCard(
                  label: 'Send',
                  value: data['send'] ?? 0,
                  color: AppTheme.statusSend,
                  icon: Icons.send,
                ),
                _StatCard(
                  label: 'Open',
                  value: data['open'] ?? 0,
                  color: AppTheme.statusOpen,
                  icon: Icons.fiber_new,
                ),
                _StatCard(
                  label: 'In Progress',
                  value: data['in_progress'] ?? 0,
                  color: AppTheme.statusInProgress,
                  icon: Icons.autorenew,
                ),
                _StatCard(
                  label: 'Resolved',
                  value: data['resolved'] ?? 0,
                  color: AppTheme.statusResolved,
                  icon: Icons.check_circle_outline,
                ),
                _StatCard(
                  label: 'Closed',
                  value: data['closed'] ?? 0,
                  color: AppTheme.statusClosed,
                  icon: Icons.lock_outline,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Quick Action ---
            if (user != null && user.isUser) ...[
              SectionHeader(title: 'Aksi Cepat'),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat Tiket Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Text(
                            'Laporkan masalah IT kamu',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- Recent Tickets ---
            SectionHeader(
              title: 'Tiket Terbaru',
              action: 'Lihat Semua',
              onAction: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
            ),
            const SizedBox(height: 12),
            if ((data['recentTickets'] as List?)?.isEmpty ?? true)
              const AppEmptyState(
                message: 'Belum ada tiket',
                icon: Icons.inbox_outlined,
              )
            else
              ...List.generate(
                (data['recentTickets'] as List).length,
                    (i) {
                  final t = data['recentTickets'][i] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _TicketColorBlock(ticketId: t['id']),
                      title: Text(
                        t['title'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${t['category']} • ${t['createdAt'].toString().substring(0, 10)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: StatusBadge(status: t['status'], small: true),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailPage(ticketId: t['id']),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketColorBlock extends StatelessWidget {
  final String ticketId;

  const _TicketColorBlock({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.ticketBlockPalette;
    final hash = ticketId.codeUnits.fold(0, (p, e) => p + e);
    final blockColors = List.generate(
      3,
          (i) => colors[(hash * (i + 3)) % colors.length],
    );

    return SizedBox(
      width: 30,
      height: 36,
      child: Column(
        children: blockColors
            .map((c) => Expanded(child: Container(color: c)))
            .toList(),
      ),
    );
  }
}
