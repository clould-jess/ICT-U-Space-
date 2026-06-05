class Course {
  final String id;
  final String code;
  final String name;
  final int enrolledCount;
  final String lecturerId;
  final String? delegateId;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.enrolledCount,
    required this.lecturerId,
    this.delegateId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      enrolledCount: json['enrolled_count'],
      lecturerId: json['lecturer_id'],
      delegateId: json['delegate_id'],
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
