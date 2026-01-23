import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class BreedingRecordForm extends StatefulWidget {
  final int farmerId;
  final BreedingRecord? existingRecord;
  const BreedingRecordForm({Key? key, required this.farmerId, this.existingRecord}) : super(key: key);

  @override
  _BreedingRecordFormState createState() => _BreedingRecordFormState();
}

class _BreedingRecordFormState extends State<BreedingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedFemaleId;
  int? _selectedMaleId;
  String _breedingMethod = 'AI';
  String _pregnancyStatus = 'Unknown';
  DateTime _breedingDate = DateTime.now();
  DateTime? _expectedCalvingDate;
  DateTime? _actualCalvingDate;
  String? _outcome;
  int? _selectedOffspringId;
  final TextEditingController _notesController = TextEditingController();

  List<Animal> _females = [];
  List<Animal> _males = [];
  List<Animal> _allAnimals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _selectedFemaleId = widget.existingRecord!.femaleId;
      _selectedMaleId = widget.existingRecord!.maleId;
      _breedingMethod = widget.existingRecord!.breedingMethod ?? 'AI';
      _pregnancyStatus = widget.existingRecord!.pregnancyStatus ?? 'Unknown';
      _breedingDate = DateTime.parse(widget.existingRecord!.breedingDate);
      if (widget.existingRecord!.expectedCalvingDate != null) {
        _expectedCalvingDate = DateTime.parse(widget.existingRecord!.expectedCalvingDate!);
      }
      if (widget.existingRecord!.actualCalvingDate != null) {
        _actualCalvingDate = DateTime.parse(widget.existingRecord!.actualCalvingDate!);
      }
      _outcome = widget.existingRecord!.outcome;
      _selectedOffspringId = widget.existingRecord!.offspringId;
      _notesController.text = widget.existingRecord!.notes ?? '';
    }
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final results = await Future.wait([
        ApiService.getAnimals(widget.farmerId),
        ApiService.getPens(widget.farmerId),
      ]);
      
      final animals = results[0] as List<Animal>;
      final pens = results[1] as List<Pen>;

      setState(() {
        _allAnimals = animals;
        
        // Filter females: Must be Female AND in a "Dry Cow" or "Milking" pen
        final femalePenIds = pens
            .where((p) => p.name.toLowerCase().contains('dry cow') || p.name.toLowerCase().contains('milking'))
            .map((p) => p.id)
            .toSet();
        _females = animals.where((a) => a.sex == 'Female' && femalePenIds.contains(a.penId)).toList();
        
        // Filter males: Must be Male AND in a "Bull" pen
        final bullPenIds = pens
            .where((p) => p.name.toLowerCase().contains('bull'))
            .map((p) => p.id)
            .toSet();
        _males = animals.where((a) => a.sex == 'Male' && bullPenIds.contains(a.penId)).toList();

        _females.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
        _males.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
        
        if (widget.existingRecord == null) {
          if (_females.isNotEmpty) _selectedFemaleId = _females[0].id;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        onSelected(picked);
      });
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
        'breeding_date': _breedingDate.toIso8601String().split('T')[0],
        'breeding_method': _breedingMethod,
        'pregnancy_status': _pregnancyStatus,
        'expected_calving_date': _expectedCalvingDate?.toIso8601String().split('T')[0],
        'actual_calving_date': _actualCalvingDate?.toIso8601String().split('T')[0],
        'outcome': _outcome,
        'offspring_id': _selectedOffspringId,
        'notes': _notesController.text,
      };

      try {
        if (widget.existingRecord != null) {
          await ApiService.updateBreedingRecord(widget.existingRecord!.id, data);
        } else {
          await ApiService.createBreedingRecord(data);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingRecord != null ? 'Record updated!' : 'Breeding record added!')),
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
      appBar: AppBar(title: Text(widget.existingRecord != null ? 'Edit Breeding' : 'Record Breeding')),
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
                    child: Text("${animal.name ?? ""} (${animal.tagNumber})"),
                  );
                }).toList(),
                onChanged: widget.existingRecord != null ? null : (value) => setState(() => _selectedFemaleId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Breeding Date"),
                subtitle: Text(_breedingDate.toIso8601String().split('T')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, _breedingDate, (date) => _breedingDate = date),
              ),
              const SizedBox(height: 10),
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
                      child: Text("${animal.name ?? ""} (${animal.tagNumber})"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedMaleId = value),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const Text("Follow-up Information", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _pregnancyStatus,
                decoration: const InputDecoration(labelText: 'Pregnancy Status'),
                items: ['Unknown', 'Pregnant', 'Not Pregnant']
                    .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _pregnancyStatus = value!;
                  if (_pregnancyStatus == 'Pregnant' && _expectedCalvingDate == null) {
                    // Set default expected date (approx 283 days for cows)
                    _expectedCalvingDate = _breedingDate.add(const Duration(days: 283));
                  }
                }),
              ),
              if (_pregnancyStatus == 'Pregnant')
                ListTile(
                  title: const Text("Expected Calving Date"),
                  subtitle: Text(_expectedCalvingDate?.toIso8601String().split('T')[0] ?? "Not set"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, _expectedCalvingDate ?? DateTime.now(), (date) => _expectedCalvingDate = date),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: [null, 'Live Calf', 'Abortion', 'Stillborn']
                    .map((o) => DropdownMenuItem(value: o, child: Text(o ?? "No outcome yet")))
                    .toList(),
                onChanged: (value) => setState(() {
                  _outcome = value;
                  if (_outcome != null && _actualCalvingDate == null) {
                    _actualCalvingDate = DateTime.now();
                  }
                }),
              ),
              if (_outcome != null) ...[
                ListTile(
                  title: const Text("Actual Calving Date"),
                  subtitle: Text(_actualCalvingDate?.toIso8601String().split('T')[0] ?? "Not set"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, _actualCalvingDate ?? DateTime.now(), (date) => _actualCalvingDate = date),
                ),
                if (_outcome == 'Live Calf')
                  DropdownButtonFormField<int?>(
                    value: _selectedOffspringId,
                    decoration: const InputDecoration(labelText: 'Link Offspring Animal'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text("Not linked yet")),
                      ..._allAnimals.map((animal) {
                        return DropdownMenuItem<int>(
                          value: animal.id,
                          child: Text("${animal.name ?? ""} (${animal.tagNumber})"),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() => _selectedOffspringId = value),
                  ),
              ],
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Record'),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
