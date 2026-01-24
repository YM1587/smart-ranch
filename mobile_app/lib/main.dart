import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/operations_dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/forms/animal_form.dart';
import 'screens/forms/milk_production_form.dart';
import 'screens/forms/weight_record_form.dart';
import 'screens/forms/breeding_record_form.dart';
import 'screens/forms/feed_log_form.dart';
import 'screens/forms/health_record_form.dart';
import 'screens/forms/labor_activity_form.dart';
import 'screens/forms/financial_transaction_form.dart';
import 'screens/forms/farmer_form.dart';

void main() {
  runApp(const SmartRanchApp());
}

class SmartRanchApp extends StatelessWidget {
  const SmartRanchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ranch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const InventoryScreen(),
    const OperationsDashboardScreen(),
    const FinanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        height: 70, // Increased height to fit labels
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.dashboard, 'Home'),
            _buildNavItem(1, Icons.pets, 'Animals'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.analytics, 'Operations'),
            _buildNavItem(3, Icons.attach_money, 'Finance'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSheet(context),
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 24),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    const int farmerId = 1; // Default farmerId
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildActionTile(context, 'Add Animal', Icons.pets, () => const AnimalForm(farmerId: farmerId)),
              _buildActionTile(context, 'Milk Record', Icons.water_drop, () => const MilkProductionForm(farmerId: farmerId)),
              _buildActionTile(context, 'Weight Record', Icons.monitor_weight, () => const WeightRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Breeding', Icons.favorite, () => const BreedingRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Feed Log', Icons.grass, () => const FeedLogForm(farmerId: farmerId)),
              _buildActionTile(context, 'Health', Icons.medical_services, () => const HealthRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Labor', Icons.work, () => const LaborActivityForm(farmerId: farmerId)),
              _buildActionTile(context, 'Finance', Icons.monetization_on, () => const FinancialTransactionForm(farmerId: farmerId)),
              _buildActionTile(context, 'Settings', Icons.settings, () => const FarmerForm()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile(BuildContext context, String label, IconData icon, Widget Function() pageBuilder) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => pageBuilder()));
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.green),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
