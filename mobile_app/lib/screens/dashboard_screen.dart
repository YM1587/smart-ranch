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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🔴 ${_criticalAlerts.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🟨 ${_warningAlerts.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        if (_criticalAlerts.isEmpty && _warningAlerts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'All systems operational. No alerts at this time.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_criticalAlerts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Critical Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                ..._criticalAlerts.map((alert) => _buildAlertCard(alert)),
              ],
            ),
          ),
        ],
        if (_warningAlerts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => setState(() => _showWarnings = !_showWarnings),
              child: Row(
                children: [
                  Icon(_showWarnings ? Icons.expand_less : Icons.expand_more, size: 20),
                  const SizedBox(width: 4),
                  Text('Warnings (${_warningAlerts.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
          ),
          if (_showWarnings) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _warningAlerts.map((alert) => _buildAlertCard(alert)).toList(),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
      ],
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

  Widget _buildAlertCard(DashboardAlert alert) {
    return InkWell(
      onTap: alert.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alert.color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(alert.icon, color: alert.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold, color: alert.color, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(alert.description, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                  if (alert.onTap != null) ...[
                    const SizedBox(height: 4),
                    Text('→ Tap to view', style: TextStyle(fontSize: 10, color: alert.color, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
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
              _buildActionTile(context, 'Add Animal', Icons.pets, () => AnimalForm(farmerId: farmerId)),
              _buildActionTile(context, 'Milk Record', Icons.water_drop, () => MilkProductionForm(farmerId: farmerId)),
              _buildActionTile(context, 'Weight Record', Icons.monitor_weight, () => WeightRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Breeding', Icons.favorite, () => BreedingRecordForm(farmerId: farmerId)),
              _buildActionTile(context, 'Feed Log', Icons.grass, () => FeedLogForm(farmerId: farmerId)),
              _buildActionTile(context, 'Health', Icons.medical_services, () => HealthRecordForm(farmerId: farmerId)),
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => pageBuilder()));
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
