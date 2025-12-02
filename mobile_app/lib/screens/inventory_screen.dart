import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'animal_health_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Animal> animals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final data = await ApiService.getAnimals();
      setState(() {
        animals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddAnimalDialog() {
    final tagController = TextEditingController();
    final breedController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tagController, decoration: const InputDecoration(labelText: 'Tag Number')),
            TextField(controller: breedController, decoration: const InputDecoration(labelText: 'Breed')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final newAnimalMap = {
                  'tag_number': tagController.text,
                  'breed': breedController.text,
                  'status': 'Active',
                  'farmer_id': 1, // Default farmer ID for testing
                  'animal_type': 'Dairy', // Default
                  'gender': 'Female', // Default
                  'acquisition_type': 'Born-on-farm', // Default
                  'acquisition_cost': 0.0,
                };
                await ApiService.createAnimal(newAnimalMap);
                Navigator.pop(context);
                _loadAnimals();
              } catch (e) {
                print(e);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock Inventory'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddAnimalDialog),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(animal.tagNumber.substring(0, 1))),
                  title: Text('Tag: ${animal.tagNumber}'),
                  subtitle: Text('${animal.breed ?? "Unknown"} - ${animal.status}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalHealthScreen(animal: animal),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
