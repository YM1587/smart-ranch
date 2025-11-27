import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService apiService = ApiService();
  List<Animal> animals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    try {
      final data = await apiService.getAnimals();
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
                final newAnimal = Animal(
                  id: 0, // ID assigned by backend
                  tagNumber: tagController.text,
                  breed: breedController.text,
                  status: 'Active',
                );
                await apiService.createAnimal(newAnimal);
                Navigator.pop(context);
                _loadAnimals();
              } catch (e) {
                print(e);
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
import 'animal_health_screen.dart';

// ... (inside _InventoryScreenState)

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
