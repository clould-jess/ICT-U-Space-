class Course {
  final String id;
  final String code;
  final String name;
  final int enrolledCount;
  final String? lecturerId;
  final String? delegateId;
  final String? lecturerName;
  final String? delegateName;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.enrolledCount,
    this.lecturerId,
    this.delegateId,
    this.lecturerName,
    this.delegateName,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      // Prefer live _count.students from the API; fall back to the static field
      enrolledCount: ((json['_count'] as Map<String, dynamic>?)?['students'] as num?)?.toInt()
          ?? (json['enrolled_count'] as num?)?.toInt()
          ?? 0,
      lecturerId: json['lecturer_id'] as String?,
      delegateId: json['delegate_id'] as String?,
      lecturerName: (json['lecturer'] as Map<String, dynamic>?)?['name'] as String?,
      delegateName: (json['delegate'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'enrolled_count': enrolledCount,
      'lecturer_id': lecturerId,
      'delegate_id': delegateId,
    };
  }
}
