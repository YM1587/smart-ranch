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
  int? _selectedPenId;
  int? _selectedAnimalId;
  List<Pen> _pens = [];
  List<Animal> _allAnimals = [];
  List<Animal> _filteredAnimals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pens = await ApiService.getPens(widget.farmerId);
      final animalsData = await ApiService.getAnimals(widget.farmerId);
      
      setState(() {
        _pens = pens;
        _allAnimals = animalsData;
        
        if (_pens.isNotEmpty) {
          _selectedPenId = _pens[0].id;
          _filterAnimals(_selectedPenId!);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _filterAnimals(int penId) {
    setState(() {
      _filteredAnimals = _allAnimals.where((a) => a.penId == penId).toList();
      _filteredAnimals.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
      if (_filteredAnimals.isNotEmpty) {
        _selectedAnimalId = _filteredAnimals[0].id;
      } else {
        _selectedAnimalId = null;
      }
    });
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
                value: _selectedPenId,
                decoration: const InputDecoration(labelText: 'Select Pen'),
                items: _pens.map<DropdownMenuItem<int>>((pen) {
                  return DropdownMenuItem<int>(
                    value: pen.id,
                    child: Text(pen.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPenId = value);
                    _filterAnimals(value);
                  }
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedAnimalId,
                decoration: const InputDecoration(labelText: 'Select Animal'),
                items: _filteredAnimals.map<DropdownMenuItem<int>>((animal) {
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
