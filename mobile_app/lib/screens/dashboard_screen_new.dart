import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'finance_screen.dart';
import 'operations_dashboard_screen.dart';
import 'forms/animal_form.dart';
import 'forms/milk_production_form.dart';
import 'forms/weight_record_form.dart';
import 'forms/breeding_record_form.dart';
import 'forms/feed_log_form.dart';
import 'forms/health_record_form.dart';
import 'forms/labor_activity_form.dart';
import 'forms/financial_transaction_form.dart';
import 'forms/farmer_form.dart';

// Alert Model
class DashboardAlert {
  final String severity; // 'critical', 'warning', 'info'
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  DashboardAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

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
  List<DashboardAlert> _criticalAlerts = [];
  List<DashboardAlert> _warningAlerts = [];

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
        _isLoading = false;
      });

      _evaluateAlerts();
    } catch (e) {
      print("Error fetching dashboard data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _evaluateAlerts() {
    _criticalAlerts.clear();
    _warningAlerts.clear();

    // CRITICAL ALERT 1: Animal Under Treatment Too Long
    final now = DateTime.now();
    for (var event in _healthEvents) {
      if (event.nextCheckupDate != null) {
        final checkupDate = DateTime.tryParse(event.nextCheckupDate!);
        final eventDate = DateTime.tryParse(event.eventDate);
        if (checkupDate != null && eventDate != null) {
          final daysSinceEvent = now.difference(eventDate).inDays;
          final expectedDays = checkupDate.difference(eventDate).inDays;
          if (daysSinceEvent > expectedDays && daysSinceEvent > 3) {
            final animal = _animals.firstWhere((a) => a.id == event.animalId, orElse: () => _animals.first);
            _criticalAlerts.add(DashboardAlert(
              severity: 'critical',
              title: '${animal.name ?? animal.tagNumber} under treatment too long',
              description: '$daysSinceEvent days (Expected: $expectedDays)',
              icon: Icons.medical_services,
              color: Colors.red,
            ));
          }
        }
      }
    }

    // CRITICAL ALERT 2: Sudden Drop in Individual Production
    Map<int, List<double>> animalProduction = {};
    for (var record in _milkRecords) {
      animalProduction.putIfAbsent(record.animalId, () => []).add(record.totalYield);
    }
    
    animalProduction.forEach((animalId, yields) {
      if (yields.length >= 3) {
        final recent3 = yields.sublist(yields.length - 3);
        final avg = yields.reduce((a, b) => a + b) / yields.length;
        final recentAvg = recent3.reduce((a, b) => a + b) / 3;
        if (avg > 0 && ((avg - recentAvg) / avg) >= 0.3) {
          final animal = _animals.firstWhere((a) => a.id == animalId, orElse: () => _animals.first);
          _criticalAlerts.add(DashboardAlert(
            severity: 'critical',
            title: '${animal.name ?? animal.tagNumber} production dropped 30%+',
            description: 'Recent avg: ${recentAvg.toStringAsFixed(1)}L vs ${avg.toStringAsFixed(1)}L',
            icon: Icons.trending_down,
            color: Colors.red,
          ));
        }
      }
    });

    // CRITICAL ALERT 3: Mortality Event
    final deadAnimals = _animals.where((a) => a.status?.toLowerCase() == 'dead').toList();
    for (var animal in deadAnimals) {
      _criticalAlerts.add(DashboardAlert(
        severity: 'critical',
        title: 'Mortality: ${animal.name ?? animal.tagNumber}',
        description: 'Disposal reason: ${animal.disposalReason ?? "Not specified"}',
        icon: Icons.dangerous,
        color: Colors.red,
      ));
    }

    // CRITICAL ALERT 4: Operating Cost per Animal Exceeded
    final totalExpenses = _transactions.where((t) => t.type == 'Expense').fold(0.0, (sum, t) => sum + t.amount);
    final costPerAnimal = _animals.isNotEmpty ? totalExpenses / _animals.length : 0;
    if (costPerAnimal > 5000) {
      _criticalAlerts.add(DashboardAlert(
        severity: 'critical',
        title: 'Operating cost per animal exceeded',
        description: 'KES ${costPerAnimal.toStringAsFixed(0)} per animal (Threshold: 5000)',
        icon: Icons.attach_money,
        color: Colors.red,
      ));
    }

    // CRITICAL ALERT 5: Negative Cash Flow
    final thisMonth = now.month;
    final thisYear = now.year;
    final monthlyIncome = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Income' && date != null && date.month == thisMonth && date.year == thisYear;
    }).fold(0.0, (sum, t) => sum + t.amount);
    
    final monthlyExpenses = _transactions.where((t) {
      final date = DateTime.tryParse(t.date);
      return t.type == 'Expense' && date != null && date.month == thisMonth && date.year == thisYear;
    }).fold(0.0, (sum, t) => sum + t.amount);

    if (monthlyExpenses > monthlyIncome) {
      _criticalAlerts.add(DashboardAlert(
        severity: 'critical',
        title: 'Negative cash flow this month',
        description: 'Expenses exceed income by KES ${(monthlyExpenses - monthlyIncome).toStringAsFixed(0)}',
        icon: Icons.money_off,
        color: Colors.red,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
      ));
    }

    // CRITICAL ALERT 6: Feed Consumption Spike
    final last7Days = now.subtract(const Duration(days: 7));
    final prev7Days = now.subtract(const Duration(days: 14));
    
    final recentFeed = _penFeedLogs.where((l) {
      final date = DateTime.tryParse(l.logDate);
      return date != null && date.isAfter(last7Days);
    }).fold(0.0, (sum, l) => sum + l.cost);
    
    final previousFeed = _penFeedLogs.where((l) {
      final date = DateTime.tryParse(l.logDate);
      return date != null && date.isAfter(prev7Days) && date.isBefore(last7Days);
    }).fold(0.0, (sum, l) => sum + l.cost);

    final recentMilk = _milkRecords.where((r) {
      final date = DateTime.tryParse(r.date);
      return date != null && date.isAfter(last7Days);
    }).fold(0.0, (sum, r) => sum + r.totalYield);
    
    final previousMilk = _milkRecords.where((r) {
      final date = DateTime.tryParse(r.date);
      return date != null && date.isAfter(prev7Days) && date.isBefore(last7Days);
    }).fold(0.0, (sum, r) => sum + r.totalYield);

    if (previousFeed > 0 && recentFeed > previousFeed * 1.2 && recentMilk <= previousMilk) {
      _criticalAlerts.add(DashboardAlert(
        severity: 'critical',
        title: 'Feed consumption spike detected',
        description: '+${((recentFeed - previousFeed) / previousFeed * 100).toStringAsFixed(0)}% without production increase',
        icon: Icons.grass,
        color: Colors.orange,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDashboardScreen())),
      ));
    }

    // WARNING ALERT 8: Herd Average Production Declining
    if (_milkRecords.length >= 14) {
      final sortedRecords = _milkRecords.toList()..sort((a, b) => a.date.compareTo(b.date));
      final recent7 = sortedRecords.sublist(sortedRecords.length - 7);
      final previous7 = sortedRecords.sublist(sortedRecords.length - 14, sortedRecords.length - 7);
      
      final recentAvg = recent7.fold(0.0, (sum, r) => sum + r.totalYield) / 7;
      final prevAvg = previous7.fold(0.0, (sum, r) => sum + r.totalYield) / 7;
      
      if (prevAvg > 0 && ((prevAvg - recentAvg) / prevAvg) >= 0.10) {
        _warningAlerts.add(DashboardAlert(
          severity: 'warning',
          title: 'Herd average production declining',
          description: '${((prevAvg - recentAvg) / prevAvg * 100).toStringAsFixed(0)}% drop over 7 days',
          icon: Icons.trending_down,
          color: Colors.orange,
        ));
      }
    }

    // WARNING ALERT 11: Missed Scheduled Activity
    for (var event in _healthEvents) {
      if (event.nextCheckupDate != null) {
        final checkupDate = DateTime.tryParse(event.nextCheckupDate!);
        if (checkupDate != null && checkupDate.isBefore(now)) {
          final animal = _animals.firstWhere((a) => a.id == event.animalId, orElse: () => _animals.first);
          _warningAlerts.add(DashboardAlert(
            severity: 'warning',
            title: 'Overdue checkup: ${animal.name ?? animal.tagNumber}',
            description: 'Due: ${DateFormat('MMM d').format(checkupDate)}',
            icon: Icons.event_busy,
            color: Colors.orange,
          ));
        }
      }
    }

    setState(() {});
  }

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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSheet(context),
        child: const Icon(Icons.add),
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

  // Continue in next message due to length...
