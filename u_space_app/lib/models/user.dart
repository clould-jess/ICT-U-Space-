class User {
  final String id;
  final String name;
  final String email;
  final String role; // "STUDENT", "PREFECT", "LECTURER", "ADMIN"
  final String? academicLevel;
  final String? semester;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academicLevel,
    this.semester,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      academicLevel: json['academic_level'],
      semester: json['semester'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'academic_level': academicLevel,
      'semester': semester,
    };
  }
}
