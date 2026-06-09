class UserModel {
  final String id;
  final String username;
  final String role; // 'driver' | 'admin'
  final DateTime createdAt;

  // Derived fake email used internally for Supabase Auth — kept package-private
  String get fakeEmail => '${username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}@dap.local';

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
