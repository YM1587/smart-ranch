import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'forms/financial_transaction_form.dart';

enum TimeRange { today, week, month, year, custom, all }

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinancialTransaction> _allTransactions = [];
  List<FinancialTransaction> _filteredTransactions = [];
  bool _isLoading = true;
  TimeRange _selectedRange = TimeRange.month;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await ApiService.getFinancialTransactions();
      setState(() {
        _allTransactions = data;
        _filterTransactions();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _filterTransactions() {
    final now = DateTime.now();
    setState(() {
      _filteredTransactions = _allTransactions.where((t) {
        final tDate = DateTime.tryParse(t.date) ?? DateTime(1970);
        switch (_selectedRange) {
          case TimeRange.today:
            return tDate.year == now.year && tDate.month == now.month && tDate.day == now.day;
          case TimeRange.week:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            return tDate.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          case TimeRange.month:
            return tDate.year == now.year && tDate.month == now.month;
          case TimeRange.year:
            return tDate.year == now.year;
          case TimeRange.custom:
            if (_customRange == null) return true;
            return tDate.isAfter(_customRange!.start.subtract(const Duration(seconds: 1))) &&
                   tDate.isBefore(_customRange!.end.add(const Duration(days: 1)));
          case TimeRange.all:
            return true;
        }
      }).toList();
      _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in _filteredTransactions) {
      if (t.type == 'Income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    double netProfit = totalIncome - totalExpense;
    double profitMargin = totalIncome > 0 ? (netProfit / totalIncome) * 100 : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart), 
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancialTransactionForm(farmerId: 1)),
              );
              _loadTransactions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRangeSelector(),
                    _buildSummaryGrid(totalIncome, totalExpense, netProfit, profitMargin),
                    _buildInsights(totalIncome, totalExpense, netProfit),
                    _buildTrendChart(),
                    if (totalIncome > 0) _buildChartSection('INCOME BREAKDOWN', 'Income', Colors.green),
                    if (totalExpense > 0) _buildChartSection('EXPENSE BREAKDOWN', 'Expense', Colors.red),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    _buildTransactionList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChartSection(String title, String type, Color color) {
    // Aggregate by category
    Map<String, double> categories = {};
    final filtered = _filteredTransactions.where((t) => t.type == type).toList();
    for (var t in filtered) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }

    final total = filtered.fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: categories.entries.map((e) {
                  final percentage = (e.value / total) * 100;
                  return PieChartSectionData(
                    color: _getCategoryColor(e.key, color),
                    value: e.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories.keys.map((cat) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: _getCategoryColor(cat, color)),
                  const SizedBox(width: 4),
                  Text(cat, style: const TextStyle(fontSize: 10)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, Color baseColor) {
    // Deterministic colors based on category name
    final hash = category.hashCode;
    return baseColor.withOpacity(0.5 + (hash % 50) / 100);
  }

  Widget _buildTrendChart() {
    if (_filteredTransactions.isEmpty) return const SizedBox.shrink();

    // Aggregate by date
    Map<String, double> dailyProfit = {};
    for (var t in _filteredTransactions) {
      final amount = t.type == 'Income' ? t.amount : -t.amount;
      dailyProfit[t.date] = (dailyProfit[t.date] ?? 0) + amount;
    }

    final sortedDates = dailyProfit.keys.toList()..sort();
    if (sortedDates.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyProfit[sortedDates[i]]!));
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DAILY PERFORMANCE TREND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: TimeRange.values.map((range) {
            final isSelected = _selectedRange == range;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(range.name.toUpperCase()),
                selected: isSelected,
                onSelected: (val) async {
                  if (val) {
                    if (range == TimeRange.custom) {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _customRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedRange = range;
                          _customRange = picked;
                        });
                        _filterTransactions();
                      }
                    } else {
                      setState(() => _selectedRange = range);
                      _filterTransactions();
                    }
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(double income, double expense, double profit, double margin) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('TOTAL INCOME', income, Icons.trending_up, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('TOTAL EXPENSE', expense, Icons.trending_down, Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricCard('NET PROFIT', profit, Icons.account_balance_wallet, profit >= 0 ? Colors.blue : Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard('MARGIN', margin, Icons.pie_chart, Colors.purple, isPercent: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double value, IconData icon, Color color, {bool isPercent = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              isPercent ? '${value.toStringAsFixed(1)}%' : 'KES ${NumberFormat("#,##0").format(value)}',
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(double income, double expense, double profit) {
    List<Widget> insights = [];
    if (expense > income && income > 0) {
      insights.add(_insightRow('⚠️ Expenses exceed income. Check feed costs.', Colors.orange));
    }
    if (profit < 0) {
      insights.add(_insightRow('🚨 Net loss recorded for this period.', Colors.red));
    }
    if (income == 0 && !_isLoading) {
      insights.add(_insightRow('ℹ️ No income recorded for this period.', Colors.blueGrey));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(children: insights),
    );
  }

  Widget _insightRow(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(Icons.info_outline, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No transactions for this range.')));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredTransactions.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = _filteredTransactions[index];
        final isIncome = t.type == 'Income';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isIncome ? Colors.green[50] : Colors.red[50],
            child: Icon(isIncome ? Icons.add : Icons.remove, color: isIncome ? Colors.green : Colors.red, size: 18),
          ),
          title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${t.date} • ${t.description ?? "No description"}'),
          trailing: Text(
            '${isIncome ? "+" : "-"} ${t.amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red),
          ),
        );
      },
    );
  }
}
