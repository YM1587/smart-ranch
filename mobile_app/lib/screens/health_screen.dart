import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
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
      // Re-using the getRecentHealthEvents but maybe we want ALL events?
      // For now, let's use the recent one or add a new method for ALL if needed.
      // The backend endpoint /health/ supports pagination, so we can use that.
      // Let's just use getRecentHealthEvents for now as a "Health Log".
      final events = await apiService.getRecentHealthEvents(); 
      setState(() {
        healthEvents = events;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Overview')),
      body: isLoading
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
                        subtitle: Text("Date: ${event.date}\nTreatment: ${event.treatment}"),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Go to Inventory and select an animal to add a record.")));
        },
        label: const Text("To Add Record, Go to Inventory"),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
