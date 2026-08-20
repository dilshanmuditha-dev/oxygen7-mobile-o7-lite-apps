/// Deep link parameter validation utility.
///
/// Validates incoming deep link intents (scheme="my", host="native") against
/// an allowlist of known routes and sanitizes parameters to prevent injection.
///
/// Bug Condition: isBugCondition_UnvalidatedDeepLink(X) where
///   X.scheme = "my" AND X.host = "native" AND NOT X.parametersAreValidated
///
/// Expected Behavior: result.parametersValidated = true
///   AND (result.isValid OR result.isRejectedGracefully)
class DeepLinkValidator {
  /// The expected deep link scheme.
  static const String expectedScheme = 'my';

  /// The expected deep link host.
  static const String expectedHost = 'native';

  /// Default route to navigate to when validation fails.
  static const String defaultRoute = '/home';

  /// Allowlist of valid routes that deep links can navigate to.
  static const List<String> allowedRoutes = [
    '/splash',
    '/auth',
    '/log_in',
    '/home',
    '/payment_list',
    '/payment_list_void',
    '/privacy',
    '/change_language',
    '/credit_card',
    '/card-reader',
    '/digital_payment',
    '/payment_page_qr_o7lite',
    '/transaction_history',
    '/transaction_history_detail',
    '/report_screen',
    '/refund_screen',
    '/scan_qr_code',
    '/forgot_password',
    '/trouble_shooting_page',
    '/print_screen',
    '/wifi_screen',
    '/touch_screen',
    '/battery_screen',
    '/bluetooth_screen',
    '/scanner_screen',
    '/barcode_screen',
    '/app_setting',
    '/create_payment_url',
    '/bluetooth_printer',
    '/cloud_print_test',
  ];

  /// Maximum allowed length for any parameter value.
  static const int maxParameterLength = 256;

  /// Regex pattern for allowed characters in route parameters.
  /// Only allows alphanumeric, hyphens, underscores, and forward slashes.
  static final RegExp _allowedRoutePattern = RegExp(r'^[a-zA-Z0-9_/\-]+$');

  /// Regex pattern for allowed characters in general string parameters.
  /// Blocks common injection characters: <, >, ", ', ;, {, }, |, \
  static final RegExp _dangerousCharsPattern = RegExp(r'[<>"' "'" r';{}|\\`$]');

  /// Validates an incoming deep link URI.
  ///
  /// Returns the validated route string if the deep link is valid,
  /// or the [defaultRoute] if the deep link is malformed or contains
  /// unexpected values.
  ///
  /// Validation checks:
  /// 1. Scheme must be "my"
  /// 2. Host must be "native"
  /// 3. Route parameter must be in the [allowedRoutes] list
  /// 4. All parameters are sanitized against injection attacks
  static String validate(Uri deepLink) {
    // Check scheme
    if (deepLink.scheme != expectedScheme) {
      return defaultRoute;
    }

    // Check host
    if (deepLink.host != expectedHost) {
      return defaultRoute;
    }

    // Extract route parameter
    final String? route = deepLink.queryParameters['route'];

    // If no route parameter, return default
    if (route == null || route.isEmpty) {
      return defaultRoute;
    }

    // Sanitize the route parameter
    final String sanitizedRoute = sanitize(route);

    // Check if sanitized route is empty after sanitization
    if (sanitizedRoute.isEmpty) {
      return defaultRoute;
    }

    // Validate against allowlist
    if (!allowedRoutes.contains(sanitizedRoute)) {
      return defaultRoute;
    }

    return sanitizedRoute;
  }

  /// Sanitizes a string parameter to prevent injection attacks.
  ///
  /// - Trims whitespace
  /// - Rejects strings exceeding [maxParameterLength]
  /// - Removes dangerous characters that could be used for injection
  /// - Validates against allowed character pattern for routes
  static String sanitize(String input) {
    // Trim whitespace
    String sanitized = input.trim();

    // Reject overly long inputs
    if (sanitized.length > maxParameterLength) {
      return '';
    }

    // Remove dangerous characters
    sanitized = sanitized.replaceAll(_dangerousCharsPattern, '');

    // Validate against allowed pattern
    if (!_allowedRoutePattern.hasMatch(sanitized)) {
      return '';
    }

    return sanitized;
  }

  /// Checks if a deep link URI has a valid scheme and host.
  ///
  /// This is a quick check before full validation to determine
  /// if the URI is intended for this app.
  static bool isValidDeepLink(Uri uri) {
    return uri.scheme == expectedScheme && uri.host == expectedHost;
  }
}
