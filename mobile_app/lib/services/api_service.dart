import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  // Use localhost for Web.
  // If using a real device, use the IP address of your machine via --dart-define=BASE_URL=...
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  static Future<List<dynamic>> getPens(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/pens/?farmer_id=$farmerId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pens');
    }
  }

  static Future<void> createPen(Map<String, dynamic> data) async {
    await _post('pens', data);
  }

  static Future<List<Animal>> getAnimals([int? farmerId]) async {
    String url = '$baseUrl/animals/';
    if (farmerId != null) {
      url += '?farmer_id=$farmerId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Animal>.from(l.map((model) => Animal.fromJson(model)));
    } else {
      throw Exception('Failed to load animals');
    }
  }

  static Future<void> createAnimal(Map<String, dynamic> data) async {
    await _post('animals', data);
  }

  static Future<void> createMilkProduction(Map<String, dynamic> data) async {
    await _post('production/milk', data);
  }

  static Future<void> createWeightRecord(Map<String, dynamic> data) async {
    await _post('production/weight', data);
  }

  static Future<void> createBreedingRecord(Map<String, dynamic> data) async {
    await _post('production/breeding', data);
  }

  static Future<void> createFeedLog(Map<String, dynamic> data) async {
    await _post('feed/pen', data);
  }

  static Future<void> createHealthRecord(Map<String, dynamic> data) async {
    await _post('health', data);
  }

  static Future<void> createLaborActivity(Map<String, dynamic> data) async {
    await _post('labor', data);
  }

  static Future<void> createFinancialTransaction(Map<String, dynamic> data) async {
    await _post('finance', data);
  }

  static Future<void> createFarmer(Map<String, dynamic> data) async {
    await _post('farmers', data);
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create record in $endpoint: ${response.body}');
    }
  }

  static Future<Expense> createExpense(Expense expense) async {
    final data = {
      'farmer_id': 1, // Default
      'type': 'Expense',
      'category': expense.category,
      'description': expense.description ?? '',
      'amount': expense.amount,
      'date': expense.expenseDate,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/finance/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      // The response is a FinancialTransaction, we need to map it back to Expense if we want to return Expense
      final json = jsonDecode(response.body);
      return Expense(
        id: json['transaction_id'],
        category: json['category'],
        amount: (json['amount'] as num).toDouble(),
        expenseDate: json['date'],
        description: json['description'],
      );
    } else {
      throw Exception('Failed to create expense');
    }
  }

  static Future<List<HealthEvent>> getRecentHealthEvents() async {
    // TODO: Implement backend endpoint for all/recent health events
    return [];
  }

  static Future<List<Expense>> getExpenses([int? farmerId]) async {
    farmerId ??= 1;
    final response = await http.get(Uri.parse('$baseUrl/finance/farmer/$farmerId'));
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Expense>.from(l.map((json) => Expense.fromJson(json)));
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  static Future<List<HealthEvent>> getHealthEvents(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/animal/$animalId'));
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<HealthEvent>.from(l.map((model) => HealthEvent.fromJson(model)));
    } else {
      throw Exception('Failed to load health events');
    }
  }

  static Future<void> createHealthEvent(HealthEvent event) async {
    final data = event.toJson();
    // Ensure date is sent as string if needed, or rely on toJson
    await _post('health', data);
  }
}
