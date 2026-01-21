import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'forms/financial_transaction_form.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<FinancialTransaction> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await ApiService.getFinancialTransactions();
      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in transactions) {
      if (t.type == 'Income') {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    double netProfit = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), 
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancialTransactionForm(farmerId: 1)), // Default farmerId
              );
              _loadTransactions();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(totalIncome, totalExpense, netProfit),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isIncome = t.type == 'Income';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green[100] : Colors.red[100],
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(t.category),
                        subtitle: Text('${t.date}\n${t.description ?? ""}'),
                        isThreeLine: true,
                        trailing: Text(
                          '${isIncome ? "+" : "-"} KES ${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double profit) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildCard('Income', income, Colors.green),
          ),
          Expanded(
            child: _buildCard('Expenses', expense, Colors.red),
          ),
          Expanded(
            child: _buildCard('Net Profit', profit, profit >= 0 ? Colors.blue : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, double amount, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(0)}', // Compact display
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
