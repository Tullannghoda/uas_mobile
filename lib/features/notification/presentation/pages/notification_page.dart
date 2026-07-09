import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../../auth/providers/auth_provider.dart';

import '../../../tickets/presentation/pages/ticket_detail_page.dart';
import '../../../../core/widgets/common_widgets.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'ticket_update': return Icons.swap_horiz;
      case 'ticket_resolved': return Icons.check_circle;
      case 'new_comment': return Icons.chat_bubble;
      default: return Icons.notifications;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'ticket_resolved': return Colors.green;
      case 'ticket_update': return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state.unreadCount > 0)
            Consumer(builder: (context, ref, _) {
              final user = ref.read(authProvider).user;
              return TextButton(
                onPressed: () {
                  if (user != null) ref.read(notificationProvider.notifier).markAllRead(user.id);
                },
                child: const Text('Tandai Semua', style: TextStyle(color: Colors.white)),
              );
            }),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingIndicator()
          : state.notifications.isEmpty
          ? const AppEmptyState(message: 'Tidak ada notifikasi', icon: Icons.notifications_none_outlined)
          : ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = state.notifications[i];
          final isRead = n['is_read'] as bool;
          final type = n['type'] as String;
          return ListTile(
            tileColor: isRead ? null : _colorFor(type).withValues(alpha: 0.05),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _colorFor(type).withValues(alpha: 0.15),
                  child: Icon(_iconFor(type), color: _colorFor(type), size: 20),
                ),
                if (!isRead)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _colorFor(type),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(n['title'],
                style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['message'], style: const TextStyle(fontSize: 13)),
                Text(n['created_at'].toString().substring(0, 16).replaceFirst('T', ' '),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              ref.read(notificationProvider.notifier).markRead(n['id']);
              if (n['ticket_id'] != null) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TicketDetailPage(ticketId: n['ticket_id'])));
              }
            },
          );
        },
      ),
    );
  }
}