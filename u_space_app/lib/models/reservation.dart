class Reservation {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String type;
  final String? eventName;
  final String hallId;
  final String? courseId;
  final String reservedBy;

  Reservation({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.type,
    this.eventName,
    required this.hallId,
    this.courseId,
    required this.reservedBy,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      date: json['date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      type: json['type'],
      eventName: json['event_name'],
      hallId: json['hall_id'],
      courseId: json['course_id'],
      reservedBy: json['reserved_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'type': type,
      'event_name': eventName,
      'hall_id': hallId,
      'course_id': courseId,
      'reserved_by': reservedBy,
    };
  }
}
