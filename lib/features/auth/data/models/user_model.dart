class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? department;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.department,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'user',
    phone: json['phone'],
    department: json['department'],
    avatar: json['avatar_url'] ?? json['avatar'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'department': department,
    'avatar_url': avatar,
  };

  bool get isAdmin => role == 'admin';
  bool get isHelpdesk => role == 'helpdesk';
  bool get isUser => role == 'user';
  bool get canManageTickets => isAdmin || isHelpdesk;

  String get roleLabel {
    switch (role) {
      case 'admin': return 'Administrator';
      case 'helpdesk': return 'Helpdesk';
      default: return 'User';
    }
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? department,
    String? avatar,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role,
    phone: phone ?? this.phone,
    department: department ?? this.department,
    avatar: avatar ?? this.avatar,
  );
}