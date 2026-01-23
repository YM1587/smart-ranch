import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class FeedLogForm extends StatefulWidget {
  final int farmerId;
  const FeedLogForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _FeedLogFormState createState() => _FeedLogFormState();
}

class _FeedLogFormState extends State<FeedLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  int? _selectedPenId;
  String _feedType = 'Napier Grass';
  List<Pen> _pens = [];
  bool _isLoading = false;

  final List<String> _feedTypes = [
    'Napier Grass', 'Dairy Meal', 'Maize Bran', 'Hay', 'Silage', 
    'Concentrates', 'Mineral Supplement', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadPens();
  }

  Future<void> _loadPens() async {
    try {
      final pens = await ApiService.getPens(widget.farmerId);
      setState(() {
        _pens = pens;
        if (_pens.isNotEmpty) {
          _selectedPenId = _pens[0].id;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedPenId != null) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'pen_id': _selectedPenId,
        'feed_type': _feedType,
        'quantity_kg': double.tryParse(_quantityController.text) ?? 0.0,
        'cost_per_kg': double.tryParse(_costController.text) ?? 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
      };

      try {
        await ApiService.createFeedLog(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed log added successfully!')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Log Feed')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedPenId,
                decoration: const InputDecoration(labelText: 'Pen'),
                items: _pens.map<DropdownMenuItem<int>>((pen) {
                  return DropdownMenuItem<int>(
                    value: pen.id,
                    child: Text("${pen.name} (${pen.livestockType})"),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPenId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _feedType,
                decoration: const InputDecoration(labelText: 'Feed Type'),
                items: _feedTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _feedType = value!),
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost per kg'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
