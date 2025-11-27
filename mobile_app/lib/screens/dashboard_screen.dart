import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'inventory_screen.dart'; // For navigation if needed
import 'finance_screen.dart';   // For navigation if needed

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
  List<HealthEvent> recentHealthEvents = [];
  List<Expense> recentExpenses = [];
  bool isLoading = true;

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
      final health = await apiService.getRecentHealthEvents();

      setState(() {
        totalAnimals = animals.length;
        totalPens = pens.length;
        totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.amount);
        recentHealthEvents = health.take(3).toList();
        recentExpenses = expenses.reversed.take(3).toList(); // Show latest first
        isLoading = false;
      });
    } catch (e) {
      print("Error loading dashboard data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Ranch Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard("Animals", totalAnimals.toString(), Icons.pets, Colors.blue)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildSummaryCard("Pens", totalPens.toString(), Icons.fence, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard("Total Expenses", "KES ${totalExpenses.toStringAsFixed(0)}", Icons.monetization_on, Colors.red),
                    
                    const SizedBox(height: 24),
                    const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildActionButton("Add Animal", Icons.add, Colors.blue, () {
                           // Navigation logic or dialog would go here
                           // For now, we can just show a snackbar or navigate to Inventory
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Go to Inventory to add animals")));
                        })),
                        const SizedBox(width: 10),
                        Expanded(child: _buildActionButton("Add Expense", Icons.attach_money, Colors.red, () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Go to Finance to add expenses")));
                        })),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text("Recent Health Alerts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (recentHealthEvents.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No recent health events recorded.")))
                    else
                      ...recentHealthEvents.map((e) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.medical_services, color: Colors.red),
                              title: Text(e.diagnosis),
                              subtitle: Text("${e.date} - Treatment: ${e.treatment}"),
                            ),
                          )),

                    const SizedBox(height: 24),
                    const Text("Recent Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                     if (recentExpenses.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No recent expenses recorded.")))
                    else
                      ...recentExpenses.map((e) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.attach_money, color: Colors.green),
                              title: Text(e.category),
                              subtitle: Text(e.expenseDate),
                              trailing: Text("KES ${e.amount}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
