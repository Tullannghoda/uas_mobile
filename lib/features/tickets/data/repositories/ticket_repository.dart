import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ticket_model.dart';
import '../models/comment_model.dart';

class TicketRepository {
  final _supabase = SupabaseService.client;

  Future<List<TicketModel>> getTickets(String userId, String role) async {
    var query = _supabase.from('tickets').select('''
      *,
      comments (*),
      ticket_history (*),
      attachments (*)
    ''');

    if (role == AppConstants.roleUser) {
      query = query.eq('user_id', userId);
    } else if (role == AppConstants.roleHelpdesk) {
      query = query.eq('assigned_to_id', userId);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((e) => TicketModel.fromJson(e)).toList();
  }

  Future<TicketModel> getTicketDetail(String id) async {
    final data = await _supabase.from('tickets').select('''
      *,
      comments (*),
      ticket_history (*),
      attachments (*)
    ''').eq('id', id).single();
    
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required String userId,
    required String userName,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final ticketData = await _supabase.from('tickets').insert({
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'user_id': userId,
      'user_name': userName,
      'status': AppConstants.statusSend,
    }).select().single();

    final ticketId = ticketData['id'];

    // History creation
    await _supabase.from('ticket_history').insert({
      'ticket_id': ticketId,
      'action': 'created',
      'performed_by_id': userId,
      'performed_by_name': userName,
    });

    // Handle attachments
    for (final file in attachments) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file['name']}';
      
      try {
        await _supabase.storage.from('attachments').uploadBinary(
          fileName,
          file['bytes'],
        );
        
        final publicUrl = _supabase.storage.from('attachments').getPublicUrl(fileName);

        await _supabase.from('attachments').insert({
          'ticket_id': ticketId,
          'file_url': publicUrl,
          'file_name': fileName,
          'uploaded_by': userId,
        });
      } catch (uploadError) {
        print('Gagal upload gambar $fileName: $uploadError');
        // Lanjut ke file berikutnya, jangan sampai menggagalkan pembuatan tiket
      }
    }

    // Notify all Admins
    try {
      final admins = await _supabase.from('profiles').select('id').eq('role', 'admin');
      if (admins.isNotEmpty) {
        final notifications = admins.map((admin) => {
          'user_id': admin['id'],
          'title': 'Tiket Baru Dibuat',
          'message': '$userName telah membuat tiket baru: $title',
          'ticket_id': ticketId,
          'type': 'ticket_created',
        }).toList();
        await _supabase.from('notifications').insert(notifications);
      }
    } catch (e) {
      // Ignore notification errors to not break ticket creation
      print('Error notifying admins: $e');
    }

