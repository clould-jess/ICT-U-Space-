class CourseRef {
  final String id;
  final String code;
  final String name;

  CourseRef({required this.id, required this.code, required this.name});

  factory CourseRef.fromJson(Map<String, dynamic> json) => CourseRef(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
  );
}

class User {
  final String id;
  final String name;
  final String email;
  final String role; // "STUDENT", "PREFECT", "LECTURER", "ADMIN"
  final String? matricule; // "ICTULEC..." for lecturers, "ICTU..." for students
  final String? academicLevel;
  final String? semester;
  final String? major; // department code: "ICT", "ACC", "BMS", etc.
  final List<CourseRef> coursesTaught;
  final List<CourseRef> enrolledIn;
  final List<CourseRef> coursesDelegated;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.matricule,
    this.academicLevel,
    this.semester,
    this.major,
    this.coursesTaught = const [],
    this.enrolledIn = const [],
    this.coursesDelegated = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<CourseRef> _parseCourses(dynamic raw) {
      if (raw == null) return const [];
      return (raw as List<dynamic>)
          .map((c) => CourseRef.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      matricule: json['matricule'] as String?,
      academicLevel: json['academic_level'] as String?,
      semester: json['semester'] as String?,
      major: json['major'] as String?,
      coursesTaught: _parseCourses(json['coursesTaught']),
      enrolledIn: _parseCourses(json['enrolledIn']),
      coursesDelegated: _parseCourses(json['coursesDelegated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'matricule': matricule,
      'academic_level': academicLevel,
      'semester': semester,
    };
  }
}
