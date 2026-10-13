import '../core/constants.dart';
import 'json_utils.dart';

enum CompanyStatus {
  /// Form started, documents still missing.
  draft('Dossier incomplet'),
  pending('En attente de validation'),
  approved('Validée'),
  rejected('Refusée'),
  suspended('Suspendue');

  const CompanyStatus(this.label);
  final String label;
}

/// Papers a rent-car company sends to join the hub.
enum CompanyDocumentType {
  rne('Extrait du RNE (registre des entreprises)'),
  taxCertificate('Attestation de matricule fiscal'),
  managerId('CIN du gérant'),
  insurance('Attestation d\'assurance de la flotte'),
  rentalLicense('Autorisation de location de voitures');

  const CompanyDocumentType(this.label);
  final String label;
}

enum DocumentStatus {
  missing('À fournir'),
  submitted('Envoyé'),
  approved('Validé'),
  rejected('Refusé');

  const DocumentStatus(this.label);
  final String label;
}

/// One uploaded paper. Files live in Storage under
/// `companies/{companyId}/documents/{type}`; [url] points there.
class CompanyDocument {
  final CompanyDocumentType type;
  final DocumentStatus status;
  final String? url;
  final DateTime? submittedAt;

  const CompanyDocument({
    required this.type,
    this.status = DocumentStatus.missing,
    this.url,
    this.submittedAt,
  });

  factory CompanyDocument.fromJson(Map<String, dynamic> json) =>
      CompanyDocument(
        type: readEnum(
          CompanyDocumentType.values,
          json['type'],
          CompanyDocumentType.rne,
        ),
        status: readEnum(
          DocumentStatus.values,
          json['status'],
          DocumentStatus.missing,
        ),
        url: readNullableString(json['url']),
        submittedAt: readDate(json['submittedAt']),
      );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'status': status.name,
    'url': url,
    'submittedAt': writeDate(submittedAt),
  };
}

/// A rent-car company: `companies/{id}`.
///
/// Dada Rent Car is the flagship company; other agencies register through the
/// account-setup wizard and appear in the marketplace once the Dada team has
/// checked their documents. The company pays the ambassador's commission on
/// every rental it gets through a code, link or QR code; Dada converts it to
/// Dada Coins.
class RentalCompany {
  final String id;
  final String name;
  final String ownerUid;
  final String? logoUrl;
  final String city;
  final String? address;
  final String phone;
  final String? email;
  final String? contactName;

  /// Matricule fiscal.
  final String taxRegistrationNumber;

  /// Identifiant unique RNE.
  final String? rneNumber;
  final int fleetSize;
  final bool isFlagship;

  /// Discount given to customers who book with a code (5 % by default).
  final double customerDiscountRate;
  final List<CompanyDocument> documents;

  /// When the owner accepted the commission agreement.
  final DateTime? agreementAcceptedAt;
  final CompanyStatus status;
  final String? rejectionReason;
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
    this.contactName,
    this.rneNumber,
    this.fleetSize = 0,
    this.isFlagship = false,
    this.customerDiscountRate = kCustomerDiscountRate,
    this.documents = const [],
    this.agreementAcceptedAt,
    this.status = CompanyStatus.pending,
    this.rejectionReason,
  });

  bool get isApproved => status == CompanyStatus.approved;

  DocumentStatus documentStatus(CompanyDocumentType type) {
    for (final d in documents) {
      if (d.type == type) return d.status;
    }
    return DocumentStatus.missing;
  }

  /// Every required paper has at least been sent.
  bool get hasAllDocuments => CompanyDocumentType.values.every(
    (t) => documentStatus(t) != DocumentStatus.missing,
  );

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
        contactName: readNullableString(json['contactName']),
        taxRegistrationNumber: readString(json['taxRegistrationNumber']),
        rneNumber: readNullableString(json['rneNumber']),
        fleetSize: readInt(json['fleetSize']),
        isFlagship: readBool(json['isFlagship']),
        customerDiscountRate: readDouble(
          json['customerDiscountRate'],
          kCustomerDiscountRate,
        ),
        documents: json['documents'] is List
            ? [
                for (final d in json['documents'] as List)
                  if (d is Map<String, dynamic>) CompanyDocument.fromJson(d),
              ]
            : const [],
        agreementAcceptedAt: readDate(json['agreementAcceptedAt']),
        status: readEnum(
          CompanyStatus.values,
          json['status'],
          CompanyStatus.pending,
        ),
        rejectionReason: readNullableString(json['rejectionReason']),
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
    'contactName': contactName,
    'taxRegistrationNumber': taxRegistrationNumber,
    'rneNumber': rneNumber,
    'fleetSize': fleetSize,
    'isFlagship': isFlagship,
    'customerDiscountRate': customerDiscountRate,
    'documents': [for (final d in documents) d.toJson()],
    'agreementAcceptedAt': writeDate(agreementAcceptedAt),
    'status': status.name,
    'rejectionReason': rejectionReason,
    'createdAt': writeDate(createdAt),
  };
}
