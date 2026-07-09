import '../../../../core/services/supabase_service.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardRepository {
  final _supabase = SupabaseService.client;

  Future<Map<String, dynamic>> getDashboardData(String userId, String role) async {
    var query = _supabase.from('tickets').select('status, priority');

    if (role == AppConstants.roleUser) {
      query = query.eq('user_id', userId);
    } else if (role == AppConstants.roleHelpdesk) {
      query = query.eq('assigned_to_id', userId);
    }
    // Admin sees all

    final data = await query;
    
    int total = data.length;
    int send = data.where((e) => e['status'] == 'send').length;
    int open = data.where((e) => e['status'] == 'open').length;
    int inProgress = data.where((e) => e['status'] == 'in_progress').length;
    int resolved = data.where((e) => e['status'] == 'resolved').length;
    int closed = data.where((e) => e['status'] == 'closed').length;

    int highPriority = data.where((e) => e['priority'] == 'high').length;

    var recentQuery = _supabase.from('tickets').select('id, title, category, status, created_at');
    if (role == AppConstants.roleUser) {
      recentQuery = recentQuery.eq('user_id', userId);
    } else if (role == AppConstants.roleHelpdesk) {
      recentQuery = recentQuery.eq('assigned_to_id', userId);
    }
    final recentData = await recentQuery.order('created_at', ascending: false).limit(3);

    // Mapping Supabase field 'created_at' to 'createdAt' for UI compatibility
    final recentTickets = recentData.map((e) => {
      'id': e['id'],
      'title': e['title'],
      'category': e['category'],
      'status': e['status'],
      'createdAt': e['created_at'],
    }).toList();

    return {
      'total': total,
      'send': send,
      'open': open,
      'in_progress': inProgress,
      'resolved': resolved,
      'closed': closed,
      'high_priority': highPriority,
      'recentTickets': recentTickets,
    };
  }
}