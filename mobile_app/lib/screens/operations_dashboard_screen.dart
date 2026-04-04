import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class OperationsDashboardScreen extends StatefulWidget {
  const OperationsDashboardScreen({Key? key}) : super(key: key);

  @override
  _OperationsDashboardScreenState createState() => _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState extends State<OperationsDashboardScreen> {
  final int farmerId = ApiService.farmerId ?? 1;
  bool _isLoading = true;

  List<Animal> _animals = [];
  List<HealthEvent> _healthEvents = [];
  List<FeedLog> _penFeedLogs = [];
  List<IndividualFeedLog> _indFeedLogs = [];
  List<MilkProduction> _milkRecords = [];
  List<WeightRecord> _weightRecords = [];
  List<BreedingRecord> _breedingRecords = [];
  List<LaborActivity> _laborActivities = [];

  Map<String, dynamic> _healthSummary = {};
  Map<String, dynamic> _breedingSummary = {};
  List<dynamic> _sickAnimals = [];
  List<dynamic> _pregnantAnimals = [];
  List<dynamic> _dueSoonAnimals = [];
  List<dynamic> _pendingBreeding = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  Future<void> _fetchData() async {
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
        ApiService.getHealthSummary(farmerId),
        ApiService.getBreedingSummary(farmerId),
        ApiService.getSickAnimals(farmerId),
        ApiService.getPregnantAnimals(farmerId),
        ApiService.getDueSoonAnimals(farmerId),
        ApiService.getPendingBreeding(farmerId),
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
        _healthSummary = results[8] as Map<String, dynamic>;
        _breedingSummary = results[9] as Map<String, dynamic>;
        _sickAnimals = results[10] as List<dynamic>;
        _pregnantAnimals = results[11] as List<dynamic>;
        _dueSoonAnimals = results[12] as List<dynamic>;
        _pendingBreeding = results[13] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching operations data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Operations Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOverviewStrip(),
            _buildIntelligenceBrief(),
            _buildFeedSection(),
            _buildHealthSection(),
            _buildProductionSection(),
            _buildBreedingSection(),
            _buildLaborSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- 0. OVERVIEW STRIP ---
  Widget _buildOverviewStrip() {
    final animalCount = _animals.length.clamp(1, 999999);
    final totalFeed = _penFeedLogs.fold(0.0, (sum, item) => sum + item.cost) +
        _indFeedLogs.fold(0.0, (sum, item) => sum + item.cost);
    final totalHealth = _healthEvents.fold(0.0, (sum, item) => sum + (item.cost ?? 0));
    final totalLabor = _laborActivities.fold(0.0, (sum, item) => sum + item.laborCost);
    final totalMilk = _milkRecords.fold(0.0, (sum, item) => sum + item.totalYield);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStripMetric('Feed/Animal', totalFeed / animalCount, Icons.grass, Colors.green),
            _buildStripMetric('Health/Animal', totalHealth / animalCount, Icons.medical_services, Colors.red),
            _buildStripMetric('Labor/Animal', totalLabor / animalCount, Icons.work, Colors.orange),
            _buildStripMetric('Avg Milk', totalMilk / animalCount, Icons.water_drop, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStripMetric(String label, double value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label.contains('Milk') ? value.toStringAsFixed(1) + 'L' : NumberFormat.compactCurrency(symbol: 'K').format(value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- INTELLIGENCE BRIEF (RED FLAGS) ---
  Widget _buildIntelligenceBrief() {
    List<Widget> insights = [];

    // 1. Feed Inefficiency Check
    if (_penFeedLogs.isNotEmpty && _milkRecords.isNotEmpty) {
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      
      final recentFeed = _penFeedLogs.where((l) => DateTime.tryParse(l.date)?.isAfter(last7Days) ?? false).fold(0.0, (s, i) => s + i.cost);
      final prevFeed = _penFeedLogs.where((l) => (DateTime.tryParse(l.date)?.isBefore(last7Days) ?? false) && (DateTime.tryParse(l.date)?.isAfter(now.subtract(const Duration(days: 14))) ?? false)).fold(0.0, (s, i) => s + i.cost);
      
      final recentMilk = _milkRecords.where((r) => DateTime.tryParse(r.date)?.isAfter(last7Days) ?? false).fold(0.0, (s, i) => s + i.totalYield);
      final prevMilk = _milkRecords.where((r) => (DateTime.tryParse(r.date)?.isBefore(last7Days) ?? false) && (DateTime.tryParse(r.date)?.isAfter(now.subtract(const Duration(days: 14))) ?? false)).fold(0.0, (s, i) => s + i.totalYield);

      if (recentFeed > prevFeed && recentMilk <= prevMilk && prevFeed > 0) {
        insights.add(_buildInsightItem(
          'Feed Efficiency Decline',
          'Feed costs are up ${( (recentFeed-prevFeed)/prevFeed * 100 ).toStringAsFixed(1)}% this week, but milk yield has not increased. Check feed quality or animal health.',
          Icons.trending_down,
          Colors.orange,
        ));
      }
    }

    // 2. Health Outbreak Detection
    Map<int, int> recentPenHealth = {};
    for (var event in _healthEvents) {
      final date = DateTime.tryParse(event.date);
      if (date != null && date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
        final animal = _animals.firstWhere((a) => a.id == event.animalId, orElse: () => _animals.first);
        final penId = animal.penId ?? 0;
        recentPenHealth[penId] = (recentPenHealth[penId] ?? 0) + 1;
      }
    }
    
    recentPenHealth.forEach((penId, count) {
      if (count >= 3) {
        final penName = _animals.firstWhere((a) => a.penId == penId, orElse: () => _animals.first).penId.toString(); // Placeholder name fetching
        insights.add(_buildInsightItem(
          'Potential Pen Outbreak',
          '$count health events reported in the same pen this week. Consider sanitary audit.',
          Icons.warning_amber_rounded,
          Colors.red,
        ));
      }
    });

    if (insights.isEmpty) {
      insights.add(_buildInsightItem(
        'Operational Smoothness',
        'All metrics are within normal variance. Production efficiency is stable.',
        Icons.check_circle_outline,
        Colors.green,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INTELLIGENCE BRIEF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...insights,
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. FEED SECTION ---
  Widget _buildFeedSection() {
    final totalFeedCost = _penFeedLogs.fold(0.0, (sum, item) => sum + item.cost) +
        _indFeedLogs.fold(0.0, (sum, item) => sum + item.cost);
    final totalFeedQty = _penFeedLogs.fold(0.0, (sum, item) => sum + item.quantityKg) +
        _indFeedLogs.fold(0.0, (sum, item) => sum + item.quantityKg);
    
    final efficiency = totalFeedQty > 0 ? (totalFeedCost / totalFeedQty) : 0.0;
    
    return _buildSectionCard(
      'Feed & Nutrition',
      [
        _buildTrendGraph('Feed Cost vs Quantity', Colors.green),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Cost/kg', 'KES ${efficiency.toStringAsFixed(1)}', 'Avg Rate'),
          _buildDetailMetric('Total Feed', NumberFormat.compact().format(totalFeedCost), 'Total KES'),
        ]),
      ],
      Icons.grass,
    );
  }

  Widget _buildHealthSection() {
    int sickCount = _healthSummary['sick'] ?? 0;
    int underTreatmentCount = _healthSummary['under_treatment'] ?? 0;

    return _buildSectionCard(
      'Health Status',
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusCounter('Sick', sickCount, Colors.red),
            _buildStatusCounter('Treatment', underTreatmentCount, Colors.orange),
          ],
        ),
        if (_sickAnimals.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Needs Attention', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
          const SizedBox(height: 8),
          ..._sickAnimals.map((a) => _buildActionableAnimalRow(a, 'Sick')),
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () {
              // Open Health Record Form
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Health Record'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        )
      ],
      Icons.medical_services,
    );
  }

  Widget _buildStatusCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionableAnimalRow(dynamic a, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(a['tag_number'][0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['name'] ?? a['tag_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(a['condition'] ?? a['expected_calving_date'] ?? a['breeding_date'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (status == 'Pending' && a['breeding_id'] != null)
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      await ApiService.markBreedingPregnant(a['breeding_id']);
                      _fetchData();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Pregnant')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.purple, size: 24),
                  tooltip: 'Pregnant',
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await ApiService.markBreedingFailed(a['breeding_id']);
                      _fetchData();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Failed')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                  tooltip: 'Failed',
                ),
              ],
            )
          else if (status == 'Sick' && a['record_id'] != null)
            TextButton.icon(
              onPressed: () async {
                try {
                  await ApiService.resolveHealthRecord(a['record_id']);
                  _fetchData(); // Refresh dashboard data
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Animal marked as treated')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Treated'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding: EdgeInsets.zero,
                minimumSize: const Size(80, 36),
              ),
            )
          else if (status == 'Failed' && a['breeding_id'] != null)
            TextButton.icon(
              onPressed: () async {
                try {
                  await ApiService.markBreedingPregnant(a['breeding_id']);
                  _fetchData();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Pregnant')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              icon: const Icon(Icons.pregnant_woman, size: 16),
              label: const Text('Pregnant?'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
                padding: EdgeInsets.zero,
                minimumSize: const Size(80, 36),
              ),
            )
          else if ((status == 'Pregnant' || status == 'Due Soon') && a['breeding_id'] != null)
            TextButton.icon(
              onPressed: () async {
                try {
                  await ApiService.markBreedingCalved(a['breeding_id']);
                  _fetchData();
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked Calved')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              icon: const Icon(Icons.child_care, size: 16),
              label: const Text('Calved?'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(80, 36),
              ),
            )
          else
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // --- 3. LABOR SECTION ---
  Widget _buildLaborSection() {
    final totalHours = _laborActivities.fold(0.0, (sum, item) => sum + item.hoursSpent);
    final totalCost = _laborActivities.fold(0.0, (sum, item) => sum + item.laborCost);
    final avgRate = totalHours > 0 ? (totalCost / totalHours) : 0.0;
    
    return _buildSectionCard(
      'Labor & Operations',
      [
        _buildLaborPie(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Man Hours', '${totalHours.toStringAsFixed(1)}h', 'Total'),
          _buildDetailMetric('Cost/H', 'KES ${avgRate.toStringAsFixed(0)}', 'Avg Rate'),
        ]),
      ],
      Icons.work,
    );
  }

  Widget _buildBreedingSection() {
    int pregnantCount = _breedingSummary['pregnant'] ?? 0;
    int dueSoonCount = _breedingSummary['due_soon'] ?? 0;
    int failedCount = _breedingSummary['failed'] ?? 0;

    return _buildSectionCard(
      'Breeding Status',
      [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusCounter('Pregnant', pregnantCount, Colors.purple),
            _buildStatusCounter('Due Soon', dueSoonCount, Colors.blue),
            _buildStatusCounter('Failed', failedCount, Colors.red),
          ],
        ),
        if (_dueSoonAnimals.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Due Soon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
          const SizedBox(height: 8),
          ..._dueSoonAnimals.map((a) => _buildActionableAnimalRow(a, 'Due Soon')),
        ],
        if (_pendingBreeding.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Breeding Tasks (Check Pregnancy)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
          const SizedBox(height: 8),
          ..._pendingBreeding.map((a) => _buildActionableAnimalRow(a, 'Pending')),
        ],
      ],
      Icons.pregnant_woman,
    );
  }

  // --- 5. PRODUCTION SECTION ---
  Widget _buildProductionSection() {
    final totalMilk = _milkRecords.fold(0.0, (sum, item) => sum + item.totalYield);
    final milkingCows = _animals.where((a) => a.sex == 'Female' && a.status == 'Active').length;
    final avgPerCow = milkingCows > 0 ? (totalMilk / milkingCows) : 0.0;
    
    return _buildSectionCard(
      'Production Analytics',
      [
        _buildProductionChart(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Avg Yield', '${avgPerCow.toStringAsFixed(1)}L', 'Per Cow'),
          _buildDetailMetric('Total Milk', '${totalMilk.toStringAsFixed(0)}L', 'All Records'),
        ]),
      ],
      Icons.insights,
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildSectionCard(String title, List<Widget> children, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children.expand((w) => [w, const SizedBox(width: 16)]).toList()..removeLast(),
    );
  }

  Widget _buildDetailMetric(String label, String value, String subLabel) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subLabel, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // --- CHART VISUALIZATIONS ---

  Widget _buildTrendGraph(String title, Color color) {
    // Group feed by type and calculate totals
    Map<String, double> feedTypeCosts = {};
    for (var log in _penFeedLogs) {
      feedTypeCosts[log.feedType] = (feedTypeCosts[log.feedType] ?? 0) + log.cost;
    }
    for (var log in _indFeedLogs) {
      feedTypeCosts[log.feedType] = (feedTypeCosts[log.feedType] ?? 0) + log.cost;
    }
    
    // Get top 5 feed types
    final sortedFeed = feedTypeCosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFeed = sortedFeed.take(5).toList();
    
    if (topFeed.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No feed data available', style: TextStyle(color: Colors.grey))),
      );
    }
    
    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (topFeed.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2),
          minY: 0, // Zero baseline
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < topFeed.length) {
                    final feedType = topFeed[value.toInt()].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        feedType.length > 10 ? '${feedType.substring(0, 10)}...' : feedType,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          barGroups: topFeed.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLaborPie() {
    // Calculate labor distribution by activity type
    Map<String, double> activityCosts = {};
    for (var activity in _laborActivities) {
      activityCosts[activity.activityType] = 
          (activityCosts[activity.activityType] ?? 0) + activity.laborCost;
    }
    
    // Limit to top 5 categories, group rest as "Other"
    final sortedEntries = activityCosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.grey];
    List<PieChartSectionData> sections = [];
    
    if (sortedEntries.isEmpty) {
      sections.add(PieChartSectionData(
        color: Colors.grey[300]!,
        value: 1,
        title: 'No Data',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
      ));
    } else {
      for (int i = 0; i < sortedEntries.length && i < 5; i++) {
        sections.add(PieChartSectionData(
          color: colors[i],
          value: sortedEntries[i].value,
          title: sortedEntries[i].key,
          radius: 50,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
      
      // Group remaining as "Other" if more than 5 categories
      if (sortedEntries.length > 5) {
        final otherValue = sortedEntries.skip(5).fold(0.0, (sum, e) => sum + e.value);
        sections.add(PieChartSectionData(
          color: colors[5],
          value: otherValue,
          title: 'Other',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ));
      }
    }
    
    return SizedBox(
      height: 150,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 0, // No donut hole - proper pie chart
          sections: sections,
        ),
      ),
    );
  }

  Widget _buildTreatmentDistChart() {
    // Group health events by condition type
    Map<String, int> conditionCounts = {};
    for (var event in _healthEvents) {
      conditionCounts[event.condition] = (conditionCounts[event.condition] ?? 0) + 1;
    }
    
    // Get top 5 conditions
    final sortedConditions = conditionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topConditions = sortedConditions.take(5).toList();
    
    if (topConditions.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No health data available', style: TextStyle(color: Colors.grey))),
      );
    }
    
    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (topConditions.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2).toDouble(),
          minY: 0, // Zero baseline
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < topConditions.length) {
                    final condition = topConditions[value.toInt()].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        condition.length > 8 ? '${condition.substring(0, 8)}...' : condition,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2),
          barGroups: topConditions.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value.toDouble(),
                  color: Colors.red,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductionChart() {
    // Group milk production by date
    Map<String, double> dailyMilk = {};
    for (var record in _milkRecords) {
      dailyMilk[record.date] = (dailyMilk[record.date] ?? 0) + record.totalYield;
    }
    
    // Sort dates and create spots
    final sortedDates = dailyMilk.keys.toList()..sort();
    
    if (sortedDates.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No production data available', style: TextStyle(color: Colors.grey))),
      );
    }
    
    // Take last 30 days or all if less
    final recentDates = sortedDates.length > 30 ? sortedDates.sublist(sortedDates.length - 30) : sortedDates;
    
    List<FlSpot> spots = [];
    for (int i = 0; i < recentDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyMilk[recentDates[i]]!));
    }
    
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) / 5,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < recentDates.length) {
                    // Show every 5th date
                    if (value.toInt() % 5 == 0) {
                      final date = DateTime.tryParse(recentDates[value.toInt()]);
                      if (date != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        );
                      }
                    }
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0, // Zero baseline
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: spots.length < 15), // Show dots only if few data points
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingFunnel() {
    final totalCycles = _breedingRecords.length;
    final pregnant = _breedingRecords.where((r) => r.pregnancyStatus == 'Pregnant').length;
    final births = _breedingRecords.where((r) => r.outcome == 'Live Calf').length;
    final notPregnant = _breedingRecords.where((r) => r.pregnancyStatus == 'Not Pregnant').length;
    
    return Column(
      children: [
        _buildFunnelStep('Total Cycles', '$totalCycles', 1.0, Colors.pink[100]!),
        _buildFunnelStep('Pregnant', '$pregnant', totalCycles > 0 ? pregnant / totalCycles : 0.0, Colors.pink[200]!),
        _buildFunnelStep('Births', '$births', totalCycles > 0 ? births / totalCycles : 0.0, Colors.pink[300]!),
        _buildFunnelStep('Not Pregnant', '$notPregnant', totalCycles > 0 ? notPregnant / totalCycles : 0.0, Colors.pink[400]!),
      ],
    );
  }

  Widget _buildFunnelStep(String label, String value, double widthFactor, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                height: 20,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
