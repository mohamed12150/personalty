/// عنصر من كتالوج الأفاتارات — مطابق لجدول avatar_catalog
class AvatarItem {
  final int id;
  final String pack; // man | girl | ...
  final String assetPath;
  final bool isPremium;
  final int price;

  const AvatarItem({
    required this.id,
    required this.pack,
    required this.assetPath,
    required this.isPremium,
    required this.price,
  });

  factory AvatarItem.fromJson(Map<String, dynamic> json) {
    return AvatarItem(
      id: json['id'] as int,
      pack: json['pack'] ?? '',
      assetPath: json['asset_path'] ?? '',
      isPremium: json['is_premium'] ?? false,
      price: json['price'] ?? 0,
    );
  }
}

/// لون اسم من كتالوج الألوان — مطابق لجدول color_catalog
class ColorItem {
  final String color;
  final int price;
  final int sortOrder;

  const ColorItem({
    required this.color,
    required this.price,
    required this.sortOrder,
  });

  factory ColorItem.fromJson(Map<String, dynamic> json) {
    return ColorItem(
      color: json['color'] ?? '',
      price: json['price'] ?? 0,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
