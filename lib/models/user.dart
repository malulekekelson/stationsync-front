class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? department;
  final String? companyName;
  final String? phone;
  final bool twoFactorEnabled;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.department,
    this.companyName,
    this.phone,
    this.twoFactorEnabled = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      department: json['department'],
      companyName: json['company_name'],
      phone: json['phone'],
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isApplicant => role == 'applicant';
  bool get isOfficer => role == 'officer';
  bool get isSuperAdmin => role == 'super_admin';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'department': department,
      'company_name': companyName,
      'phone': phone,
      'two_factor_enabled': twoFactorEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
