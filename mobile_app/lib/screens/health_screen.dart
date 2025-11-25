import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // For simplicity, this screen just lists animals to select for health records
  // In a real app, you'd select an animal first.
  // Here we will just show a placeholder or a list of recent events if we had an endpoint for all events.
  // Let's just show a message for now as the requirement is to log events for specific animals.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Monitoring')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.medical_services, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Select an animal from Inventory to view/add Health Records', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
