import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost, or localhost for Windows
  // For physical device, use your machine's IP address.
  static const String baseUrl = 'http://127.0.0.1:8000'; 

  // --- PENS ---
  Future<List<Pen>> getPens() async {
    final response = await http.get(Uri.parse('$baseUrl/pens/'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Pen.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load pens');
    }
  }

  Future<Pen> createPen(Pen pen) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pens/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(pen.toJson()),
    );
    if (response.statusCode == 200) {
      return Pen.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create pen');
    }
  }

  // --- ANIMALS ---
  Future<List<Animal>> getAnimals() async {
    final response = await http.get(Uri.parse('$baseUrl/animals/'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Animal.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load animals');
    }
  }

  Future<Animal> createAnimal(Animal animal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animals/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(animal.toJson()),
    );
    if (response.statusCode == 200) {
      return Animal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create animal');
    }
  }

  // --- HEALTH ---
  Future<List<HealthEvent>> getHealthEvents(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/animal/$animalId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => HealthEvent.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load health events');
    }
  }

  Future<HealthEvent> createHealthEvent(HealthEvent event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/health/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(event.toJson()),
    );
    if (response.statusCode == 200) {
      return HealthEvent.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create health event');
    }
  }

  // --- FEED ---
  Future<List<FeedLog>> getFeedLogs(int penId) async {
    final response = await http.get(Uri.parse('$baseUrl/feed/pen/$penId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => FeedLog.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load feed logs');
    }
  }

  Future<FeedLog> createFeedLog(FeedLog log) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feed/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(log.toJson()),
    );
    if (response.statusCode == 200) {
      return FeedLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create feed log');
    }
  }

  // --- EXPENSES ---
  Future<List<Expense>> getExpenses() async {
    final response = await http.get(Uri.parse('$baseUrl/expenses/'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Expense.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(expense.toJson()),
    );
    if (response.statusCode == 200) {
      return Expense.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create expense');
    }
  }
}
