import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class AnimalForm extends StatefulWidget {
  final int farmerId;
  final Animal? animal;
  const AnimalForm({Key? key, required this.farmerId, this.animal}) : super(key: key);

  @override
  _AnimalFormState createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  // final _breedController = TextEditingController(); // Removed
  final _costController = TextEditingController();
  String _animalType = 'Dairy';
  String _gender = 'Female';
  String _acquisitionType = 'Born-on-farm';
  String _selectedBreed = 'Sahiwal';
  final List<String> _breeds = [
    'Sahiwal', 'Holstein', 'Jersey', 'Guernsey', 'Ayrshire', 'Friesian', // Dairy
    'Angus', 'Hereford', 'Charolais', 'Simmental', 'Brahman', // Beef
    'Other'
  ];
  int? _selectedPenId;
  List<Pen> _pens = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.animal != null) {
      _tagController.text = widget.animal!.tagNumber;
      _nameController.text = widget.animal!.name ?? '';
      _animalType = widget.animal!.animalType ?? 'Dairy';
      _selectedBreed = widget.animal!.breed ?? 'Sahiwal';
      _gender = widget.animal!.sex ?? 'Female';
      _selectedPenId = widget.animal!.penId;
      _acquisitionType = widget.animal!.acquisitionType ?? 'Born-on-farm';
      _costController.text = widget.animal!.acquisitionCost?.toString() ?? '';
    }
    _loadPens();
  }

  Future<void> _loadPens() async {
    try {
      final pens = await ApiService.getPens(widget.farmerId);
      setState(() {
        _pens = pens;
        // If we are in edit mode, ensure the existing pen is in the list
        bool exists = _pens.any((p) => p.id == _selectedPenId);
        if (!exists && _pens.isNotEmpty) {
           // If the animal's pen isn't in the list (rare), default to first available
           if (_selectedPenId == null) {
             _selectedPenId = _pens[0].id;
           }
        }
      });
    } catch (e) {
      print("Error loading pens: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Find selected pen safely
      dynamic selectedPen;
      try {
        selectedPen = _pens.firstWhere((p) => p.id == _selectedPenId);
      } catch (e) {
        selectedPen = null;
      }

      if (selectedPen != null && selectedPen.name.toLowerCase() == 'milking parlor' && _gender == 'Male') {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only female animals can be assigned to the Milking Parlor!')),
        );
        return;
      }

      final data = {
        'farmer_id': widget.farmerId,
        'pen_id': _selectedPenId,
        'tag_number': _tagController.text,
        'name': _nameController.text,
        'animal_type': _animalType,
        'breed': _selectedBreed,
        'gender': _gender,
        'acquisition_type': _acquisitionType,
        'acquisition_cost': double.tryParse(_costController.text) ?? 0.0,
      };

      try {
        if (widget.animal != null) {
          await ApiService.updateAnimal(widget.animal!.id, data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Animal updated successfully!')),
          );
        } else {
          await ApiService.createAnimal(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Animal added successfully!')),
          );
        }
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

  Future<void> _showAddPenDialog() async {
    final _penNameController = TextEditingController();
    String _penType = 'Barn'; // Default
    final _formKeyPen = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Pen'),
          content: Form(
            key: _formKeyPen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _penNameController,
                  decoration: const InputDecoration(labelText: 'Pen Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _penType,
                  decoration: const InputDecoration(labelText: 'Pen Type'),
                  items: ['Barn', 'Pasture', 'Coop', 'Stall']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => _penType = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKeyPen.currentState!.validate()) {
                  final data = {
                    'farmer_id': widget.farmerId,
                    'pen_name': _penNameController.text,
                    'pen_type': _penType,
                    'capacity': 100, // Default or add field
                    'description': 'Created from Animal Form',
                  };
                  try {
                    await ApiService.createPen(data);
                    Navigator.pop(context);
                    _loadPens(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pen created!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.animal != null ? 'Edit Animal' : 'Add Animal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
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
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddPenDialog,
                    ),
                  ],
                ),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag Number'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Animal Name'),
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
              DropdownButtonFormField<String>(
                value: _selectedBreed,
                decoration: const InputDecoration(labelText: 'Breed'),
                items: _breeds
                    .map((breed) => DropdownMenuItem(value: breed, child: Text(breed)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBreed = value!),
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
                child: _isLoading ? const CircularProgressIndicator() : Text(widget.animal != null ? 'Update Animal' : 'Add Animal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
