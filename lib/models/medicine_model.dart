class Medicine {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String? genericName;
  final String? category;
  final String? description;
  final List<String> uses;
  final List<String> sideEffects;
  final List<String> warnings;
  final List<String> interactions;
  final String? dosageInfo;
  final String? howToTake;
  final String? storage;
  final String? imageUrl;

  Medicine({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.genericName,
    this.category,
    this.description,
    required this.uses,
    required this.sideEffects,
    required this.warnings,
    required this.interactions,
    this.dosageInfo,
    this.howToTake,
    this.storage,
    this.imageUrl,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'],
      genericName: json['generic_name'],
      category: json['category'],
      description: json['description'],
      uses: List<String>.from(json['uses'] ?? []),
      sideEffects: List<String>.from(json['side_effects'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      interactions: List<String>.from(json['interactions'] ?? []),
      dosageInfo: json['dosage_info'],
      howToTake: json['how_to_take'],
      storage: json['storage'],
      imageUrl: json['image_url'],
    );
  }
}
