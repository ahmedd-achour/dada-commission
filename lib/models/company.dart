import '../core/constants.dart';
import 'json_utils.dart';

enum CompanyStatus {
  pending('En attente de validation'),
  approved('Validée'),
  rejected('Refusée'),
  suspended('Suspendue');

  const CompanyStatus(this.label);
  final String label;
}

/// A rent-car company: `companies/{id}`.
///
/// Dada Rent Car is the flagship company; other agencies register through the
/// app and appear in the marketplace once the Dada team approves them. The
/// company pays the ambassador's commission on every rental it gets through
/// a code, link or QR code.
class RentalCompany {
  final String id;
  final String name;
  final String ownerUid;
  final String? logoUrl;
  final String city;
  final String? address;
  final String phone;
  final String? email;

  /// Matricule fiscal.
  final String taxRegistrationNumber;
  final int fleetSize;
  final bool isFlagship;

  /// Discount given to customers who book with a code (5 % by default).
  final double customerDiscountRate;
  final CompanyStatus status;
  final DateTime createdAt;

  const RentalCompany({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.city,
    required this.phone,
    required this.taxRegistrationNumber,
    required this.createdAt,
    this.logoUrl,
    this.address,
    this.email,
    this.fleetSize = 0,
    this.isFlagship = false,
    this.customerDiscountRate = kCustomerDiscountRate,
    this.status = CompanyStatus.pending,
  });

  bool get isApproved => status == CompanyStatus.approved;

  factory RentalCompany.fromJson(String id, Map<String, dynamic> json) =>
      RentalCompany(
        id: id,
        name: readString(json['name']),
        ownerUid: readString(json['ownerUid']),
        logoUrl: readNullableString(json['logoUrl']),
        city: readString(json['city']),
        address: readNullableString(json['address']),
        phone: readString(json['phone']),
        email: readNullableString(json['email']),
        taxRegistrationNumber: readString(json['taxRegistrationNumber']),
        fleetSize: readInt(json['fleetSize']),
        isFlagship: readBool(json['isFlagship']),
        customerDiscountRate: readDouble(
          json['customerDiscountRate'],
          kCustomerDiscountRate,
        ),
        status: readEnum(
          CompanyStatus.values,
          json['status'],
          CompanyStatus.pending,
        ),
        createdAt: readDate(json['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'ownerUid': ownerUid,
    'logoUrl': logoUrl,
    'city': city,
    'address': address,
    'phone': phone,
    'email': email,
    'taxRegistrationNumber': taxRegistrationNumber,
    'fleetSize': fleetSize,
    'isFlagship': isFlagship,
    'customerDiscountRate': customerDiscountRate,
    'status': status.name,
    'createdAt': writeDate(createdAt),
  };
}
