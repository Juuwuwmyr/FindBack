enum ReportType { lost, found }

enum ReportStatus { active, claimed, resolved, closed }

enum ItemCategory {
  electronics,
  documentsKeys,
  bagsLuggage,
  clothingAccessories,
  pets,
  jewelry,
  sportsEquipment,
  booksStationery,
  toys,
  vehicles,
  moneyCards,
  other,
}

extension ReportTypeExt on ReportType {
  String get dbValue => name.toUpperCase();
  String get label => name == 'lost' ? 'LOST' : 'FOUND';
  static ReportType fromDb(String v) =>
      ReportType.values.firstWhere((e) => e.dbValue == v.toUpperCase());
}

extension ReportStatusExt on ReportStatus {
  String get dbValue => name.toUpperCase();
  static ReportStatus fromDb(String v) =>
      ReportStatus.values.firstWhere((e) => e.dbValue == v.toUpperCase());
}

extension ItemCategoryExt on ItemCategory {
  String get dbValue {
    switch (this) {
      case ItemCategory.electronics:
        return 'ELECTRONICS';
      case ItemCategory.documentsKeys:
        return 'DOCUMENTS_KEYS';
      case ItemCategory.bagsLuggage:
        return 'BAGS_LUGGAGE';
      case ItemCategory.clothingAccessories:
        return 'CLOTHING_ACCESSORIES';
      case ItemCategory.pets:
        return 'PETS';
      case ItemCategory.jewelry:
        return 'JEWELRY';
      case ItemCategory.sportsEquipment:
        return 'SPORTS_EQUIPMENT';
      case ItemCategory.booksStationery:
        return 'BOOKS_STATIONERY';
      case ItemCategory.toys:
        return 'TOYS';
      case ItemCategory.vehicles:
        return 'VEHICLES';
      case ItemCategory.moneyCards:
        return 'MONEY_CARDS';
      case ItemCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.documentsKeys:
        return 'Documents & Keys';
      case ItemCategory.bagsLuggage:
        return 'Bags & Luggage';
      case ItemCategory.clothingAccessories:
        return 'Clothing & Accessories';
      case ItemCategory.pets:
        return 'Pets';
      case ItemCategory.jewelry:
        return 'Jewelry';
      case ItemCategory.sportsEquipment:
        return 'Sports Equipment';
      case ItemCategory.booksStationery:
        return 'Books & Stationery';
      case ItemCategory.toys:
        return 'Toys';
      case ItemCategory.vehicles:
        return 'Vehicles';
      case ItemCategory.moneyCards:
        return 'Money & Cards';
      case ItemCategory.other:
        return 'Other';
    }
  }

  static ItemCategory fromDb(String v) {
    switch (v.toUpperCase()) {
      case 'ELECTRONICS':
        return ItemCategory.electronics;
      case 'DOCUMENTS_KEYS':
        return ItemCategory.documentsKeys;
      case 'BAGS_LUGGAGE':
        return ItemCategory.bagsLuggage;
      case 'CLOTHING_ACCESSORIES':
        return ItemCategory.clothingAccessories;
      case 'PETS':
        return ItemCategory.pets;
      case 'JEWELRY':
        return ItemCategory.jewelry;
      case 'SPORTS_EQUIPMENT':
        return ItemCategory.sportsEquipment;
      case 'BOOKS_STATIONERY':
        return ItemCategory.booksStationery;
      case 'TOYS':
        return ItemCategory.toys;
      case 'VEHICLES':
        return ItemCategory.vehicles;
      case 'MONEY_CARDS':
        return ItemCategory.moneyCards;
      default:
        return ItemCategory.other;
    }
  }
}

class ItemReportModel {
  const ItemReportModel({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.category,
    required this.dateOfIncident,
    required this.locationText,
    this.latitude,
    this.longitude,
    required this.imageUrls,
    required this.rewardOffered,
    this.rewardDescription,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.reporterName,
    this.reporterAvatarUrl,
  });

  final String id;
  final String reporterId;
  final ReportType type;
  final ReportStatus status;
  final String title;
  final String description;
  final ItemCategory category;
  final DateTime dateOfIncident;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final bool rewardOffered;
  final String? rewardDescription;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  // Joined fields (optional, from profile join)
  final String? reporterName;
  final String? reporterAvatarUrl;

  factory ItemReportModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    return ItemReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      type: ReportTypeExt.fromDb(json['type'] as String),
      status: ReportStatusExt.fromDb(json['status'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      category: ItemCategoryExt.fromDb(json['category'] as String),
      dateOfIncident: DateTime.parse(json['date_of_incident'] as String),
      locationText: json['location_text'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      rewardOffered: json['reward_offered'] as bool? ?? false,
      rewardDescription: json['reward_description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      reporterName: profileData?['display_name'] as String?,
      reporterAvatarUrl: profileData?['avatar_url'] as String?,
    );
  }

  ItemReportModel copyWith({
    ReportStatus? status,
    String? title,
    String? description,
    ItemCategory? category,
    DateTime? dateOfIncident,
    String? locationText,
    List<String>? imageUrls,
    bool? rewardOffered,
    String? rewardDescription,
    DateTime? updatedAt,
  }) {
    return ItemReportModel(
      id: id,
      reporterId: reporterId,
      type: type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateOfIncident: dateOfIncident ?? this.dateOfIncident,
      locationText: locationText ?? this.locationText,
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      rewardOffered: rewardOffered ?? this.rewardOffered,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
      reporterName: reporterName,
      reporterAvatarUrl: reporterAvatarUrl,
    );
  }
}
