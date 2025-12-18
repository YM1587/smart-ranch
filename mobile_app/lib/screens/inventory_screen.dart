import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'animal_health_screen.dart';
import 'forms/animal_form.dart';

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
      final data = await ApiService.getAnimals(1); // Pass farmer ID
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnimalForm(farmerId: 1)),
    ).then((_) => _loadAnimals()); // Refresh after adding
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
              leading: const CircleAvatar(child: Icon(Icons.pets)),
              title: Text(animal.name != null && animal.name!.isNotEmpty ? animal.name! : animal.tagNumber),
              subtitle: Text('${animal.breed} - ${animal.status} ${animal.name != null && animal.name!.isNotEmpty ? "(${animal.tagNumber})" : ""}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
