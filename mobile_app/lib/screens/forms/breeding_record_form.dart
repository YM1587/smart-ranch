import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class BreedingRecordForm extends StatefulWidget {
  final int farmerId;
  const BreedingRecordForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _BreedingRecordFormState createState() => _BreedingRecordFormState();
}

class _BreedingRecordFormState extends State<BreedingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedFemaleId;
  int? _selectedMaleId;
  String _breedingMethod = 'AI';
  List<Animal> _females = [];
  List<Animal> _males = [];
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
        _females = animals.where((a) => a.sex == 'Female').toList();
        _males = animals.where((a) => a.sex == 'Male').toList();
        if (_females.isNotEmpty) _selectedFemaleId = _females[0].id;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedFemaleId != null) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'female_id': _selectedFemaleId,
        'male_id': _selectedMaleId,
        'breeding_date': DateTime.now().toIso8601String().split('T')[0],
        'breeding_method': _breedingMethod,
        'pregnancy_status': 'Unknown',
      };

      try {
        await ApiService.createBreedingRecord(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Breeding record added successfully!')),
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
      appBar: AppBar(title: const Text('Record Breeding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedFemaleId,
                decoration: const InputDecoration(labelText: 'Female Animal'),
                items: _females.map<DropdownMenuItem<int>>((animal) {
                  return DropdownMenuItem<int>(
                    value: animal.id,
                    child: Text(animal.name ?? animal.tagNumber),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedFemaleId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _breedingMethod,
                decoration: const InputDecoration(labelText: 'Method'),
                items: ['Natural', 'AI']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _breedingMethod = value!),
              ),
              if (_breedingMethod == 'Natural')
                DropdownButtonFormField<int>(
                  value: _selectedMaleId,
                  decoration: const InputDecoration(labelText: 'Male Animal (Optional)'),
                  items: _males.map<DropdownMenuItem<int>>((animal) {
                    return DropdownMenuItem<int>(
                      value: animal.id,
                      child: Text(animal.name ?? animal.tagNumber),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedMaleId = value),
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
