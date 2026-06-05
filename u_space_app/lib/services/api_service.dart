import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../models/reservation.dart';

class ApiService {
  // Using 10.0.2.2 for Android emulator, change to localhost for iOS/web
  static const String baseUrl = 'http://10.0.2.2:3000/api';

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
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Methods
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Assuming backend returns a token or sets a cookie
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      return User.fromJson(data['user']);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to login');
    }
  }

  Future<User> signup(String name, String email, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: _headers(null),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      return User.fromJson(data['user']);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to sign up');
    }
  }

  // Halls Methods
  Future<List<Hall>> getHalls() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/halls'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Hall.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load halls');
    }
  }

  // Courses Methods
  Future<List<Course>> getCourses() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/courses'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // Reservation Methods
  Future<Reservation> createReservation(Map<String, dynamic> bookingData) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/reservations'),
      headers: _headers(token),
      body: jsonEncode(bookingData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Reservation.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create reservation');
    }
  }
}
