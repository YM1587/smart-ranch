import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'breeding_history_screen.dart';
import 'forms/animal_disposal_form.dart';

class AnimalHealthScreen extends StatefulWidget {
  final Animal animal;

  const AnimalHealthScreen({super.key, required this.animal});

  @override
  State<AnimalHealthScreen> createState() => _AnimalHealthScreenState();
}

class _AnimalHealthScreenState extends State<AnimalHealthScreen> {
  List<HealthEvent> healthEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthEvents();
  }

  Future<void> _loadHealthEvents() async {
    try {
      final events = await ApiService.getHealthEvents(widget.animal.id);
      setState(() {
        healthEvents = events;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error loading health events: $e");
    }
  }

  void _showAddHealthEventDialog() {
    final diagnosisController = TextEditingController();
    final treatmentController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Health Record for ${widget.animal.tagNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
              TextField(controller: diagnosisController, decoration: const InputDecoration(labelText: 'Diagnosis / Symptom')),
              TextField(controller: treatmentController, decoration: const InputDecoration(labelText: 'Treatment')),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final newEvent = HealthEvent(
                  id: 0,
                  animalId: widget.animal.id,
                  date: dateController.text,
                  condition: diagnosisController.text,
                  symptoms: '', // Can be empty or add field
                  treatment: treatmentController.text,
                  notes: notesController.text,
                );
                await ApiService.createHealthEvent(newEvent);
                Navigator.pop(context);
                _loadHealthEvents();
              } catch (e) {
                print(e);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add record')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health: ${widget.animal.tagNumber}'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddHealthEventDialog),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Breed: ${widget.animal.breed ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                        Text("Status: ${widget.animal.status}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (widget.animal.sex == 'Female')
                      InkWell(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => BreedingHistoryScreen(animal: widget.animal)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                              SizedBox(width: 4),
                              Text("Reproduction", style: TextStyle(color: Colors.purple, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : healthEvents.isEmpty
                    ? const Center(child: Text("No health records found."))
                    : ListView.builder(
                        itemCount: healthEvents.length,
                        itemBuilder: (context, index) {
                          final event = healthEvents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.medical_services, color: Colors.red),
                              title: Text(event.condition),
                              subtitle: Text("${event.date}\nTreatment: ${event.treatment}"),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
          if (widget.animal.status != 'Disposed')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnimalDisposalForm(animal: widget.animal, farmerId: ApiService.farmerId)),
                    ).then((_) {
                       if (context.mounted) Navigator.pop(context);
                    });
                  },
                  icon: const Icon(Icons.archive, color: Colors.red),
                  label: const Text('Dispose (Died/Sold/Other)', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
