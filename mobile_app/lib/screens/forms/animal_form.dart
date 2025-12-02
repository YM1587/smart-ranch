import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AnimalForm extends StatefulWidget {
  final int farmerId;
  const AnimalForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _AnimalFormState createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _breedController = TextEditingController();
  final _costController = TextEditingController();
  String _animalType = 'Dairy';
  String _gender = 'Female';
  String _acquisitionType = 'Born-on-farm';
  int? _selectedPenId;
  List<dynamic> _pens = [];

  bool _isLoading = false;

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
          _selectedPenId = _pens[0]['pen_id'];
        }
      });
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedPenId != null) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'farmer_id': widget.farmerId,
        'pen_id': _selectedPenId,
        'tag_number': _tagController.text,
        'animal_type': _animalType,
        'breed': _breedController.text,
        'gender': _gender,
        'acquisition_type': _acquisitionType,
        'acquisition_cost': double.tryParse(_costController.text) ?? 0.0,
        // Add date pickers later
      };

      try {
        await ApiService.createAnimal(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal added successfully!')),
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
      appBar: AppBar(title: const Text('Add Animal')),
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
                    value: pen['pen_id'],
                    child: Text(pen['pen_name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPenId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag Number'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _animalType,
                decoration: const InputDecoration(labelText: 'Animal Type'),
                items: ['Dairy', 'Beef']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _animalType = value!),
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
              DropdownButtonFormField<String>(
                value: _acquisitionType,
                decoration: const InputDecoration(labelText: 'Acquisition Type'),
                items: ['Purchased', 'Born-on-farm']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _acquisitionType = value!),
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Acquisition Cost'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Add Animal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
