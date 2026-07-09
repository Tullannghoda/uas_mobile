import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import 'ticket_detail_page.dart';
import 'create_ticket_page.dart';
import '../../../admin/providers/user_management_provider.dart';

class TicketListPage extends ConsumerWidget {
  const TicketListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ticketListProvider);
    final user = ref.watch(authProvider).user;

    Future.microtask(() {
      if (user != null && !state.hasLoaded && !state.isLoading) {
        ref.read(ticketListProvider.notifier).loadTickets(user.id, user.role);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (user != null) {
                ref.read(ticketListProvider.notifier).loadTickets(user.id, user.role);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTicketPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Buat Tiket'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Filter Bar ---
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(ref: ref, value: '', label: 'Semua', current: state.filterStatus),
                  const SizedBox(width: 8),
                  _FilterChip(ref: ref, value: 'send', label: 'Send', current: state.filterStatus),
                  const SizedBox(width: 8),
                  _FilterChip(ref: ref, value: 'open', label: 'Open', current: state.filterStatus),
                  const SizedBox(width: 8),
                  _FilterChip(ref: ref, value: 'in_progress', label: 'In Progress', current: state.filterStatus),
                  const SizedBox(width: 8),
                  _FilterChip(ref: ref, value: 'resolved', label: 'Resolved', current: state.filterStatus),
                  const SizedBox(width: 8),
                  _FilterChip(ref: ref, value: 'closed', label: 'Closed', current: state.filterStatus),
                ],
              ),
            ),
          ),
          // --- Helpdesk Filter (Admin Only) ---
          if (user?.isAdmin == true)
            Consumer(
              builder: (context, ref, _) {
                final helpdeskState = ref.watch(userManagementProvider);
                if (!helpdeskState.isLoading && helpdeskState.helpdesks.isEmpty && helpdeskState.error == null) {
                  Future.microtask(() => ref.read(userManagementProvider.notifier).loadHelpdesks());
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: state.filterHelpdesk.isEmpty ? null : state.filterHelpdesk,
                    decoration: InputDecoration(
                      labelText: 'Filter Helpdesk',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua Helpdesk')),
                      ...helpdeskState.helpdesks.map((h) => DropdownMenuItem(
                            value: h.id,
                            child: Text(h.name),
                          )),
                    ],
                    onChanged: (v) => ref.read(ticketListProvider.notifier).setFilterHelpdesk(v ?? ''),
                  ),
                );
              }
            ),
          // --- Count ---
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.filteredTickets.length} tiket',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ),
          // --- List ---
          Expanded(child: _buildList(context, state)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, TicketListState state) {
    if (state.isLoading) return const AppLoadingIndicator(message: 'Memuat tiket...');
    if (state.error != null) return AppErrorView(message: state.error!);

    final tickets = state.filteredTickets;
    if (tickets.isEmpty) {
      return AppEmptyState(
        message: 'Tidak ada tiket${state.filterStatus.isNotEmpty ? ' dengan status ini' : ''}',
        icon: Icons.confirmation_number_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: tickets.length,
      itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final WidgetRef ref;
  final String value, label, current;

  const _FilterChip({required this.ref, required this.value, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    final color = value.isEmpty ? Colors.blueGrey : AppTheme.getStatusColor(value);

    return GestureDetector(
      onTap: () => ref.read(ticketListProvider.notifier).setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.ticketBlockPalette;
    final hash = ticket.id.codeUnits.fold(0, (p, e) => p + e);
    final blockColors = List.generate(6, (i) => colors[(hash * (i + 1) * 13) % colors.length]);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => TicketDetailPage(ticketId: ticket.id))),
        child: Row(
          children: [
            // --- Color Block (BatakFest-inspired) ---
            SizedBox(
              width: 10,
              height: 90,
              child: Column(
                children: blockColors
                    .map((c) => Expanded(child: Container(color: c)))
                    .toList(),
              ),
            ),
            // --- Content ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ticket.id,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
                        const Spacer(),
                        StatusBadge(status: ticket.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ticket.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(ticket.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        PriorityBadge(priority: ticket.priority),
                        const Spacer(),
                        if (ticket.comments.isNotEmpty) ...[
                          const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('${ticket.comments.length}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}