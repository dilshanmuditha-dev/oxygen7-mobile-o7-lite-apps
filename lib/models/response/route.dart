class Route {
  final String brand;
  final String host;
  final List<String> currencies;
  final bool isActive;

  Route({
    required this.brand,
    required this.host,
    required this.currencies,
    required this.isActive,
  });

  factory Route.fromJson(Map<String, dynamic> json) => Route(
        brand: json["brand"],
        host: json["host"],
        currencies: List<String>.from(json["currencies"].map((x) => x)),
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "brand": brand,
        "host": host,
        "currencies": List<dynamic>.from(currencies.map((x) => x)),
        "is_active": isActive,
      };
}
