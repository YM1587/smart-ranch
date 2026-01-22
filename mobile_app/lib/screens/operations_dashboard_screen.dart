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
  final int farmerId = 1;
  bool _isLoading = true;

  List<Animal> _animals = [];
  List<HealthEvent> _healthEvents = [];
  List<FeedLog> _penFeedLogs = [];
  List<IndividualFeedLog> _indFeedLogs = [];
  List<MilkProduction> _milkRecords = [];
  List<WeightRecord> _weightRecords = [];
  List<BreedingRecord> _breedingRecords = [];
  List<LaborActivity> _laborActivities = [];

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
      
      final recentFeed = _penFeedLogs.where((l) => DateTime.tryParse(l.logDate)?.isAfter(last7Days) ?? false).fold(0.0, (s, i) => s + i.cost);
      final prevFeed = _penFeedLogs.where((l) => (DateTime.tryParse(l.logDate)?.isBefore(last7Days) ?? false) && (DateTime.tryParse(l.logDate)?.isAfter(now.subtract(const Duration(days: 14))) ?? false)).fold(0.0, (s, i) => s + i.cost);
      
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
      final date = DateTime.tryParse(event.eventDate);
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
    return _buildSectionCard(
      'Feed & Nutrition',
      [
        _buildTrendGraph('Feed Cost vs Quantity', Colors.green),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Efficiency', '1.2kg/K', 'Conversion'),
          _buildDetailMetric('Monthly Feed', NumberFormat.compact().format(54000), 'Total KES'),
        ]),
      ],
      Icons.grass,
    );
  }

  // --- 2. HEALTH SECTION ---
  Widget _buildHealthSection() {
    return _buildSectionCard(
      'Health & Veterinary',
      [
        _buildTreatmentDistChart(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Active Cases', '4', 'Animals'),
          _buildDetailMetric('Vet Expenditure', 'KES 12k', 'This Month'),
        ]),
      ],
      Icons.medical_services,
    );
  }

  // --- 3. LABOR SECTION ---
  Widget _buildLaborSection() {
    return _buildSectionCard(
      'Labor & Operations',
      [
        _buildLaborPie(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Man Hours', '142h', 'Total Month'),
          _buildDetailMetric('Cost/H', 'KES 450', 'Avg Rate'),
        ]),
      ],
      Icons.work,
    );
  }

  // --- 4. BREEDING SECTION ---
  Widget _buildBreedingSection() {
    return _buildSectionCard(
      'Breeding & Reproduction',
      [
        _buildBreedingFunnel(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Success Rate', '68%', 'Pregnancy'),
          _buildDetailMetric('Calving Int.', '380d', 'Avg Days'),
        ]),
      ],
      Icons.favorite,
    );
  }

  // --- 5. PRODUCTION SECTION ---
  Widget _buildProductionSection() {
    return _buildSectionCard(
      'Production Analytics',
      [
        _buildProductionChart(),
        const SizedBox(height: 16),
        _buildMetricRow([
          _buildDetailMetric('Daily Avg', '18.4L', 'Per Cow'),
          _buildDetailMetric('Top Pen', 'Pen B', 'Yield Leader'),
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

  // --- CHART PLACEHOLDERS (To be populated with real data logic) ---

  Widget _buildTrendGraph(String title, Color color) {
    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [const FlSpot(0, 3), const FlSpot(1, 1), const FlSpot(2, 4), const FlSpot(3, 2), const FlSpot(4, 5)],
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborPie() {
    return SizedBox(
      height: 100,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 20,
          sections: [
            PieChartSectionData(color: Colors.blue, value: 40, title: 'Milk', radius: 40, showTitle: false),
            PieChartSectionData(color: Colors.orange, value: 30, title: 'Feed', radius: 40, showTitle: false),
            PieChartSectionData(color: Colors.red, value: 20, title: 'Health', radius: 40, showTitle: false),
            PieChartSectionData(color: Colors.grey, value: 10, title: 'Other', radius: 40, showTitle: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentDistChart() {
    return SizedBox(
      height: 100,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 5, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 12, color: Colors.red, width: 12, borderRadius: BorderRadius.circular(4))]),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionChart() {
    return _buildTrendGraph('Volume (L)', Colors.blue);
  }

  Widget _buildBreedingFunnel() {
    return Column(
      children: [
        _buildFunnelStep('Cycles', '24', 1.0, Colors.pink[100]!),
        _buildFunnelStep('Inseminated', '18', 0.8, Colors.pink[200]!),
        _buildFunnelStep('Confirmed', '12', 0.6, Colors.pink[300]!),
        _buildFunnelStep('Births', '9', 0.4, Colors.pink[400]!),
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
