import '../../api/api_constants.dart';

import '../utils/app_flavor_helper.dart';

class EnvironmentalAttribute {
  EnvironmentalAttribute.development()
      : flavorType = AppFlavor.development,
        apiBaseUrl = ApiConstants.API_DEV;

  EnvironmentalAttribute.production()
      : flavorType = AppFlavor.production,
        apiBaseUrl = ApiConstants.API_PRO;

  EnvironmentalAttribute.developmentGW3()
      : flavorType = AppFlavor.development,
        apiBaseUrl = ApiConstants.API_GW3_DEV;

  EnvironmentalAttribute.productionGW3()
      : flavorType = AppFlavor.production,
        apiBaseUrl = ApiConstants.API_GW3_PRO;

  final String apiBaseUrl;
  final AppFlavor flavorType;

  bool get isDevelopment =>
      flavorType == AppFlavor.development ||
      flavorType == AppFlavor.developmentGW3;

  bool get isProduction =>
      flavorType == AppFlavor.production ||
      flavorType == AppFlavor.productionGW3;
}
