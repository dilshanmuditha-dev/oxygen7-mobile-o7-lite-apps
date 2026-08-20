import '../constants/environmental_attribute.dart';

enum AppFlavor {
  development,
  developmentGW3,
  production,
  productionGW3,
}

extension AppFlavorHelper on AppFlavor {
  EnvironmentalAttribute get attributeFlavor {
    switch (this) {
      case AppFlavor.development:
        return EnvironmentalAttribute.development();

      case AppFlavor.developmentGW3:
        return EnvironmentalAttribute.developmentGW3();

      case AppFlavor.production:
        return EnvironmentalAttribute.production();

      case AppFlavor.productionGW3:
        return EnvironmentalAttribute.productionGW3();
    }
  }

  String get apiBaseUrl => attributeFlavor.apiBaseUrl;

  bool get isDevelopment =>
      this == AppFlavor.development || this == AppFlavor.developmentGW3;

  bool get isProduction =>
      this == AppFlavor.production || this == AppFlavor.productionGW3;
}
