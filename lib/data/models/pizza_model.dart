class PizzaModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isBestSeller;
  final bool isAvailable;
  final DateTime? availableAt;

  PizzaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category = 'Pizza',
    this.isBestSeller = false,
    this.isAvailable = true,
    this.availableAt,
  });
  bool get isCurrentlyAvailable {
    if (isAvailable) return true;
    if (availableAt != null) {
      final target = availableAt!.toLocal();
      final now = DateTime.now();
      if (now.isAfter(target)) return true;
    }
    return false;
  }

  factory PizzaModel.fromJson(Map<String, dynamic> json) {
    return PizzaModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Pizza',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl:
          json['image_url'] ??
          json['image'] ??
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
      category: json['category'] ?? 'Pizza',
      isBestSeller: json['is_best_seller'] ?? false,
      isAvailable: json['is_available'] ?? true,
      availableAt: json['available_at'] != null
          ? DateTime.tryParse(json['available_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_best_seller': isBestSeller,
      'is_available': isAvailable,
      'available_at': availableAt?.toIso8601String(),
    };
  }
}
