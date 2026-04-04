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
    final response = await http.get(Uri.parse('$baseUrl/animals/pens/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Pen>.from(l.map((model) => Pen.fromJson(model)));
    } else {
      throw Exception('Failed to load pens');
    }
  }

  static Future<void> createPen(Map<String, dynamic> data) async {
    await _post('animals/pens', data);
  }

  static Future<List<Animal>> getAnimals([int? farmerId]) async {
    final response = await http.get(Uri.parse('$baseUrl/animals/'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Animal>.from(l.map((model) => Animal.fromJson(model)));
    } else {
      throw Exception('Failed to load animals');
    }
  }

  // --- REPORTING ENDPOINTS ---

  static Future<Map<String, dynamic>> getFCR(int penId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/fcr/$penId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load FCR');
  }

  static Future<Map<String, dynamic>> getMortalityRate(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/mortality?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load mortality rate');
  }

  static Future<Map<String, dynamic>> getFinancialSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/reports/financial-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load financial summary');
  }

  static Future<void> createAnimal(Map<String, dynamic> data) async {
    await _post('animals', data);
  }

  static Future<void> updateAnimal(int id, Map<String, dynamic> data) async {
    await _put('animals/$id', data);
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

  static Future<void> updateBreedingRecord(int id, Map<String, dynamic> data) async {
    await _put('production/breeding/$id', data);
  }

  static Future<List<BreedingRecord>> getBreedingRecords(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/animal/$animalId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<BreedingRecord>.from(l.map((model) => BreedingRecord.fromJson(model)));
    } else {
      throw Exception('Failed to load breeding records');
    }
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


  static Future<void> createFarmer(Map<String, dynamic> data) async {
    await _post('farmers', data);
  }

  static Future<void> _post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create record in $endpoint (Status: ${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> _put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update record in $endpoint (Status: ${response.statusCode}): ${response.body}');
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
      throw Exception('Failed to create transaction (Status: ${response.statusCode}): ${response.body}');
    }
  }

  static Future<List<HealthEvent>> getRecentHealthEvents() async {
    // TODO: Implement backend endpoint for all/recent health events
    return [];
  }

  static Future<List<FinancialTransaction>> getFinancialTransactions([int? farmerId]) async {
    final response = await http.get(Uri.parse('$baseUrl/finance/farmer/${farmerId ?? _farmerId ?? 1}'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<FinancialTransaction>.from(l.map((json) => FinancialTransaction.fromJson(json)));
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  static Future<List<HealthEvent>> getHealthEvents(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/animal/$animalId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<HealthEvent>.from(l.map((model) => HealthEvent.fromJson(model)));
    } else {
      throw Exception('Failed to load health events');
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
    throw Exception('Failed to load farm health records');
  }

  static Future<List<FeedLog>> getPenFeedLogs(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/feed/farmer/$farmerId/pen'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<FeedLog>.from(l.map((model) => FeedLog.fromJson(model)));
    }
    throw Exception('Failed to load pen feed logs');
  }

  static Future<List<IndividualFeedLog>> getIndividualFeedLogs(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/feed/farmer/$farmerId/individual'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<IndividualFeedLog>.from(l.map((model) => IndividualFeedLog.fromJson(model)));
    }
    throw Exception('Failed to load individual feed logs');
  }

  static Future<List<MilkProduction>> getAllMilkProduction(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/milk/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<MilkProduction>.from(l.map((model) => MilkProduction.fromJson(model)));
    }
    throw Exception('Failed to load milk production');
  }

  static Future<List<WeightRecord>> getAllWeightRecords(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/weight/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<WeightRecord>.from(l.map((model) => WeightRecord.fromJson(model)));
    }
    throw Exception('Failed to load weight records');
  }

  static Future<List<BreedingRecord>> getAllBreedingRecords(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<BreedingRecord>.from(l.map((model) => BreedingRecord.fromJson(model)));
    }
    throw Exception('Failed to load breeding records');
  }

  static Future<List<LaborActivity>> getAllLaborActivities(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/labor/farmer/$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<LaborActivity>.from(l.map((model) => LaborActivity.fromJson(model)));
    }
    throw Exception('Failed to load labor activities');
  }

  // --- DECISION SUPPORT ENDPOINTS ---

  static Future<Map<String, dynamic>> getBreedingSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load breeding summary');
  }

  static Future<List<dynamic>> getPregnantAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/pregnant?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load pregnant animals');
  }

  static Future<List<dynamic>> getDueSoonAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/due-soon?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load due-soon animals');
  }

  static Future<List<dynamic>> getFailedBreedingAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/production/breeding/failed?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load failed breeding list');
  }

  static Future<Map<String, dynamic>> getHealthSummary(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/status-summary?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load health summary');
  }

  static Future<List<dynamic>> getSickAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/sick?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load sick animals');
  }

  static Future<List<dynamic>> getUnderTreatmentAnimals(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/health/under-treatment?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load animals under treatment');
  }

  static Future<List<Alert>> getAlerts(int farmerId) async {
    final response = await http.get(Uri.parse('$baseUrl/alerts/?farmer_id=$farmerId'), headers: _headers);
    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<Alert>.from(l.map((json) => Alert.fromJson(json)));
    }
    throw Exception('Failed to load alerts');
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
      Uri.parse('$baseUrl/breeding/$breedingId/pregnant'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark breeding as pregnant: ${response.body}');
    }
  }

  static Future<void> markBreedingCalved(int breedingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/breeding/$breedingId/calved'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark breeding as calved: ${response.body}');
    }
  }
}
