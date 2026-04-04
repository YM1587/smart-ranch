import 'dart:convert';

class Pen {
  final int id;
  final int farmerId;
  final String name;
  final String livestockType;
  final int? capacity;

  Pen({required this.id, required this.farmerId, required this.name, required this.livestockType, this.capacity});

  factory Pen.fromJson(Map<String, dynamic> json) {
    return Pen(
      id: int.tryParse(json['pen_id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      name: json['pen_name'] ?? '',
      livestockType: json['pen_type'] ?? '',
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'pen_name': name,
      'pen_type': livestockType,
      'capacity': capacity,
    };
  }
}

class Animal {
  final int id;
  final int farmerId;
  final String tagNumber;
  final String? name;
  final int? penId;
  final String? breed;
  final String? sex;
  final String status;
  final String? animalType;
  final String? birthDate;
  final String acquisitionType;
  final double acquisitionCost;
  final String? disposalReason;
  final String? notes;

  Animal({
    required this.id,
    required this.farmerId,
    required this.tagNumber,
    this.name,
    this.penId,
    this.breed,
    this.sex,
    this.status = 'Active',
    this.animalType,
    this.birthDate,
    required this.acquisitionType,
    this.acquisitionCost = 0.0,
    this.disposalReason,
    this.notes,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: int.tryParse(json['animal_id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      tagNumber: json['tag_number'] ?? '',
      name: json['name'],
      penId: json['pen_id'] != null ? int.tryParse(json['pen_id'].toString()) : null,
      breed: json['breed'],
      sex: json['gender'],
      status: json['status'] ?? 'Active',
      animalType: json['animal_type'],
      birthDate: json['birth_date'],
      acquisitionType: json['acquisition_type'] ?? '',
      acquisitionCost: double.tryParse(json['acquisition_cost'].toString()) ?? 0.0,
      disposalReason: json['disposal_reason'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'tag_number': tagNumber,
      'name': name,
      'pen_id': penId,
      'breed': breed,
      'gender': sex,
      'status': status,
      'animal_type': animalType,
      'birth_date': birthDate,
      'acquisition_type': acquisitionType,
      'acquisition_cost': acquisitionCost,
      'disposal_reason': disposalReason,
      'notes': notes,
    };
  }
}

class HealthEvent {
  final int id;
  final int animalId;
  final String date;
  final String condition;
  final String symptoms;
  final String treatment;
  final String? outcome;
  final double cost;
  final String? vetName;
  final String? nextCheckupDate;
  final String? notes;

  HealthEvent({
    required this.id,
    required this.animalId,
    required this.date,
    required this.condition,
    required this.symptoms,
    required this.treatment,
    this.outcome,
    this.cost = 0.0,
    this.vetName,
    this.nextCheckupDate,
    this.notes,
  });

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      id: int.tryParse(json['record_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      condition: json['condition'] ?? '',
      symptoms: json['symptoms'] ?? '',
      treatment: json['treatment'] ?? '',
      outcome: json['outcome'],
      cost: double.tryParse(json['cost'].toString()) ?? 0.0,
      vetName: json['vet_name'],
      nextCheckupDate: json['next_checkup_date'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'date': date,
      'condition': condition,
      'symptoms': symptoms,
      'treatment': treatment,
      'outcome': outcome,
      'cost': cost,
      'vet_name': vetName,
      'next_checkup_date': nextCheckupDate,
      'notes': notes,
    };
  }
}

class FeedLog {
  final int id;
  final int penId;
  final String date;
  final String feedType;
  final double quantityKg;
  final double cost;

  FeedLog({
    required this.id,
    required this.penId,
    required this.date,
    required this.feedType,
    required this.quantityKg,
    required this.cost,
  });

  factory FeedLog.fromJson(Map<String, dynamic> json) {
    return FeedLog(
      id: int.tryParse(json['log_id'].toString()) ?? 0,
      penId: int.tryParse(json['pen_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      feedType: json['feed_type'] ?? '',
      quantityKg: double.tryParse(json['quantity_kg'].toString()) ?? 0.0,
      cost: double.tryParse(json['cost_per_kg'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pen_id': penId,
      'date': date,
      'feed_type': feedType,
      'quantity_kg': quantityKg,
      'cost_per_kg': cost,
    };
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
      feedType: json['feed_type'] ?? '',
      quantityKg: double.tryParse(json['quantity_kg'].toString()) ?? 0.0,
      cost: double.tryParse(json['cost_per_kg'].toString()) ?? 0.0,
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'feed_type': feedType,
      'quantity_kg': quantityKg,
      'cost_per_kg': cost,
      'date': date,
    };
  }
}

class MilkProduction {
  final int id;
  final int animalId;
  final String date;
  final double morningYield;
  final double eveningYield;
  final double totalYield;

  MilkProduction({
    required this.id,
    required this.animalId,
    required this.date,
    required this.morningYield,
    required this.eveningYield,
    required this.totalYield,
  });

  factory MilkProduction.fromJson(Map<String, dynamic> json) {
    return MilkProduction(
      id: int.tryParse(json['production_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      morningYield: double.tryParse(json['morning_yield'].toString()) ?? 0.0,
      eveningYield: double.tryParse(json['evening_yield'].toString()) ?? 0.0,
      totalYield: double.tryParse(json['total_yield'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'date': date,
      'morning_yield': morningYield,
      'evening_yield': eveningYield,
    };
  }
}

class WeightRecord {
  final int id;
  final int animalId;
  final String date;
  final double weightKg;
  final int? bodyConditionScore;
  final String? notes;

  WeightRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.weightKg,
    this.bodyConditionScore,
    this.notes,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: int.tryParse(json['weight_id'].toString()) ?? 0,
      animalId: int.tryParse(json['animal_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      weightKg: double.tryParse(json['weight_kg'].toString()) ?? 0.0,
      bodyConditionScore: json['body_condition_score'] != null ? int.tryParse(json['body_condition_score'].toString()) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'date': date,
      'weight_kg': weightKg,
      'body_condition_score': bodyConditionScore,
      'notes': notes,
    };
  }
}

class FinancialTransaction {
  final int id;
  final int farmerId;
  final String type;
  final String category;
  final double amount;
  final String date;
  final String description;
  final int? relatedAnimalId;
  final int? relatedPenId;

  FinancialTransaction({
    required this.id,
    required this.farmerId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.relatedAnimalId,
    this.relatedPenId,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: int.tryParse(json['transaction_id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      relatedAnimalId: json['related_animal_id'],
      relatedPenId: json['related_pen_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'type': type,
      'category': category,
      'amount': amount,
      'date': date,
      'description': description,
      'related_animal_id': relatedAnimalId,
      'related_pen_id': relatedPenId,
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
  final double cost;
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
    this.cost = 0.0,
    this.notes,
  });

  factory BreedingRecord.fromJson(Map<String, dynamic> json) {
    return BreedingRecord(
      id: int.tryParse(json['breeding_id'].toString()) ?? 0,
      femaleId: int.tryParse(json['female_id'].toString()) ?? 0,
      maleId: json['male_id'] != null ? int.tryParse(json['male_id'].toString()) : null,
      breedingDate: json['breeding_date'] ?? '',
      breedingMethod: json['breeding_method'],
      pregnancyStatus: json['pregnancy_status'],
      expectedCalvingDate: json['expected_calving_date'],
      actualCalvingDate: json['actual_calving_date'],
      outcome: json['outcome'],
      offspringId: json['offspring_id'] != null ? int.tryParse(json['offspring_id'].toString()) : null,
      cost: double.tryParse(json['cost'].toString()) ?? 0.0,
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
      'cost': cost,
      'notes': notes,
    };
  }
}

class LaborActivity {
  final int id;
  final int farmerId;
  final String activityType;
  final double hoursSpent;
  final double laborCost;
  final String date;
  final String? description;

  LaborActivity({
    required this.id,
    required this.farmerId,
    required this.activityType,
    required this.hoursSpent,
    required this.laborCost,
    required this.date,
    this.description,
  });

  factory LaborActivity.fromJson(Map<String, dynamic> json) {
    return LaborActivity(
      id: int.tryParse(json['activity_id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      activityType: json['activity_type'] ?? '',
      hoursSpent: double.tryParse(json['hours_spent'].toString()) ?? 0.0,
      laborCost: double.tryParse(json['labor_cost'].toString()) ?? 0.0,
      date: json['date'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmer_id': farmerId,
      'activity_type': activityType,
      'hours_spent': hoursSpent,
      'labor_cost': laborCost,
      'date': date,
      'description': description,
    };
  }
}

class Alert {
  final int id;
  final int farmerId;
  final String type;
  final String title;
  final String message;
  final String severity;
  final int? relatedAnimalId;
  final bool isDismissed;

  Alert({
    required this.id,
    required this.farmerId,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.relatedAnimalId,
    this.isDismissed = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: int.tryParse(json['id'].toString()) ?? 0,
      farmerId: int.tryParse(json['farmer_id'].toString()) ?? 0,
      type: json['type'] ?? 'INFO',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'Info',
      relatedAnimalId: json['related_animal_id'],
      isDismissed: (json['is_dismissed'] == 1 || json['is_dismissed'] == true),
    );
  }
}