    return getTicketDetail(ticketId);
  }

  Future<TicketModel> updateStatus(String id, String status, String userId, String userName) async {
    final updateData = <String, dynamic>{
      'status': status,
    };
    
    if (status == AppConstants.statusInProgress) {
      updateData['in_progress_at'] = DateTime.now().toIso8601String();
    } else if (status == AppConstants.statusResolved) {
      updateData['resolved_at'] = DateTime.now().toIso8601String();
    } else if (status == AppConstants.statusClosed) {
      updateData['closed_at'] = DateTime.now().toIso8601String();
    }

    await _supabase.from('tickets').update(updateData).eq('id', id);

    await _supabase.from('ticket_history').insert({
      'ticket_id': id,
      'action': 'status_updated',
      'new_value': status,
      'performed_by_id': userId,
      'performed_by_name': userName,
    });

    // Notify the ticket owner about status change
    try {
      final ticket = await _supabase.from('tickets').select('user_id, title').eq('id', id).single();
      final ticketOwnerId = ticket['user_id'];
      // Only notify if the person changing status is NOT the ticket owner
      if (ticketOwnerId != userId) {
        final statusLabel = {
          'send': 'Send',
          'open': 'Open',
          'in_progress': 'In Progress',
          'resolved': 'Resolved',
          'closed': 'Closed',
        };
        await _supabase.from('notifications').insert({
          'user_id': ticketOwnerId,
          'title': 'Status Tiket Diperbarui',
          'message': 'Tiket "${ticket['title']}" diubah ke ${statusLabel[status] ?? status}',
          'ticket_id': id,
          'type': 'status_updated',
        });
      }
    } catch (e) {
      print('Error notifying user: $e');
    }

    return getTicketDetail(id);
  }

  Future<TicketModel> assignTicket(
      String id, String assignedTo, String assignedToId, String userId, String userName) async {
    
    await _supabase.from('tickets').update({
      'assigned_to_name': assignedTo,
      'assigned_to_id': assignedToId,
      'status': AppConstants.statusInProgress,
      'assigned_at': DateTime.now().toIso8601String(),
      'in_progress_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _supabase.from('ticket_history').insert({
      'ticket_id': id,
      'action': 'assigned',
      'new_value': assignedTo,
      'performed_by_id': userId,
      'performed_by_name': userName,
    });

    try {
      final ticket = await _supabase.from('tickets').select('title, user_id').eq('id', id).single();
      
      // 1. Notifikasi ke Helpdesk
      await _supabase.from('notifications').insert({
        'user_id': assignedToId,
        'title': 'Tiket Di-assign',
        'message': 'Admin menugaskan tiket kepadamu: ${ticket['title']}',
        'ticket_id': id,
        'type': 'ticket_assigned',
      });
      
      // 2. Notifikasi ke User (Pelapor)
      await _supabase.from('notifications').insert({
        'user_id': ticket['user_id'],
        'title': 'Tiket Diproses',
        'message': 'Tiketmu "${ticket['title']}" telah ditugaskan ke Teknisi: $assignedTo',
        'ticket_id': id,
        'type': 'ticket_assigned',
      });
    } catch (e) {
      print('Error notifying: $e');
    }

    return getTicketDetail(id);
  }
  
  Future<void> markAsRead(String id, String userId, String userName) async {
    // Only mark as read if it hasn't been read yet
    final ticket = await _supabase.from('tickets').select('read_at, status').eq('id', id).single();
    if (ticket['read_at'] == null) {
      final now = DateTime.now().toIso8601String();
      await _supabase.from('tickets').update({
        'read_at': now,
        'status': AppConstants.statusOpen,
      }).eq('id', id);
      
      await _supabase.from('ticket_history').insert({
        'ticket_id': id,
        'action': 'read',
        'performed_by_id': userId,
        'performed_by_name': userName,
      });

      await _supabase.from('ticket_history').insert({
        'ticket_id': id,
        'action': 'status_updated',
        'new_value': AppConstants.statusOpen,
        'performed_by_id': userId,
        'performed_by_name': userName,
      });
    }
  }

  Future<CommentModel> addComment({
    required String ticketId,
    required String userId,
    required String userName,
    required String role,
    required String content,
  }) async {
    final data = await _supabase.from('comments').insert({
      'ticket_id': ticketId,
      'user_id': userId,
      'user_name': userName,
      'role': role,
      'content': content,
    }).select().single();
    
    // Create Notification to ticket owner and assignee
    // (Simplified logic here)
    
    return CommentModel.fromJson(data);
  }

  Future<void> deleteTicket(String id) async {
    // Hapus data terkait secara manual untuk menghindari Foreign Key Constraint error
    // jika ON DELETE CASCADE belum diatur dengan sempurna di semua tabel (terutama notifications)
    try {
      await _supabase.from('notifications').delete().eq('ticket_id', id);
      await _supabase.from('ticket_history').delete().eq('ticket_id', id);
      await _supabase.from('comments').delete().eq('ticket_id', id);
      await _supabase.from('attachments').delete().eq('ticket_id', id);
      
      // Hapus tiket utama
      await _supabase.from('tickets').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus tiket: $e');
    }
  }
}