import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'animal_health_screen.dart';
import 'breeding_history_screen.dart';
import 'forms/animal_form.dart';
import 'operations_dashboard_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Animal> _allAnimals = [];
  List<Pen> _pens = [];
  Map<int, List<Animal>> _groupedAnimals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pens = await ApiService.getPens(1); // Pass farmer ID
      final animals = await ApiService.getAnimals(1);
      
      setState(() {
        _pens = pens;
        _allAnimals = animals;
        
        // Group animals by penId
        _groupedAnimals = {};
        for (var animal in animals) {
          final penId = animal.penId ?? -1; // -1 for "Unassigned"
          if (!_groupedAnimals.containsKey(penId)) {
            _groupedAnimals[penId] = [];
          }
          _groupedAnimals[penId]!.add(animal);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddAnimalDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnimalForm(farmerId: 1)),
    ).then((_) => _loadData()); // Refresh after adding
  }

  @override
  Widget build(BuildContext context) {
    // Filter pens that have animals, or show all pens?
    // User wants organization, so showing pens that have animals is most logical for "Inventory".
    // But showing ALL pens gives a clearer picture of the ranch structure.
    // Let's show pens that have animals + an "Unassigned" pen if needed.
    
    final pensToShow = _pens.where((p) => _groupedAnimals.containsKey(p.id)).toList();
    final unassignedAnimals = _groupedAnimals[-1] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock Inventory'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddAnimalDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pensToShow.length + (unassignedAnimals.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < pensToShow.length) {
                  final pen = pensToShow[index];
                  final penAnimals = _groupedAnimals[pen.id] ?? [];
                  return _buildPenSection(pen.name, penAnimals);
                } else {
                  return _buildPenSection("Unassigned / Other", unassignedAnimals);
                }
              },
            ),
    );
  }

  Widget _buildPenSection(String penName, List<Animal> penAnimals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey.shade200,
          width: double.infinity,
          child: Text(
            penName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
          ),
        ),
        ...penAnimals.map((animal) => _buildAnimalTile(animal)).toList(),
      ],
    );
  }

  Widget _buildAnimalTile(Animal animal) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.pets)),
      title: Text(animal.name != null && animal.name!.isNotEmpty ? animal.name! : animal.tagNumber),
      subtitle: Text('${animal.breed} - ${animal.status} ${animal.name != null && animal.name!.isNotEmpty ? "(${animal.tagNumber})" : ""}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animal.sex == 'Female')
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.pink),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreedingHistoryScreen(animal: animal),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OperationsDashboardScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalForm(farmerId: 1, animal: animal),
                ),
              );
              _loadData();
            },
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OperationsDashboardScreen(),
          ),
        );
      },
    );
  }
}
