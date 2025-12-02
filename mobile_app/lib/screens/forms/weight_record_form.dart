import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WeightRecordForm extends StatefulWidget {
  final int farmerId;
  const WeightRecordForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _WeightRecordFormState createState() => _WeightRecordFormState();
}

class _WeightRecordFormState extends State<WeightRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bcsController = TextEditingController();
  int? _selectedAnimalId;
  List<dynamic> _animals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final animals = await ApiService.getAnimals(widget.farmerId);
      setState(() {
        _animals = animals;
        if (_animals.isNotEmpty) {
          _selectedAnimalId = _animals[0]['animal_id'];
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedAnimalId != null) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'animal_id': _selectedAnimalId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
        'body_condition_score': int.tryParse(_bcsController.text),
      };

      try {
        await ApiService.createWeightRecord(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight record added successfully!')),
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
      appBar: AppBar(title: const Text('Record Weight')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedAnimalId,
                decoration: const InputDecoration(labelText: 'Animal'),
                items: _animals.map<DropdownMenuItem<int>>((animal) {
                  return DropdownMenuItem<int>(
                    value: animal['animal_id'],
                    child: Text('${animal['tag_number']}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedAnimalId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _bcsController,
                decoration: const InputDecoration(labelText: 'Body Condition Score (1-5)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
