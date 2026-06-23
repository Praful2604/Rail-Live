class MenuItem {
  final String item;
  final int price;

  const MenuItem({required this.item, required this.price});

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      item: json['item'] as String,
      price: (json['price'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'item': item, 'price': price};
}

class RestaurantModel {
  final int id;
  final String name;
  final double distanceFromStationKm;
  final double rating;
  final String priceRange;
  final String contact;
  final String openingHours;
  final List<MenuItem> menu;
  final String stationName;

  // Computed at runtime from GPS
  double? distanceFromUserKm;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.distanceFromStationKm,
    required this.rating,
    required this.priceRange,
    required this.contact,
    required this.openingHours,
    required this.menu,
    required this.stationName,
    this.distanceFromUserKm,
  });

  factory RestaurantModel.fromJson(
      Map<String, dynamic> json,
      String stationName,
      ) {
    return RestaurantModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      distanceFromStationKm: (json['distance_km'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      priceRange: json['price_range'] as String,
      contact: json['contact'] as String,
      openingHours: json['opening_hours'] as String,
      menu: (json['menu'] as List<dynamic>)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      stationName: stationName,
    );
  }
}