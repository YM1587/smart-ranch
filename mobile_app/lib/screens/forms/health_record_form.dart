import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class HealthRecordForm extends StatefulWidget {
  final int farmerId;
  const HealthRecordForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _HealthRecordFormState createState() => _HealthRecordFormState();
}

class _HealthRecordFormState extends State<HealthRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _conditionController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _costController = TextEditingController();
  int? _selectedAnimalId;
  List<Animal> _animals = [];
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
          _selectedAnimalId = _animals[0].id;
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
        'condition': _conditionController.text,
        'symptoms': _symptomsController.text,
        'treatment': _treatmentController.text,
        'cost': double.tryParse(_costController.text) ?? 0.0,
      };

      try {
        await ApiService.createHealthRecord(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health record added successfully!')),
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
      appBar: AppBar(title: const Text('Record Health Event')),
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
                    value: animal.id,
                    child: Text(animal.name ?? animal.tagNumber),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedAnimalId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(labelText: 'Condition/Disease'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _symptomsController,
                decoration: const InputDecoration(labelText: 'Symptoms'),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _treatmentController,
                decoration: const InputDecoration(labelText: 'Treatment'),
                maxLines: 2,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost'),
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
