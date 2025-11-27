import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AnimalHealthScreen extends StatefulWidget {
  final Animal animal;

  const AnimalHealthScreen({super.key, required this.animal});

  @override
  State<AnimalHealthScreen> createState() => _AnimalHealthScreenState();
}

class _AnimalHealthScreenState extends State<AnimalHealthScreen> {
  final ApiService apiService = ApiService();
  List<HealthEvent> healthEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthEvents();
  }

  Future<void> _loadHealthEvents() async {
    try {
      final events = await apiService.getHealthEvents(widget.animal.id);
      setState(() {
        healthEvents = events;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      // It's possible there are no events yet, or an error occurred.
      // For now, we'll just show the empty list.
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
                  diagnosis: diagnosisController.text,
                  treatment: treatmentController.text,
                  notes: notesController.text,
                );
                await apiService.createHealthEvent(newEvent);
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
                Text("Breed: ${widget.animal.breed ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                Text("Status: ${widget.animal.status}", style: const TextStyle(fontSize: 16)),
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
                              title: Text(event.diagnosis),
                              subtitle: Text("${event.date}\nTreatment: ${event.treatment}"),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
