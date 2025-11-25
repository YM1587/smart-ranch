import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  int totalAnimals = 0;
  int totalPens = 0;
  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final animals = await apiService.getAnimals();
      final pens = await apiService.getPens();
      final expenses = await apiService.getExpenses();

      setState(() {
        totalAnimals = animals.length;
        totalPens = pens.length;
        totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
      });
    } catch (e) {
      print("Error loading dashboard data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Ranch Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard("Total Animals", totalAnimals.toString(), Icons.pets, Colors.blue),
            const SizedBox(height: 16),
            _buildSummaryCard("Total Pens", totalPens.toString(), Icons.fence, Colors.green),
            const SizedBox(height: 16),
            _buildSummaryCard("Total Expenses", "KES ${totalExpenses.toStringAsFixed(2)}", Icons.monetization_on, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
