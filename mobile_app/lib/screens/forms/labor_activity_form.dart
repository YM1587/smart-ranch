import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LaborActivityForm extends StatefulWidget {
  final int farmerId;
  const LaborActivityForm({Key? key, required this.farmerId}) : super(key: key);

  @override
  _LaborActivityFormState createState() => _LaborActivityFormState();
}

class _LaborActivityFormState extends State<LaborActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _activityType = 'Milking';
  bool _isLoading = false;

  final List<String> _activityTypes = [
    'Milking', 'Feeding', 'Cleaning', 'Health Check', 'Treatment',
    'Breeding', 'Moving Animals', 'Maintenance', 'Other'
  ];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final data = {
        'farmer_id': widget.farmerId,
        'activity_type': _activityType,
        'description': _descriptionController.text,
        'hours_spent': double.tryParse(_hoursController.text) ?? 0.0,
        'labor_cost': double.tryParse(_costController.text) ?? 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
      };

      try {
        await ApiService.createLaborActivity(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Labor activity added successfully!')),
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
      appBar: AppBar(title: const Text('Record Labor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _activityType,
                decoration: const InputDecoration(labelText: 'Activity Type'),
                items: _activityTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _activityType = value!),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(labelText: 'Hours Spent'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Labor Cost'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
