class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String action;
  final String? oldValue;
  final String? newValue;
  final String performedByName;
  final String createdAt;

  const TicketHistoryModel({
    required this.id,
    required this.ticketId,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.performedByName,
    required this.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketHistoryModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      action: json['action'] ?? '',
      oldValue: json['old_value'],
      newValue: json['new_value'],
      performedByName: json['performed_by_name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
