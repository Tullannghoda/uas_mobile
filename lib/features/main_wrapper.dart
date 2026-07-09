import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/providers/auth_provider.dart';
import 'notification/providers/notification_provider.dart';
import 'dashboard/presentation/pages/dashboard_page.dart';
import 'tickets/presentation/pages/ticket_list_page.dart';
import 'notification/presentation/pages/notification_page.dart';
import 'profile/presentation/pages/profile_page.dart';
import 'admin/presentation/pages/user_management_page.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(bottomNavIndexProvider);
    final user = ref.watch(authProvider).user;
    final notifState = ref.watch(notificationProvider);

    // Load notifications once
    if (user != null && !notifState.hasLoaded && !notifState.isLoading) {
      Future.microtask(() =>
          ref.read(notificationProvider.notifier).load(user.id));
    }

    final isAdmin = user?.isAdmin ?? false;

    final pages = [
      const DashboardPage(),
      const TicketListPage(),
      const NotificationPage(),
      if (isAdmin) const UserManagementPage(),
      const ProfilePage(),
    ];

    final safeIdx = idx < pages.length ? idx : 0;

    return Scaffold(
      body: pages[safeIdx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIdx,
        onDestinationSelected: (i) =>
        ref.read(bottomNavIndexProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notifState.unreadCount > 0,
              label: Text('${notifState.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Kelola',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}