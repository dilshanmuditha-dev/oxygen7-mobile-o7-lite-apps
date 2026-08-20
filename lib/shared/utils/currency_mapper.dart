/// Utility class for mapping country codes to currencies.
/// Used to determine the default currency based on merchant's location.
class CurrencyMapper {
  /// Maps ISO 3166-1 alpha-2 country codes to ISO 4217 currency codes.
  static const Map<String, String> countryToCurrency = {
    // Southeast Asia
    'SG': 'SGD', // Singapore
    'MY': 'MYR', // Malaysia
    'TH': 'THB', // Thailand
    'ID': 'IDR', // Indonesia
    'PH': 'PHP', // Philippines
    'VN': 'VND', // Vietnam
    'BN': 'BND', // Brunei
    'MM': 'MMK', // Myanmar
    'KH': 'KHR', // Cambodia
    'LA': 'LAK', // Laos

    // East Asia
    'CN': 'CNY', // China
    'HK': 'HKD', // Hong Kong
    'TW': 'TWD', // Taiwan
    'JP': 'JPY', // Japan
    'KR': 'KRW', // South Korea
    'MO': 'MOP', // Macau

    // South Asia
    'IN': 'INR', // India
    'BD': 'BDT', // Bangladesh
    'LK': 'LKR', // Sri Lanka
    'PK': 'PKR', // Pakistan
    'NP': 'NPR', // Nepal
    'BT': 'BTN', // Bhutan

    // Oceania
    'AU': 'AUD', // Australia
    'NZ': 'NZD', // New Zealand

    // Americas
    'US': 'USD', // United States
    'CA': 'CAD', // Canada

    // Europe
    'GB': 'GBP', // United Kingdom
    'EU': 'EUR', // European Union (generic)
    'DE': 'EUR', // Germany
    'FR': 'EUR', // France
    'IT': 'EUR', // Italy
    'ES': 'EUR', // Spain
    'NL': 'EUR', // Netherlands
    'CH': 'CHF', // Switzerland

    // Middle East
    'AE': 'AED', // United Arab Emirates
    'SA': 'SAR', // Saudi Arabia
    'QA': 'QAR', // Qatar
  };

  /// Gets the default currency based on the merchant's country code.
  ///
  /// [countryCodeAlpha] - The merchant's country code (ISO 3166-1 alpha-2)
  /// [supportedCurrencies] - List of currencies supported by the payment route
  ///
  /// Returns the mapped currency if it exists in supportedCurrencies,
  /// otherwise returns the first currency in the list.
  static String getDefaultCurrency(
    String? countryCodeAlpha,
    List<String> supportedCurrencies,
  ) {
    // Handle empty list
    if (supportedCurrencies.isEmpty) {
      return '';
    }

    // Handle null or empty country code
    if (countryCodeAlpha == null || countryCodeAlpha.isEmpty) {
      return supportedCurrencies.first;
    }

    // Normalize country code to uppercase
    final normalizedCode = countryCodeAlpha.toUpperCase();

    // Get mapped currency for the country
    final mappedCurrency = countryToCurrency[normalizedCode];

    // If mapped currency exists and is in supported list, use it
    if (mappedCurrency != null &&
        supportedCurrencies.contains(mappedCurrency)) {
      return mappedCurrency;
    }

    // Fallback to first currency in the list
    return supportedCurrencies.first;
  }
}
