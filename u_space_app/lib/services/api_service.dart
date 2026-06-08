import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../models/reservation.dart';

class CapacityWarningException implements Exception {
  final String message;
  final List<Hall> alternatives;
  CapacityWarningException(this.message, this.alternatives);
  
  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl {
    // Deployed VPS Backend
    return 'http://109.199.115.217:3000/api';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      // Send the session JSON as x-session header. We URI encode it because 
      // names like "Tchakounté" contain non-ASCII characters which crash HTTP headers.
      if (token != null) 'x-session': Uri.encodeComponent(token),
    };
  }

  // Store the session JSON string from the login/signup response body so it
  // can be sent back as the x-session header on subsequent requests.
  Future<void> _saveSessionFromBody(Map<String, dynamic> userData) async {
    final sessionJson = jsonEncode({
      'id': userData['id'],
      'name': userData['name'],
      'role': userData['role'],
      'email': userData['email'],
      'matricule': userData['matricule'],
      'academic_level': userData['academic_level'],
      'semester': userData['semester'],
      'major': userData['major'],
    });
    await saveToken(sessionJson);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<User> signup(String name, String email, String password, String matricule) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers(null),
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'matricule': matricule}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSessionFromBody(data['user'] as Map<String, dynamic>);
      return User.fromJson(data['user']);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Failed to sign up');
  }

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveSessionFromBody(data['user'] as Map<String, dynamic>);
      return User.fromJson(data['user']);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Failed to login');
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers(null),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to send reset link');
    }
  }

  Future<User> getMe() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers(token));
    if (response.statusCode == 200) return User.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load user profile');
  }

  // ── Admin: Users ──────────────────────────────────────────────────────────

  Future<List<User>> getUsers() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/admin/users'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<void> updateUserRole(String userId, String role) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/role'),
      headers: _headers(token),
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update role');
    }
  }

  // ── Admin: Halls ──────────────────────────────────────────────────────────

  Future<Hall> createHall({
    required String name,
    required int capacity,
    required String features,
    required String buildingBlock,
  }) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/admin/halls'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'capacity': capacity, 'features': features, 'building_block': buildingBlock}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Hall.fromJson((data['hall'] ?? data) as Map<String, dynamic>);
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Failed to create hall');
  }

  Future<void> deleteHall(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/halls?id=$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete hall');
    }
  }

  Future<void> updateHallCapacity(String id, int capacity) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/halls'),
      headers: _headers(token),
      body: jsonEncode({'id': id, 'capacity': capacity}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to update hall');
    }
  }

  // ── Admin: Courses ────────────────────────────────────────────────────────

  Future<Course> createCourse({
    required String code,
    required String name,
    required int enrolledCount,
    String? lecturerId,
  }) async {
    final token = await getToken();
    final body = <String, dynamic>{'code': code, 'name': name, 'enrolled_count': enrolledCount};
    if (lecturerId != null) body['lecturer_id'] = lecturerId;
    final response = await http.post(
      Uri.parse('$baseUrl/admin/courses'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Course.fromJson((data['course'] ?? data) as Map<String, dynamic>);
    }
    final b = jsonDecode(response.body);
    throw Exception(b['error'] ?? 'Failed to create course');
  }

  Future<void> deleteCourse(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/courses?id=$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete course');
    }
  }

  // Lecturer claims an unclaimed course for themselves
  Future<void> claimCourse(String courseId, String lecturerId) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/courses/$courseId'),
      headers: _headers(token),
      body: jsonEncode({'lecturer_id': lecturerId}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to claim course');
    }
  }

  // Lecturer unclaims their course
  Future<void> unclaimCourse(String courseId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/courses/$courseId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to unclaim course');
    }
  }

  // Get course details with enrolled students (for prefect assignment)
  Future<Map<String, dynamic>> getCourseDetail(String courseId) async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/courses/$courseId'), headers: _headers(token));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load course detail');
  }

  Future<void> assignCoursePersonnel(String courseId, {String? lecturerId, String? delegateId}) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (lecturerId != null) body['lecturer_id'] = lecturerId;
    if (delegateId != null) body['delegate_id'] = delegateId;
    final response = await http.put(
      Uri.parse('$baseUrl/courses/$courseId'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to assign course personnel');
    }
  }

  // ── Halls ──────────────────────────────────────────────────────────────────

  Future<List<Hall>> getHalls() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/halls'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Hall.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load halls');
  }

  Future<List<Map<String, dynamic>>> getHallsStatusNow() async {
    final response = await http.get(Uri.parse('$baseUrl/halls/status-now'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load hall status');
  }

  // ── Courses ────────────────────────────────────────────────────────────────

  Future<List<Course>> getCourses() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/courses'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Course.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load courses');
  }

  // ── Timetable ──────────────────────────────────────────────────────────────
  
  Future<List<Map<String, dynamic>>> getTimetable() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/timetable'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load timetable');
  }

  // ── Reservations ───────────────────────────────────────────────────────────

  Future<List<Reservation>> getReservations() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/reservations'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => Reservation.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load reservations');
  }

  Future<Reservation> createReservation(Map<String, dynamic> bookingData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: _headers(token),
      body: jsonEncode(bookingData),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Reservation.fromJson((body['reservation'] ?? body) as Map<String, dynamic>);
    }
    final error = jsonDecode(response.body);
    if (response.statusCode == 409 && error['error'] == 'CAPACITY_WARNING') {
      throw CapacityWarningException(
        error['message'] ?? 'Capacity warning',
        (error['alternatives'] as List<dynamic>).map((j) => Hall.fromJson(j as Map<String, dynamic>)).toList(),
      );
    }
    throw Exception(error['error'] ?? error['message'] ?? 'Failed to create reservation');
  }

  Future<void> deleteReservation(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/reservations/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete reservation');
    }
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/messages'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load messages');
  }

  Future<void> sendMessage(String content, {String? receiverId}) async {
    final token = await getToken();
    final body = <String, dynamic>{'content': content};
    if (receiverId != null) body['receiver_id'] = receiverId;
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final b = jsonDecode(response.body);
      throw Exception(b['error'] ?? 'Failed to send message');
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers(token));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load notifications');
  }

  // ── Account Management ────────────────────────────────────────────────────

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/user/account/password'),
      headers: _headers(token),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to change password');
    }
  }

  Future<String> changeEmail(String newEmail, String password) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/user/account/email'),
      headers: _headers(token),
      body: jsonEncode({'newEmail': newEmail, 'password': password}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to change email');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['email'] as String;
  }

  Future<void> deleteAccount(String password) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/user/account/delete'),
      headers: _headers(token),
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to delete account');
    }
    await removeToken();
  }

  // ── Departments ────────────────────────────────────────────────────────────

  Future<Map<String, String>> getDepartments() async {
    final response = await http.get(Uri.parse('$baseUrl/departments'), headers: _headers(null));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value.toString()));
    }
    throw Exception('Failed to load departments');
  }

  // ── User Settings ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserSettings() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/user/settings'), headers: _headers(token));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load settings');
  }

  Future<void> updateUserSettings({String? academicLevel, String? semester, String? major, List<String>? courseIds}) async {
    final token = await getToken();
    final body = <String, dynamic>{};
    if (academicLevel != null) body['academic_level'] = academicLevel;
    if (semester != null) body['semester'] = semester;
    if (major != null) body['major'] = major;
    if (courseIds != null) body['courseIds'] = courseIds;
    final response = await http.post(
      Uri.parse('$baseUrl/user/settings'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to update settings');
    }
  }
}
