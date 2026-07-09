import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/ticket_model.dart';
import '../data/repositories/ticket_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

// ─── Ticket List State ────────────────────────────────────────────────────────
class TicketListState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final String? error;
  final String filterStatus; // '' = all
  final String filterHelpdesk; // '' = all helpdesks
  final bool hasLoaded;

  const TicketListState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus = '',
    this.filterHelpdesk = '',
    this.hasLoaded = false,
  });

  List<TicketModel> get filteredTickets {
    var result = tickets;
    if (filterStatus.isNotEmpty) {
      result = result.where((t) => t.status == filterStatus).toList();
    }
    if (filterHelpdesk.isNotEmpty) {
      result = result.where((t) => t.assignedToId == filterHelpdesk).toList();
    }
    return result;
  }

  TicketListState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    String? error,
    String? filterStatus,
    String? filterHelpdesk,
    bool? hasLoaded,
    bool clearError = false,
  }) =>
      TicketListState(
        tickets: tickets ?? this.tickets,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        filterStatus: filterStatus ?? this.filterStatus,
        filterHelpdesk: filterHelpdesk ?? this.filterHelpdesk,
        hasLoaded: hasLoaded ?? this.hasLoaded,
      );
}

// ─── Ticket List Notifier ─────────────────────────────────────────────────────
class TicketListNotifier extends StateNotifier<TicketListState> {
  final TicketRepository _repo;

  TicketListNotifier(this._repo) : super(const TicketListState());

  Future<void> loadTickets(String userId, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repo.getTickets(userId, role);
      state = state.copyWith(tickets: tickets, isLoading: false, hasLoaded: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', ''), hasLoaded: true);
    }
  }

  Future<bool> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String userId,
    required String userName,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final ticket = await _repo.createTicket(
        title: title,
        description: description,
        category: category,
        priority: priority,
        userId: userId,
        userName: userName,
        attachments: attachments,
      );
      state = state.copyWith(tickets: [ticket, ...state.tickets]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateStatus(String id, String status, String userId, String userName) async {
    final updated = await _repo.updateStatus(id, status, userId, userName);
    state = state.copyWith(
      tickets: state.tickets
          .map((t) => t.id == id ? updated : t)
          .toList(),
    );
  }

  void setFilter(String status) => state = state.copyWith(filterStatus: status);
  void setFilterHelpdesk(String helpdeskId) => state = state.copyWith(filterHelpdesk: helpdeskId);
}

// ─── Providers ────────────────────────────────────────────────────────────────
final ticketListProvider =
StateNotifierProvider<TicketListNotifier, TicketListState>((ref) {
  return TicketListNotifier(ref.watch(ticketRepositoryProvider));
});

// ─── Ticket Detail State ──────────────────────────────────────────────────────
class TicketDetailState {
  final TicketModel? ticket;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const TicketDetailState({
    this.ticket,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  TicketDetailState copyWith({
    TicketModel? ticket,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) =>
      TicketDetailState(
        ticket: ticket ?? this.ticket,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : error ?? this.error,
      );
}

class TicketDetailNotifier extends StateNotifier<TicketDetailState> {
  final TicketRepository _repo;

  TicketDetailNotifier(this._repo) : super(const TicketDetailState());

  Future<void> load(String id, String userId, String userName, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ticket = await _repo.getTicketDetail(id);
      
      // Automatically mark as read if the ticket is assigned to this helpdesk
      if (role == 'helpdesk' && ticket.assignedToId == userId && ticket.readAt == null) {
        await _repo.markAsRead(id, userId, userName);
        // reload to get updated readAt
        final updatedTicket = await _repo.getTicketDetail(id);
        state = state.copyWith(ticket: updatedTicket, isLoading: false);
      } else {
        state = state.copyWith(ticket: ticket, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addComment({
    required String userId,
    required String userName,
    required String role,
    required String content,
  }) async {
    if (state.ticket == null) return;
    state = state.copyWith(isSending: true);
    try {
      final comment = await _repo.addComment(
        ticketId: state.ticket!.id,
        userId: userId,
        userName: userName,
        role: role,
        content: content,
      );
      final updatedComments = [...state.ticket!.comments, comment];
      state = state.copyWith(
        ticket: state.ticket!.copyWith(comments: updatedComments),
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String status, String userId, String userName) async {
    if (state.ticket == null) return;
    final updated = await _repo.updateStatus(state.ticket!.id, status, userId, userName);
    state = state.copyWith(ticket: updated);
  }

  Future<void> assignTicket(String assignedTo, String assignedToId, String userId, String userName) async {
    if (state.ticket == null) return;
    final updated =
    await _repo.assignTicket(state.ticket!.id, assignedTo, assignedToId, userId, userName);
    state = state.copyWith(ticket: updated);
  }

  Future<void> deleteTicket() async {
    if (state.ticket == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteTicket(state.ticket!.id);
      state = state.copyWith(isLoading: false, ticket: null); // null indicates deleted
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final ticketDetailProvider =
StateNotifierProvider.autoDispose<TicketDetailNotifier, TicketDetailState>(
        (ref) {
      return TicketDetailNotifier(ref.watch(ticketRepositoryProvider));
    });
