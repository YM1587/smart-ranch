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
import 'operations_dashboard_screen.dart';

import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int farmerId = 1;
  List<FinancialTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final transactions = await ApiService.getFinancialTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildActionTile(context, 'Add Animal', Icons.pets, () => AnimalForm(farmerId: farmerId)),
              _buildActionTile(context, 'Inventory', Icons.inventory, () => const InventoryScreen()),
              _buildActionTile(context, 'Milk Record', Icons.water_drop, () => MilkProductionForm(farmerId: farmerId)),
              _buildActionTile(context, 'Weight Record', Icons.monitor_weight, () => WeightRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Breeding', Icons.favorite, () => BreedingRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Feed Log', Icons.grass, () => FeedLogForm(farmerId: farmerId)),
              _buildActionTile(context, 'Operations', Icons.analytics, () => const OperationsDashboardScreen()),
              _buildActionTile(context, 'Labor', Icons.work, () => LaborActivityForm(farmerId: farmerId)),
              _buildActionTile(context, 'Finance', Icons.monetization_on, () => const FinanceScreen()),
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => pageBuilder())).then((_) => _loadData());
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate current month's financials
    final now = DateTime.now();
    final thisMonthTrans = _transactions.where((t) {
      final date = DateTime.tryParse(t.date) ?? DateTime(1970);
      return date.year == now.year && date.month == now.month;
    }).toList();

    double income = 0;
    double expenses = 0;
    for (var t in thisMonthTrans) {
      if (t.type == 'Income') income += t.amount; else expenses += t.amount;
    }
    double netProfit = income - expenses;

    // Last month for trend
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthTrans = _transactions.where((t) {
      final date = DateTime.tryParse(t.date) ?? DateTime(1970);
      return date.year == lastMonth.year && date.month == lastMonth.month;
    }).toList();

    double prevIncome = 0;
    double prevExpenses = 0;
    for (var t in lastMonthTrans) {
      if (t.type == 'Income') prevIncome += t.amount; else prevExpenses += t.amount;
    }
    double prevProfit = prevIncome - prevExpenses;
    bool isTrendingUp = netProfit >= prevProfit;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Ranch', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FarmerForm())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLovelyFinancialSection(income, expenses, netProfit, isTrendingUp),
            const SizedBox(height: 24),
            const Text('Welcome Back!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Here is what\'s happening on your ranch today.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 200), // Placeholder for other dashboard content
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionSheet(context),
        label: const Text('New Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLovelyFinancialSection(double income, double expenses, double profit, bool isUp) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: 'KES ');
    final isPositive = profit >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FINANCIAL SNAPSHOT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive ? [Colors.green[600]!, Colors.green[400]!] : [Colors.red[600]!, Colors.red[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: (isPositive ? Colors.green : Colors.red).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Profit (This Month)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Icon(isUp ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'KES ${NumberFormat("#,##0").format(profit)}',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMiniMetric('Income', income, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniMetric('Expenses', expenses, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniMetric(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              'KES ${NumberFormat("#,###").format(amount)}',
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
