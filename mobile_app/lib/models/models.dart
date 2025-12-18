class Pen {
  final int id;
  final String name;
  final String livestockType;
  final int? capacity;

  Pen({required this.id, required this.name, required this.livestockType, this.capacity});

  factory Pen.fromJson(Map<String, dynamic> json) {
    return Pen(
      id: json['pen_id'],
      name: json['pen_name'],
      livestockType: json['pen_type'],
      capacity: json['capacity'],
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

  Animal({required this.id, required this.tagNumber, this.name, this.penId, this.breed, this.sex, this.status, this.animalType});

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['animal_id'],
      tagNumber: json['tag_number'],
      name: json['name'],
      penId: json['pen_id'],
      breed: json['breed'],
      sex: json['gender'],
      status: json['status'],
      animalType: json['animal_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag_number': tagNumber,
      'name': name,
      'pen_id': penId,
      'breed': breed,
      'sex': sex,
      'status': status,
      'animal_type': animalType,
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
      id: json['record_id'],
      animalId: json['animal_id'],
      eventDate: json['date'],
      eventType: json['condition'],
      diagnosis: json['symptoms'],
      treatment: json['treatment'],
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : 0.0,
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
      id: json['log_id'],
      penId: json['pen_id'],
      logDate: json['date'],
      feedType: json['feed_type'],
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      cost: (json['total_cost'] as num).toDouble(),
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

class Expense {
  final int id;
  final String category;
  final double amount;
  final String expenseDate;
  final String? description;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['transaction_id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      expenseDate: json['date'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'expense_date': expenseDate,
      'description': description,
    };
  }
}
