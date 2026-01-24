import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class FinancialTransactionForm extends StatefulWidget {
  final int farmerId;
  const FinancialTransactionForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _FinancialTransactionFormState createState() => _FinancialTransactionFormState();
}

class _FinancialTransactionFormState extends State<FinancialTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Expense';
  String _category = 'Feed';
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'Milk Sales', 'Animal Sales', 'Manure Sales', 'Breeding Services'
  ];
  final List<String> _expenseCategories = [
    'Transport', 'Equipment', 'Utilities', 'Other'
  ];
  
  @override
  void initState() {
    super.initState();
    _category = 'Transport';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final transaction = FinancialTransaction(
        id: 0, // Backend assigns ID
        type: _type,
        category: _category,
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: DateTime.now().toIso8601String().split('T')[0],
        // farmer_id will be handled by ApiService or backend defaults
      );

      try {
        await ApiService.createFinancialTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentCategories = _type == 'Income' ? _incomeCategories : _expenseCategories;
    if (!currentCategories.contains(_category)) {
      _category = currentCategories[0];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Record Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['Income', 'Expense']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: currentCategories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              if (_type == 'Expense')
                Card(
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Note: Operational expenses like Feed, Vet, and Labor are added automatically when you record those activities.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
