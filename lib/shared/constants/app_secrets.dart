import 'package:envied/envied.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'app_secrets.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class AppSecrets {
  @EnviedField(varName: 'USER_GUIDE_URL')
  static final String userGuideUrl = _AppSecrets.userGuideUrl;

  @EnviedField(varName: 'PRIVACY_POLICY_URL')
  static final String privacyPolicyUrl = _AppSecrets.privacyPolicyUrl;

  @EnviedField(varName: 'MERCHANT_DASHBOARD_URL')
  static final String merchantDashboardUrl = _AppSecrets.merchantDashboardUrl;

  @EnviedField(varName: 'SUPPORT_EMAIL')
  static final String supportEmail = _AppSecrets.supportEmail;

  static String get userGuideUrlFallback => dotenv.env['USER_GUIDE_URL'] ?? '';
  static String get privacyPolicyUrlFallback =>
      dotenv.env['PRIVACY_POLICY_URL'] ?? '';
  static String get merchantDashboardUrlFallback =>
      dotenv.env['MERCHANT_DASHBOARD_URL'] ?? '';
  static String get supportEmailFallback => dotenv.env['SUPPORT_EMAIL'] ?? '';
}
