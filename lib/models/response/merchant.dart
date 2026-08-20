class Merchant {
  final String merchantId;
  final String name;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? addressLine4;
  final String? addressLine5;
  final String? city;
  final String? postalCode;
  final String? url;
  final bool isActive;
  final String? countryCodeAlpha;
  final String? countryCodeNumeric;

  Merchant({
    required this.merchantId,
    required this.name,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.addressLine4,
    this.addressLine5,
    this.city,
    this.postalCode,
    this.url,
    required this.isActive,
    this.countryCodeAlpha,
    this.countryCodeNumeric,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
        merchantId: json["merchant_id"] ?? "",
        name: json["name"] ?? "",
        addressLine1: json["address_line_1"] ?? "",
        addressLine2: json["address_line_2"] ?? "",
        addressLine3: json["address_line_3"] ?? "",
        addressLine4: json["address_line_4"],
        addressLine5: json["address_line_5"],
        city: json["city"] ?? "",
        postalCode: json["postal_code"] ?? "",
        url: json["url"] ?? "",
        isActive: json["is_active"] ?? false,
        countryCodeAlpha: json["country_code_alpha"] ?? "",
        countryCodeNumeric: json["country_code_numeric"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "merchant_id": merchantId,
        "name": name,
        "address_line_1": addressLine1,
        "address_line_2": addressLine2,
        "address_line_3": addressLine3,
        "address_line_4": addressLine4,
        "address_line_5": addressLine5,
        "city": city,
        "postal_code": postalCode,
        "url": url,
        "is_active": isActive,
        "country_code_alpha": countryCodeAlpha,
        "country_code_numeric": countryCodeNumeric,
      };
}
