import 'package:flutter/material.dart';
import '../../services/api_service.dart';

import '../../models/models.dart';

class MilkProductionForm extends StatefulWidget {
  final int farmerId;
  const MilkProductionForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _MilkProductionFormState createState() => _MilkProductionFormState();
}

class _MilkProductionFormState extends State<MilkProductionForm> {
  final _formKey = GlobalKey<FormState>();
  final _morningYieldController = TextEditingController();
  final _eveningYieldController = TextEditingController();
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
      final pens = await ApiService.getPens(widget.farmerId);
      final animals = await ApiService.getAnimals(widget.farmerId);

      // Find the ID of the "Milking Parlor" pen
      final parlorPens = pens.where((p) => p.name.toLowerCase() == 'milking parlor');
      final parlorIds = parlorPens.map((p) => p.id).toSet();

      setState(() {
        _animals = animals.where((a) => parlorIds.contains(a.penId)).toList();
        _animals.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
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
        'morning_yield': double.tryParse(_morningYieldController.text) ?? 0.0,
        'evening_yield': double.tryParse(_eveningYieldController.text) ?? 0.0,
      };

      try {
        await ApiService.createMilkProduction(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk record added successfully!')),
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
      appBar: AppBar(title: const Text('Record Milk Production')),
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
                controller: _morningYieldController,
                decoration: const InputDecoration(labelText: 'Morning Yield (L)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _eveningYieldController,
                decoration: const InputDecoration(labelText: 'Evening Yield (L)'),
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
