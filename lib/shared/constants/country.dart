/// Enum representing supported countries in O7Lite.
/// Provides type-safe country handling with associated metadata.
///
/// Each country includes:
/// - [alpha2Code]: ISO 3166-1 alpha-2 code (2 letters)
/// - [alpha3Code]: ISO 3166-1 alpha-3 code (3 letters)
/// - [currencyCode]: ISO 4217 currency code (3 letters)
/// - [numericCode]: ISO 3166-1 numeric code (3 digits)
/// - [displayName]: Human-readable country name
enum Country {
  singapore(
    alpha2Code: 'SG',
    alpha3Code: 'SGP',
    currencyCode: 'SGD',
    numericCode: '702',
    displayName: 'Singapore',
  ),
  malaysia(
    alpha2Code: 'MY',
    alpha3Code: 'MYS',
    currencyCode: 'MYR',
    numericCode: '458',
    displayName: 'Malaysia',
  ),
  thailand(
    alpha2Code: 'TH',
    alpha3Code: 'THA',
    currencyCode: 'THB',
    numericCode: '764',
    displayName: 'Thailand',
  ),
  bhutan(
    alpha2Code: 'BT',
    alpha3Code: 'BTN',
    currencyCode: 'BTN',
    numericCode: '064',
    displayName: 'Bhutan',
  );

  /// ISO 3166-1 alpha-2 country code (2 letters, e.g., SG, MY, TH, BT)
  final String alpha2Code;

  /// ISO 3166-1 alpha-3 country code (3 letters, e.g., SGP, MYS, THA, BTN)
  final String alpha3Code;

  /// ISO 4217 currency code (3 letters, e.g., SGD, MYR, THB, BTN)
  final String currencyCode;

  /// ISO 3166-1 numeric country code (3 digits, e.g., 702, 458, 764, 064)
  final String numericCode;

  /// Human-readable country display name
  final String displayName;

  const Country({
    required this.alpha2Code,
    required this.alpha3Code,
    required this.currencyCode,
    required this.numericCode,
    required this.displayName,
  });

  /// Converts an ISO 3166-1 alpha-3 code to Country enum.
  /// Returns null if no match found. Case-insensitive.
  static Country? fromAlpha3(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.toUpperCase();
    return Country.values.cast<Country?>().firstWhere(
          (c) => c?.alpha3Code == normalized,
          orElse: () => null,
        );
  }

  /// Converts an ISO 3166-1 alpha-2 code to Country enum.
  /// Returns null if no match found. Case-insensitive.
  static Country? fromAlpha2(String? code) {
    if (code == null || code.isEmpty) return null;
    final normalized = code.toUpperCase();
    return Country.values.cast<Country?>().firstWhere(
          (c) => c?.alpha2Code == normalized,
          orElse: () => null,
        );
  }

  /// Converts an ISO 3166-1 numeric code to Country enum.
  /// Returns null if no match found.
  static Country? fromNumeric(String? code) {
    if (code == null || code.isEmpty) return null;
    return Country.values.cast<Country?>().firstWhere(
          (c) => c?.numericCode == code,
          orElse: () => null,
        );
  }
}
