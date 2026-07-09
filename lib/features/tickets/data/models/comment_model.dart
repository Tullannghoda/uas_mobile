class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String content;
  final String createdAt;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'] ?? '',
    userId: json['user_id'] ?? '',
    userName: json['user_name'] ?? '',
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    createdAt: json['created_at'] ?? '',
  );
}
