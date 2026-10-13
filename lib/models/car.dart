import 'json_utils.dart';

enum CarCategory {
  citadine('Citadine'),
  compacte('Compacte'),
  berline('Berline'),
  suv('SUV'),
  utilitaire('Utilitaire'),
  luxe('Luxe');

  const CarCategory(this.label);
  final String label;
}

enum Transmission {
  manual('Manuelle'),
  automatic('Automatique');

  const Transmission(this.label);
  final String label;
}

/// A car offered by a company: `cars/{id}`. Ambassadors share these.
class Car {
  final String id;
  final String companyId;

  /// Denormalised so lists don't need a second read.
  final String companyName;
  final String model;
  final CarCategory category;
  final double pricePerDay;
  final String? imageUrl;
  final int seats;
  final Transmission transmission;
  final String city;
  final bool isAvailable;

  const Car({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.model,
    required this.category,
    required this.pricePerDay,
    required this.city,
    this.imageUrl,
    this.seats = 5,
    this.transmission = Transmission.manual,
    this.isAvailable = true,
  });

  factory Car.fromJson(String id, Map<String, dynamic> json) => Car(
    id: id,
    companyId: readString(json['companyId']),
    companyName: readString(json['companyName']),
    model: readString(json['model']),
    category: readEnum(
      CarCategory.values,
      json['category'],
      CarCategory.citadine,
    ),
    pricePerDay: readDouble(json['pricePerDay']),
    imageUrl: readNullableString(json['imageUrl']),
    seats: readInt(json['seats'], 5),
    transmission: readEnum(
      Transmission.values,
      json['transmission'],
      Transmission.manual,
    ),
    city: readString(json['city']),
    isAvailable: readBool(json['isAvailable'], true),
  );

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'companyName': companyName,
    'model': model,
    'category': category.name,
    'pricePerDay': pricePerDay,
    'imageUrl': imageUrl,
    'seats': seats,
    'transmission': transmission.name,
    'city': city,
    'isAvailable': isAvailable,
  };
}
