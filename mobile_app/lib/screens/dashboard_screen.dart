import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'inventory_screen.dart'; // For navigation if needed
import 'finance_screen.dart';   // For navigation if needed
import 'forms/animal_form.dart';
import 'forms/milk_production_form.dart';
import 'forms/weight_record_form.dart';
import 'forms/breeding_record_form.dart';
import 'forms/feed_log_form.dart';
import 'forms/health_record_form.dart';
import 'forms/labor_activity_form.dart';
import 'forms/financial_transaction_form.dart';
import 'forms/farmer_form.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // Hardcoded farmer ID for demo purposes. In a real app, this would come from auth.
  final int farmerId = 1; 

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildActionButton(context, 'Add Animal', Icons.pets, () => AnimalForm(farmerId: farmerId)),
              _buildActionButton(context, 'Milk Record', Icons.water_drop, () => MilkProductionForm(farmerId: farmerId)),
              _buildActionButton(context, 'Weight Record', Icons.monitor_weight, () => WeightRecordForm(farmerId: farmerId)),
              _buildActionButton(context, 'Breeding', Icons.favorite, () => BreedingRecordForm(farmerId: farmerId)),
              _buildActionButton(context, 'Feed Log', Icons.grass, () => FeedLogForm(farmerId: farmerId)),
              _buildActionButton(context, 'Health', Icons.medical_services, () => HealthRecordForm(farmerId: farmerId)),
              _buildActionButton(context, 'Labor', Icons.work, () => LaborActivityForm(farmerId: farmerId)),
              _buildActionButton(context, 'Finance', Icons.attach_money, () => FinancialTransactionForm(farmerId: farmerId)),
              _buildActionButton(context, 'Register Farmer', Icons.person_add, () => const FarmerForm()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Widget Function() pageBuilder) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pageBuilder()),
        );
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Ranch Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerForm()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to Smart Ranch!\nUse the + button to add records.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSheet(context),
        child: const Icon(Icons.add),
        tooltip: 'Quick Actions',
      ),
    );
  }
}
