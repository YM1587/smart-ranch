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
                            Text('Method: ${record.breedingMethod}', style: const TextStyle(fontSize: 12)),
                            Row(
                              children: [
                                const Text('Status: ', style: TextStyle(fontSize: 12)),
                                Text(
                                  record.pregnancyStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: record.pregnancyStatus == 'Pregnant' ? Colors.purple : 
                                           record.pregnancyStatus == 'Failed' ? Colors.red : 
                                           record.pregnancyStatus == 'Calved' ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (record.expectedCalvingDate != null) Text('Due: ${record.expectedCalvingDate}', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                            if (record.outcome != null) Text('Outcome: ${record.outcome}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 8),
                            if (record.pregnancyStatus == 'Unknown')
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await ApiService.markBreedingPregnant(record.breedingId);
                                      _loadRecords();
                                    },
                                    icon: const Icon(Icons.check_circle, size: 14),
                                    label: const Text('Pregnant', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await ApiService.markBreedingFailed(record.breedingId);
                                      _loadRecords();
                                    },
                                    icon: const Icon(Icons.cancel, size: 14),
                                    label: const Text('Failed', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  ),
                                ],
                              )
                            else if (record.pregnancyStatus == 'Pregnant')
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await ApiService.markBreedingCalved(record.breedingId);
                                  _loadRecords();
                                },
                                icon: const Icon(Icons.child_care, size: 14),
                                label: const Text('Mark Calved', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                            
                            if (record.pregnancyStatus == 'Calved')
                               Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AnimalForm(farmerId: ApiService.farmerId),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle, size: 14),
                                  label: const Text('Register Offspring', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                 ),
                               ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BreedingRecordForm(
                                farmerId: ApiService.farmerId,
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
              builder: (context) => BreedingRecordForm(farmerId: ApiService.farmerId, femaleInitialId: widget.animal.id),
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
