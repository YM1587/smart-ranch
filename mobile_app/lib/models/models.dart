class Pen {
  final int id;
  final String name;
  final String livestockType;
  final int? capacity;

  Pen({required this.id, required this.name, required this.livestockType, this.capacity});

  factory Pen.fromJson(Map<String, dynamic> json) {
    return Pen(
      id: int.tryParse(json['pen_id'].toString()) ?? 0,
      name: json['pen_name'],
      livestockType: json['pen_type'],
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'livestock_type': livestockType,
      'capacity': capacity,
    };
  }
}

class Animal {
  final int id;
  final String tagNumber;
  final String? name;
  final int? penId;
  final String? breed;
  final String? sex;
  final String? status;
  final String? animalType;
  final String? birthDate;
  final String? acquisitionType;
  final double? acquisitionCost;

  Animal({
    required this.id,
    required this.tagNumber,
    this.name,
    this.penId,
    this.breed,
    this.sex,
    this.status,
    this.animalType,
    this.birthDate,
    this.acquisitionType,
    this.acquisitionCost,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: int.tryParse(json['animal_id'].toString()) ?? 0,
      tagNumber: json['tag_number'],
      name: json['name'],
      penId: json['pen_id'] != null ? int.tryParse(json['pen_id'].toString()) : null,
      breed: json['breed'],
      sex: json['gender'],
      status: json['status'],
      animalType: json['animal_type'],
      birthDate: json['birth_date'],
      acquisitionType: json['acquisition_type'],
      acquisitionCost: json['acquisition_cost'] != null 
          ? double.tryParse(json['acquisition_cost'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag_number': tagNumber,
      'name': name,
      'pen_id': penId,
      'breed': breed,
      'gender': sex, // Use gender for backend
      'status': status,
      'animal_type': animalType,
      'birth_date': birthDate,
      'acquisition_type': acquisitionType,
      'acquisition_cost': acquisitionCost,
    };
  }
}

class HealthEvent {
  final int id;
  final int animalId;
  final String eventDate;
  final String eventType;
  final String? diagnosis;
  final String? treatment;
  final double? cost;

  HealthEvent({
    required this.id,
    required this.animalId,
    required this.eventDate,
    required this.eventType,
    this.diagnosis,
    this.treatment,
    this.cost,
  });

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      id: int.tryParse(json['record_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      eventDate: json['date'],
      eventType: json['condition'],
      diagnosis: json['symptoms'],
      treatment: json['treatment'],
      cost: json['cost'] != null ? double.tryParse(json['cost'].toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'event_date': eventDate,
      'event_type': eventType,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'cost': cost,
    };
  }
}

class FeedLog {
  final int id;
  final int penId;
  final String logDate;
  final String feedType;
  final double quantityKg;
  final double cost;

  FeedLog({
    required this.id,
    required this.penId,
    required this.logDate,
    required this.feedType,
    required this.quantityKg,
    required this.cost,
  });

  factory FeedLog.fromJson(Map<String, dynamic> json) {
    return FeedLog(
      id: int.tryParse(json['log_id'].toString()) ?? 0,
      penId: int.tryParse(json['pen_id'].toString()) ?? 0,
      logDate: json['date'],
      feedType: json['feed_type'],
      quantityKg: double.tryParse(json['quantity_kg'].toString()) ?? 0.0,
      cost: double.tryParse(json['total_cost'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pen_id': penId,
      'log_date': logDate,
      'feed_type': feedType,
      'quantity_kg': quantityKg,
      'cost': cost,
    };
  }
}

class FinancialTransaction {
  final int id;
  final String type; // 'Income' or 'Expense'
  final String category;
  final double amount;
  final String date;
  final String? description;
  final int? relatedAnimalId;
  final int? relatedPenId;
  final String? notes;

  FinancialTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.relatedAnimalId,
    this.relatedPenId,
    this.notes,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: int.tryParse(json['transaction_id'].toString()) ?? 0,
      type: json['type'],
      category: json['category'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      date: json['date'],
      description: json['description'],
      relatedAnimalId: json['related_animal_id'] != null ? int.tryParse(json['related_animal_id'].toString()) : null,
      relatedPenId: json['related_pen_id'] != null ? int.tryParse(json['related_pen_id'].toString()) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'date': date,
      'description': description,
      'related_animal_id': relatedAnimalId,
      'related_pen_id': relatedPenId,
      'notes': notes,
    };
  }
}
class BreedingRecord {
  final int id;
  final int femaleId;
  final int? maleId;
  final String breedingDate;
  final String? breedingMethod;
  final String? pregnancyStatus;
  final String? expectedCalvingDate;
  final String? actualCalvingDate;
  final String? outcome;
  final int? offspringId;
  final String? notes;

  BreedingRecord({
    required this.id,
    required this.femaleId,
    this.maleId,
    required this.breedingDate,
    this.breedingMethod,
    this.pregnancyStatus,
    this.expectedCalvingDate,
    this.actualCalvingDate,
    this.outcome,
    this.offspringId,
    this.notes,
  });

  factory BreedingRecord.fromJson(Map<String, dynamic> json) {
    return BreedingRecord(
      id: int.tryParse(json['breeding_id'].toString()) ?? 0,
      femaleId: int.tryParse(json['female_id'].toString()) ?? 0,
      maleId: json['male_id'] != null ? int.tryParse(json['male_id'].toString()) : null,
      breedingDate: json['breeding_date'],
      breedingMethod: json['breeding_method'],
      pregnancyStatus: json['pregnancy_status'],
      expectedCalvingDate: json['expected_calving_date'],
      actualCalvingDate: json['actual_calving_date'],
      outcome: json['outcome'],
      offspringId: json['offspring_id'] != null ? int.tryParse(json['offspring_id'].toString()) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'female_id': femaleId,
      'male_id': maleId,
      'breeding_date': breedingDate,
      'breeding_method': breedingMethod,
      'pregnancy_status': pregnancyStatus,
      'expected_calving_date': expectedCalvingDate,
      'actual_calving_date': actualCalvingDate,
      'outcome': outcome,
      'offspring_id': offspringId,
      'notes': notes,
    };
  }
}

class LaborActivity {
  final int id;
  final int farmerId;
  final String activityType;
  final String? description;
  final double hoursSpent;
  final double laborCost;
  final String date;
  final int? relatedAnimalId;
  final int? relatedPenId;

  LaborActivity({
    required this.id,
    required this.farmerId,
    required this.activityType,
    this.description,
    required this.hoursSpent,
    required this.laborCost,
    required this.date,
    this.relatedAnimalId,
    this.relatedPenId,
  });

  factory LaborActivity.fromJson(Map<String, dynamic> json) {
    return LaborActivity(
      id: int.tryParse(json['activity_id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      activityType: json['activity_type'],
      description: json['description'],
      hoursSpent: double.tryParse(json['hours_spent'].toString()) ?? 0.0,
      laborCost: double.tryParse(json['labor_cost'].toString()) ?? 0.0,
      date: json['date'],
      relatedAnimalId: json['related_animal_id'] != null ? int.tryParse(json['related_animal_id'].toString()) : null,
      relatedPenId: json['related_pen_id'] != null ? int.tryParse(json['related_pen_id'].toString()) : null,
    );
  }
}

class MilkProduction {
  final int id;
  final int animalId;
  final String date;
  final double? morningYield;
  final double? eveningYield;
  final double totalYield;

  MilkProduction({
    required this.id,
    required this.animalId,
    required this.date,
    this.morningYield,
    this.eveningYield,
    required this.totalYield,
  });

  factory MilkProduction.fromJson(Map<String, dynamic> json) {
    return MilkProduction(
      id: int.tryParse(json['production_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      date: json['date'],
      morningYield: json['morning_yield'] != null ? double.tryParse(json['morning_yield'].toString()) : null,
      eveningYield: json['evening_yield'] != null ? double.tryParse(json['evening_yield'].toString()) : null,
      totalYield: double.tryParse(json['total_yield'].toString()) ?? 0.0,
    );
  }
}

class WeightRecord {
  final int id;
  final int animalId;
  final String date;
  final double weightKg;
  final int? bodyConditionScore;

  WeightRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.weightKg,
    this.bodyConditionScore,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: int.tryParse(json['weight_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      date: json['date'],
      weightKg: double.tryParse(json['weight_kg'].toString()) ?? 0.0,
      bodyConditionScore: json['body_condition_score'] != null ? int.tryParse(json['body_condition_score'].toString()) : null,
    );
  }
}

class IndividualFeedLog {
  final int id;
  final int animalId;
  final String feedType;
  final double quantityKg;
  final double cost;
  final String date;

  IndividualFeedLog({
    required this.id,
    required this.animalId,
    required this.feedType,
    required this.quantityKg,
    required this.cost,
    required this.date,
  });

  factory IndividualFeedLog.fromJson(Map<String, dynamic> json) {
    return IndividualFeedLog(
      id: int.tryParse(json['individual_feed_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      feedType: json['feed_type'],
      quantityKg: double.tryParse(json['quantity_kg'].toString()) ?? 0.0,
      cost: double.tryParse(json['total_cost'].toString()) ?? 0.0,
      date: json['date'],
    );
  }
}
