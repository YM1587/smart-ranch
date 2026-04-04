import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static String? _token;
  static int? _farmerId;

  static void setAuth(String token, int farmerId) {
    _token = token;
    _farmerId = farmerId;
  }

  static void logout() {
    _token = null;
    _farmerId = null;
  }

  static int get farmerId => _farmerId ?? 1; // Fallback to 1 only if absolutely necessary, but preferred from session

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (_token != null) "Authorization": "Bearer $_token",
  };

  // Use 10.0.2.2 for Android emulator to access localhost of the host machine.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/farmers/token'),
      body: {
        'username': username,
        'password': password,
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setAuth(data['access_token'], data['farmer_id']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<List<Pen>> getPens(int farmerId) async {
    // Backend now verifies token matches farmerId
    final response = await http.get(Uri.parse('$baseUrl/pens/?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Pen>.from(l.map((model) => Pen.fromJson(model)));
    } else {
      // Return empty list if unauthorized or failed instead of crashing dashboard
      print("Failed to load pens: ${response.statusCode}");
      return [];
    }
  }

  static Future<void> createPen(Map<String, dynamic> data) async {
    await _post('pens', data);
  }

  static Future<List<Animal>> getAnimals([int? farmerId]) async {
    // Backend now scopes to current_user token automatically
    final response = await http.get(Uri.parse('$baseUrl/animals/'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Animal>.from(l.map((model) => Animal.fromJson(model)));
    } else {
      print("Failed to load animals: ${response.statusCode}");
      return [];
    }
  }

  // --- REPORTING ENDPOINTS ---

  static Future<Map<String, dynamic>> getFCR(int penId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/fcr/$penId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"fcr": 0, "message": "N/A"};
  }

  static Future<Map<String, dynamic>> getMortalityRate(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/mortality?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"mortality_rate": 0};
  }

  static Future<Map<String, dynamic>> getFinancialSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/financial-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"categories": {}, "total_expenses": 0};
  }

  static Future<void> createAnimal(Animal animal) async {
    await _post('animals', animal.toJson());
  }

  static Future<void> updateAnimal(int id, Map<String, dynamic> data) async {
    await _put('animals/$id', data);
  }

  static Future<void> createMilkProduction(MilkProduction production) async {
    await _post('production/milk', production.toJson());
  }

  static Future<void> createWeightRecord(WeightRecord record) async {
    await _post('production/weight', record.toJson());
  }

  static Future<List<dynamic>> getPendingBreeding(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/pending?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> markBreedingFailed(int breedingId) async {
    final response = await http.post(Uri.parse('$baseUrl/production/breeding/$breedingId/failed'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to mark breeding as failed');
  }

  static Future<void> createBreedingRecord(BreedingRecord record) async {
    await _post('production/breeding', record.toJson());
  }

  static Future<void> updateBreedingRecord(int id, Map<String, dynamic> data) async {
    await _put('production/breeding/$id', data);
  }

  static Future<List<BreedingRecord>> getBreedingRecords(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/animal/$animalId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<BreedingRecord>.from(l.map((model) => BreedingRecord.fromJson(model)));
    } else {
      return [];
    }
  }

  static Future<void> createFeedLog(FeedLog log) async {
    await _post('feed/pen', log.toJson());
  }

  static Future<void> createHealthRecord(HealthEvent event) async {
    await _post('health', event.toJson());
  }

  static Future<void> createLaborActivity(LaborActivity activity) async {
    await _post('labor', activity.toJson());
  }


  static Future<void> createFarmer(Map<String, dynamic> data) async {
    // No trailing slash as per standard convention
    final response = await http.post(
      Uri.parse('$baseUrl/farmers/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> data) async {
    // Unified endpoint logic: handle trailing slash correctly
    final uri = endpoint.endsWith('/') ? '$baseUrl/$endpoint' : '$baseUrl/$endpoint/';
    final response = await http.post(
      Uri.parse(uri),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error in $endpoint (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> _put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Error in $endpoint (${response.statusCode}): ${response.body}');
    }
  }

  static Future<FinancialTransaction> createFinancialTransaction(FinancialTransaction transaction) async {
    final data = transaction.toJson();
    final response = await http.post(
      Uri.parse('$baseUrl/finance/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return FinancialTransaction.fromJson(json);
    } else {
      throw Exception('Failed to create transaction: ${response.body}');
    }
  }

  static Future<List<HealthEvent>> getRecentHealthEvents() async {
    // This is now covered by getAllHealthEvents
    return [];
  }

  static Future<List<FinancialTransaction>> getFinancialTransactions([int? farmerId]) async {
    final id = farmerId ?? _farmerId;
    if (id == null) return [];
    final response = await http.get(Uri.parse('$baseUrl/finance/farmer/$id'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<FinancialTransaction>.from(l.map((json) => FinancialTransaction.fromJson(json)));
    } else {
      return [];
    }
  }

  static Future<List<HealthEvent>> getHealthEvents(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/animal/$animalId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<HealthEvent>.from(l.map((model) => HealthEvent.fromJson(model)));
    } else {
      return [];
    }
  }

  static Future<void> createHealthEvent(HealthEvent event) async {
    final data = event.toJson();
    await _post('health', data);
  }

  // --- FARM-WIDE ANALYTICS FETCHERS ---

  static Future<List<HealthEvent>> getAllHealthEvents(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<HealthEvent>.from(l.map((model) => HealthEvent.fromJson(model)));
    }
    return [];
  }

  static Future<List<FeedLog>> getPenFeedLogs(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/feed/farmer/$farmerId/pen'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<FeedLog>.from(l.map((model) => FeedLog.fromJson(model)));
    }
    return [];
  }

  static Future<List<IndividualFeedLog>> getIndividualFeedLogs(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/feed/farmer/$farmerId/individual'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<IndividualFeedLog>.from(l.map((model) => IndividualFeedLog.fromJson(model)));
    }
    return [];
  }

  static Future<List<MilkProduction>> getAllMilkProduction(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/milk/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<MilkProduction>.from(l.map((model) => MilkProduction.fromJson(model)));
    }
    return [];
  }

  static Future<List<WeightRecord>> getAllWeightRecords(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/weight/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<WeightRecord>.from(l.map((model) => WeightRecord.fromJson(model)));
    }
    return [];
  }

  static Future<List<BreedingRecord>> getAllBreedingRecords(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<BreedingRecord>.from(l.map((model) => BreedingRecord.fromJson(model)));
    }
    return [];
  }

  static Future<List<LaborActivity>> getAllLaborActivities(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/labor/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<LaborActivity>.from(l.map((model) => LaborActivity.fromJson(model)));
    }
    return [];
  }

  // --- DECISION SUPPORT ENDPOINTS ---

  static Future<Map<String, dynamic>> getBreedingSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"pregnant": 0, "due_soon": 0, "failed": 0};
  }

  static Future<List<dynamic>> getPregnantAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/pregnant?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> getHealthSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/status-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {"sick": 0, "under_treatment": 0};
  }

  static Future<List<dynamic>> getSickAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/sick?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getUnderTreatmentAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/under-treatment?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<Alert>> getAlerts(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/alerts/?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Alert>.from(l.map((json) => Alert.fromJson(json)));
    }
    return [];
  }

  static Future<void> dismissAlert(int alertId) async {
    final response = await http.post(Uri.parse('$baseUrl/alerts/$alertId/dismiss'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to dismiss alert');
  }

  static Future<void> disposeAnimal(int animalId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/animals/$animalId/dispose'),
      headers: _headers,
      body: jsonEncode(data)
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to dispose animal: ${response.body}');
    }
  }

  static Future<List<dynamic>> getDueSoonAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/due-soon?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> resolveHealthRecord(int recordId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/health/$recordId/resolve'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to resolve health record: ${response.body}');
    }
  }

  static Future<void> markBreedingPregnant(int breedingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production/breeding/$breedingId/pregnant'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark breeding as pregnant: ${response.body}');
    }
  }

  static Future<void> markBreedingCalved(int breedingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/production/breeding/$breedingId/calved'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark breeding as calved: ${response.body}');
    }
  }
}
