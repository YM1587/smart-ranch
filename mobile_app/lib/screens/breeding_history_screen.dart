import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'forms/breeding_record_form.dart';

class BreedingHistoryScreen extends StatefulWidget {
  final Animal animal;
  const BreedingHistoryScreen({Key? key, required this.animal}) : super(key: key);

  @override
  _BreedingHistoryScreenState createState() => _BreedingHistoryScreenState();
}

class _BreedingHistoryScreenState extends State<BreedingHistoryScreen> {
  List<BreedingRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await ApiService.getBreedingRecords(widget.animal.id);
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Breeding History: ${widget.animal.name ?? widget.animal.tagNumber}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No breeding records found.'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Date: ${record.breedingDate}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Method: ${record.breedingMethod}'),
                            Text('Status: ${record.pregnancyStatus}'),
                            if (record.outcome != null) Text('Outcome: ${record.outcome}'),
                          ],
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BreedingRecordForm(
                                farmerId: 1, // Defaulting for demo
                                existingRecord: record,
                              ),
                            ),
                          );
                          _loadRecords();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.animal.sex == 'Female' ? FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedingRecordForm(farmerId: 1),
            ),
          );
          _loadRecords();
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Breeding Record',
      ) : null,
    );
  }
}
