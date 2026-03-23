import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'finance_screen.dart';
import 'operations_dashboard_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int farmerId = 1;
  bool _isLoading = true;
  bool _showWarnings = false;

  // Data
  List<Animal> _animals = [];
  List<HealthEvent> _healthEvents = [];
  List<FeedLog> _penFeedLogs = [];
  List<IndividualFeedLog> _indFeedLogs = [];
  List<MilkProduction> _milkRecords = [];
  List<WeightRecord> _weightRecords = [];
  List<BreedingRecord> _breedingRecords = [];
  List<LaborActivity> _laborActivities = [];
  List<FinancialTransaction> _transactions = [];

  // Alerts
  List<Alert> _alerts = [];
  bool _showAllAlerts = false;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getAnimals(farmerId),
        ApiService.getAllHealthEvents(farmerId),
        ApiService.getPenFeedLogs(farmerId),
        ApiService.getIndividualFeedLogs(farmerId),
        ApiService.getAllMilkProduction(farmerId),
        ApiService.getAllWeightRecords(farmerId),
        ApiService.getAllBreedingRecords(farmerId),
        ApiService.getAllLaborActivities(farmerId),
        ApiService.getFinancialTransactions(farmerId),
      ]);

      setState(() {
        _animals = results[0] as List<Animal>;
        _healthEvents = results[1] as List<HealthEvent>;
        _penFeedLogs = results[2] as List<FeedLog>;
        _indFeedLogs = results[3] as List<IndividualFeedLog>;
        _milkRecords = results[4] as List<MilkProduction>;
        _weightRecords = results[5] as List<WeightRecord>;
        _breedingRecords = results[6] as List<BreedingRecord>;
        _laborActivities = results[7] as List<LaborActivity>;
        _transactions = results[8] as List<FinancialTransaction>;
      });

      _fetchAlerts();
    } catch (e) {
      print("Error fetching dashboard data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAlerts() async {
    try {
      final alerts = await ApiService.getAlerts(farmerId);
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching alerts: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissAlert(int alertId) async {
    try {
      await ApiService.dismissAlert(alertId);
      setState(() {
        _alerts.removeWhere((a) => a.id == alertId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Logic removed as it's now handled by the backend /alerts endpoint

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildHerdSnapshot()),
            SliverToBoxAdapter(child: _buildFinancialSnapshot()),
            SliverToBoxAdapter(child: _buildProductionSnapshot()),
            SliverToBoxAdapter(child: _buildAlertsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Welcome Back, Farmer!', style: TextStyle(fontSize: 18)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchAllData,
        ),
      ],
    );
  }

  Widget _buildHerdSnapshot() {
    final totalAnimals = _animals.length;
    final activeAnimals = _animals.where((a) => a.status == 'Active').length;
    final sickAnimals = _healthEvents.where((e) {
      final date = DateTime.tryParse(e.eventDate);
      return date != null && date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;
    final pregnantAnimals = _breedingRecords.where((r) => r.pregnancyStatus == 'Pregnant').length;
    final lactatingAnimals = _animals.where((a) => a.sex == 'Female' && a.status == 'Active').length;
    final now = DateTime.now();
    final calves = _animals.where((a) {
      if (a.birthDate == null) return false;
      final birthDate = DateTime.tryParse(a.birthDate!);
      if (birthDate == null) return false;
      final age = now.difference(birthDate).inDays;
      return age < 180; // < 6 months
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.pets, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Herd Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildKPICard('Total', '$totalAnimals', Icons.pets, Colors.blue),
              const SizedBox(width: 12),
              _buildKPICard('Active', '$activeAnimals', Icons.check_circle, Colors.green),
              const SizedBox(width: 12),
              _buildKPICard('Sick', '$sickAnimals', Icons.medical_services, Colors.red),
              const SizedBox(width: 12),
              _buildKPICard('Pregnant', '$pregnantAnimals', Icons.pregnant_woman, Colors.purple),
              const SizedBox(width: 12),
              _buildKPICard('Lactating', '$lactatingAnimals', Icons.water_drop, Colors.blue),
              const SizedBox(width: 12),
              _buildKPICard('Calves', '$calves', Icons.child_care, Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFinancialSnapshot() {
    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    final monthlyIncome = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Income' && date != null && date.month == thisMonth && date.year == thisYear;
    }).fold(0.0, (sum, t) => sum + t.amount);

    final monthlyExpenses = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Expense' && date != null && date.month == thisMonth && date.year == thisYear;
    }).fold(0.0, (sum, t) => sum + t.amount);

    final lastMonthIncome = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Income' && date != null && date.month == lastMonth && date.year == lastMonthYear;
    }).fold(0.0, (sum, t) => sum + t.amount);

    final lastMonthExpenses = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Expense' && date != null && date.month == lastMonth && date.year == lastMonthYear;
    }).fold(0.0, (sum, t) => sum + t.amount);

    final netProfit = monthlyIncome - monthlyExpenses;
    final lastNetProfit = lastMonthIncome - lastMonthExpenses;
    final costPerAnimal = _animals.isNotEmpty ? monthlyExpenses / _animals.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Financial Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildKPICardWithTrend('Income', NumberFormat.compact().format(monthlyIncome), Icons.arrow_upward, Colors.green, 
                lastMonthIncome > 0 ? ((monthlyIncome - lastMonthIncome) / lastMonthIncome * 100).toStringAsFixed(0) + '%' : null,
                monthlyIncome >= lastMonthIncome),
              const SizedBox(width: 12),
              _buildKPICardWithTrend('Expenses', NumberFormat.compact().format(monthlyExpenses), Icons.arrow_downward, Colors.red,
                lastMonthExpenses > 0 ? ((monthlyExpenses - lastMonthExpenses) / lastMonthExpenses * 100).toStringAsFixed(0) + '%' : null,
                monthlyExpenses <= lastMonthExpenses),
              const SizedBox(width: 12),
              _buildKPICardWithTrend('Net Profit', NumberFormat.compact().format(netProfit), Icons.account_balance, 
                netProfit >= 0 ? Colors.green : Colors.red,
                lastNetProfit != 0 ? ((netProfit - lastNetProfit) / lastNetProfit.abs() * 100).toStringAsFixed(0) + '%' : null,
                netProfit >= lastNetProfit),
              const SizedBox(width: 12),
              _buildKPICard('Cost/Animal', NumberFormat.compact().format(costPerAnimal), Icons.pets, Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductionSnapshot() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayMilk = _milkRecords.where((r) {
      final date = DateTime.tryParse(r.date);
      if (date == null) return false;
      final recordDay = DateTime(date.year, date.month, date.day);
      return recordDay.isAtSameMomentAs(today);
    }).fold(0.0, (sum, r) => sum + r.totalYield);

    final lactatingCows = _animals.where((a) => a.sex == 'Female' && a.status == 'Active').length;
    final avgPerCow = lactatingCows > 0 ? todayMilk / lactatingCows : 0;

    // Top/Bottom performers
    Map<int, double> animalTotals = {};
    for (var record in _milkRecords) {
      animalTotals[record.animalId] = (animalTotals[record.animalId] ?? 0) + record.totalYield;
    }
    final sorted = animalTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();
    final bottom3 = sorted.length > 3 ? sorted.skip(sorted.length - 3).toList().reversed.toList() : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.water_drop, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Production Snapshot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildKPICard('Today', '${todayMilk.toStringAsFixed(1)}L', Icons.today, Colors.blue),
              const SizedBox(width: 12),
              _buildKPICard('Avg/Cow', '${avgPerCow.toStringAsFixed(1)}L', Icons.pets, Colors.green),
              const SizedBox(width: 12),
              _buildKPICard('Cows', '$lactatingCows', Icons.female, Colors.purple),
            ],
          ),
        ),
        if (top3.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top Performers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...top3.map((e) {
                    final animal = _animals.firstWhere((a) => a.id == e.key, orElse: () => _animals.first);
                    return _buildPerformerRow(animal.name ?? animal.tagNumber, '${e.value.toStringAsFixed(0)}L', true);
                  }),
                  if (bottom3.isNotEmpty) ...[
                    const Divider(height: 16),
                    const Text('Needs Attention', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...bottom3.map((e) {
                      final animal = _animals.firstWhere((a) => a.id == e.key, orElse: () => _animals.first);
                      return _buildPerformerRow(animal.name ?? animal.tagNumber, '${e.value.toStringAsFixed(0)}L', false);
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlertsSection() {
    if (_alerts.isEmpty) return const SizedBox.shrink();

    final criticalAlerts = _alerts.where((a) => a.type == 'CRITICAL').toList();
    final warningAlerts = _alerts.where((a) => a.type != 'CRITICAL').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.bolt, size: 20, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Smart Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildAlertBadge('Crit', criticalAlerts.length, Colors.red),
              const SizedBox(width: 8),
              _buildAlertBadge('Warn', warningAlerts.length, Colors.orange),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _alerts.length > 3 && !_showAllAlerts ? 3 : _alerts.length,
          itemBuilder: (context, index) {
            final alert = _alerts[index];
            return _buildAlertCard(alert);
          },
        ),
        if (_alerts.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllAlerts = !_showAllAlerts),
            child: Center(
              child: Text(_showAllAlerts ? 'Show Less' : 'View All ${_alerts.length} Alerts'),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertBadge(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label $count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final color = alert.type == 'CRITICAL' ? Colors.red : Colors.orange;
    final icon = alert.type == 'CRITICAL' ? Icons.error_outline : Icons.warning_amber_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(alert.message, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => _dismissAlert(alert.id),
        ),
        onTap: alert.relatedAnimalId != null ? () {
          // TODO: Navigate to Animal Profile
        } : null,
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildKPICardWithTrend(String label, String value, IconData icon, Color color, String? trend, bool? isPositive) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))),
              if (trend != null)
                Row(
                  children: [
                    Icon(isPositive == true ? Icons.arrow_upward : Icons.arrow_downward, 
                      size: 10, color: isPositive == true ? Colors.green : Colors.red),
                    Text(trend, style: TextStyle(fontSize: 9, color: isPositive == true ? Colors.green : Colors.red)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerRow(String name, String value, bool isTop) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }


}
