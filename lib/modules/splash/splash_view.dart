// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'dart:async';
import 'dart:io' show Platform, exit;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:get/get.dart';
import '../../api/api_provider.dart';
import '../../app_controller.dart';
import '../../routes/app_pages.dart';
import '../../shared/constants/common.dart';
import '../../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../shared/services/storage_service.dart';
import '../../shared/services/login_deep_link_service.dart';
import '../../shared/utils/deep_link_validator.dart';
import '../../shared/utils/enum/app_dialog_type.dart';
import '../../shared/utils/jwt_utils.dart';
import '../../shared/utils/responsive_util.dart';
import '../../shared/widgets/custom_dialog/custom_dialog.dart';
import 'models/splash_performance_flags.dart';
import 'models/splash_color_scheme.dart';
import 'widgets/adaptive_splash_background.dart';
import 'widgets/adaptive_splash_decorations.dart';
import 'widgets/adaptive_loading_indicator.dart';
import 'package:app/shared/utils/log_utils.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  final AppController appController = Get.find();

  // Animation controllers
  late AnimationController _fadeController;
  AnimationController? _pulseController;
  AnimationController? _particleController;

  // Animations
  late Animation<double> _fadeAnimation;
  Animation<double>? _pulseAnimation;
  Animation<double>? _particleAnimation;

  // State flags
  bool _isLogoLoaded = false;
  bool _isTextAnimationReady = false;
  bool _isReadyToNavigate = false;
  bool _didInitializeSetup = false;
  bool _isSecurityCheckInProgress = false;

  // Performance flags (cached)
  late SplashPerformanceFlags _performanceFlags;

  @override
  void initState() {
    super.initState();

    // Set default language
    SharedPrefManager.instance.setString('saveLanguage', '🇺🇸');

    // Get performance flags (with fallback for uninitialized detector)
    _performanceFlags = SplashPerformanceFlags.getFlags();

    // Initialize fade animation controller (always needed)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    // Initialize additional animations only for high-spec devices
    if (_performanceFlags.enableComplexAnimations) {
      _initializeHighSpecAnimations();
    }
  }

  /// Initialize animations for high-spec devices only
  void _initializeHighSpecAnimations() {
    // Pulse animation for decorations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController!.repeat(reverse: true);

    // Particle animation for floating effect
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _particleController!,
    );
    _particleController!.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didInitializeSetup) {
      _didInitializeSetup = true;
      _setupSplash();
    }
  }

  Future<void> _setupSplash() async {
    try {
      await precacheImage(
        AssetImage(ImageConstant.oxygen7IconTransparentBackgroundSmall),
        context,
      );
    } catch (e) {
      LogUtils.debugLog('Logo loading failed: $e');
    }

    if (mounted) {
      setState(() {
        _isLogoLoaded = true;
      });

      _fadeController.forward();

      // Delay based on device capability
      final delay = _performanceFlags.shouldUseSimplifiedUI ? 200 : 300;
      await Future.delayed(Duration(milliseconds: delay));

      if (mounted) {
        setState(() {
          _isTextAnimationReady = true;
        });

        // Wait for slogan animation to complete before navigating
        // "Beyond Digital Payment" = 22 chars, speed 30ms/char = 660ms + buffer
        final navDelay = _performanceFlags.shouldUseSimplifiedUI ? 1500 : 2500;
        await Future.delayed(Duration(milliseconds: navDelay));

        if (mounted) {
          setState(() {
            _isReadyToNavigate = true;
            _isSecurityCheckInProgress = true;
          });

          _checkDeviceIntegrity();
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController?.dispose();
    _particleController?.dispose();
    super.dispose();
  }

  Future<void> _checkDeviceIntegrity() async {
    if (!mounted) return;

    // TODO(security): Remove SKIP_ROOT_DETECTION bypass before release — only for local testing.
    const bool kSkipRootDetection = bool.fromEnvironment('SKIP_ROOT_DETECTION');

    if (kDebugMode || kSkipRootDetection) {
      debugPrint('Skipping jailbreak and developer mode check');

      if (!_isReadyToNavigate) {
        await Future.delayed(const Duration(milliseconds: 2500));
      }

      _navigateToNextScreen();
      return;
    }

    bool jailbroken = false;
    bool developerMode = false;

    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
      developerMode = await FlutterJailbreakDetection.developerMode;
    } on PlatformException {
      jailbroken = true;
      developerMode = true;
    }

    if (!mounted) return;

    if (jailbroken || developerMode) {
      _showSecurityWarning();
    } else {
      if (!_isReadyToNavigate) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      _navigateToNextScreen();
    }
  }

  void _showSecurityWarning() {
    CustomDialog.showCustomDialog(
      isBarrierDismissible: true,
      isCheckEnableCloseIcon: true,
      content: CommonConstants.securityWarning.tr,
      context: context,
      onPressedCheck: _closeApp,
      titleButton: CommonConstants.exit.tr,
      dialogType: AppDialogType.failed,
    );
  }

  /// Retrieves and validates the deep link route from the platform.
  ///
  /// Returns the validated route if the app was launched via a valid deep link,
  /// or `null` if no deep link was used or the deep link is invalid.
  /// Invalid deep links result in navigation to the default route (/home).
  String? _getValidatedDeepLinkRoute() {
    try {
      final defaultRouteName =
          WidgetsBinding.instance.platformDispatcher.defaultRouteName;

      // Skip if no deep link or just the root route
      if (defaultRouteName.isEmpty || defaultRouteName == '/') {
        return null;
      }

      // Try to parse as a full URI (e.g., my://native?route=/home)
      Uri? deepLinkUri;
      try {
        deepLinkUri = Uri.parse(defaultRouteName);
      } catch (_) {
        return null;
      }

      // If the parsed URI doesn't have the expected scheme, try constructing
      // from the path (Flutter may strip the scheme in some versions)
      if (deepLinkUri.scheme != DeepLinkValidator.expectedScheme) {
        // Check if it looks like a path with query params (e.g., /native?route=/home)
        if (defaultRouteName.contains('route=')) {
          deepLinkUri = Uri.parse(
              '${DeepLinkValidator.expectedScheme}://${DeepLinkValidator.expectedHost}$defaultRouteName');
        } else {
          return null;
        }
      }

      // Validate the deep link using DeepLinkValidator
      final validatedRoute = DeepLinkValidator.validate(deepLinkUri);

      LogUtils.debugLog(
          '[DeepLink] Validated deep link: $defaultRouteName -> $validatedRoute');

      return validatedRoute;
    } catch (e) {
      LogUtils.debugLog('[DeepLink] Error processing deep link: $e');
      return null;
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (mounted) {
      setState(() {
        _isSecurityCheckInProgress = false;
      });
    }

    // Use adaptive transition duration
    final transitionDuration = _performanceFlags.transitionDuration;

    // Check for deep link and validate parameters before navigation
    final deepLinkRoute = _getValidatedDeepLinkRoute();
    final loginDeepLinkService = Get.isRegistered<LoginDeepLinkService>()
        ? Get.find<LoginDeepLinkService>()
        : null;

    try {
      final passwordEncrypted =
          await SecureSharedPreferences.instance.getPassword();

      if (kDebugMode) {
        final accessToken =
            await SecureSharedPreferences.instance.getAccessToken();
        final hasPassword =
            passwordEncrypted != null && passwordEncrypted.isNotEmpty;
        final hasToken = accessToken != null && accessToken.isNotEmpty;
        final isValid = hasToken ? JwtUtils.isTokenValid(accessToken) : false;
        final isExpiringSoon = hasToken
            ? JwtUtils.isTokenExpiringSoon(accessToken, bufferSeconds: 60)
            : true;
        LogUtils.debugLog(
            '[SplashAuth] hasPassword=$hasPassword, hasToken=$hasToken, '
            'isTokenValid=$isValid, isExpiringSoon=$isExpiringSoon');
      }

      if (loginDeepLinkService?.hasPendingCredentials == true ||
          loginDeepLinkService?.hasPendingError == true) {
        Get.offAllNamed(
          Routes.LOG_IN,
          arguments: {'transitionDuration': transitionDuration},
        );
      } else if (passwordEncrypted != null && passwordEncrypted.isNotEmpty) {
        // Validate access token locally before auto-navigating
        final accessToken =
            await SecureSharedPreferences.instance.getAccessToken();
        if (accessToken != null &&
            accessToken.isNotEmpty &&
            JwtUtils.isTokenValid(accessToken)) {
          // Token is still valid — navigate to deep link route or HOME
          final targetRoute = deepLinkRoute ?? Routes.HOME;
          Get.offAllNamed(
            targetRoute,
            arguments: {'transitionDuration': transitionDuration},
          );
        } else if (await _tryRefreshToken()) {
          // Token was expired but refresh succeeded — navigate to deep link route or HOME
          final targetRoute = deepLinkRoute ?? Routes.HOME;
          Get.offAllNamed(
            targetRoute,
            arguments: {'transitionDuration': transitionDuration},
          );
        } else {
          // Token is expired and refresh failed — redirect to login
          Get.offAllNamed(
            Routes.LOG_IN,
            arguments: {'transitionDuration': transitionDuration},
          );
        }
      } else {
        Get.offAllNamed(
          Routes.LOG_IN,
          arguments: {'transitionDuration': transitionDuration},
        );
      }
    } catch (e) {
      LogUtils.debugLog('Error retrieving password: $e');
      Get.offAllNamed(
        Routes.LOG_IN,
        arguments: {'transitionDuration': transitionDuration},
      );
    }
  }

  /// Attempts to refresh the access token using the stored refresh token.
  ///
  /// Only applies to GW3 gateway. For non-GW3, returns false immediately
  /// since those sessions don't support JWT refresh.
  ///
  /// Returns true if the token was successfully refreshed and stored.
  Future<bool> _tryRefreshToken() async {
    if (!StorageService.isGw3) return false;

    try {
      final apiProvider = Get.find<ApiProvider>();
      final refreshResponse = await apiProvider.refreshTokenGw3();

      if (refreshResponse.statusCode == 200 && refreshResponse.body != null) {
        final newAccessToken = refreshResponse.body['access_token'];
        final newRefreshToken = refreshResponse.body['refresh_token'];

        if (newAccessToken != null) {
          await SecureSharedPreferences.instance.setAccessToken(newAccessToken);

          // Update refresh token if provided (token rotation)
          if (newRefreshToken != null &&
              newRefreshToken.toString().isNotEmpty) {
            await SharedPrefManager.setRefreshTokenSecure(newRefreshToken);
          }

          if (kDebugMode) {
            debugPrint('SplashView: Token refreshed successfully on startup');
          }
          return true;
        }
      }

      if (kDebugMode) {
        debugPrint(
            'SplashView: Token refresh failed with status: ${refreshResponse.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SplashView: Token refresh error: $e');
      }
    }

    return false;
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = appController.isDarkModeOn.value;
    final colorScheme = SplashColorScheme.fromDarkMode(isDarkMode);
    final useGradient = _performanceFlags.enableGradients;
    final enableDecorations = _performanceFlags.enableComplexAnimations;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeApp();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.backgroundColor,
        body: AdaptiveSplashBackground(
          useGradient: useGradient,
          isDarkMode: isDarkMode,
          child: Stack(
            children: [
              // Decorative layer (high-spec only)
              AdaptiveSplashDecorations(
                enableAnimations: enableDecorations,
                isDarkMode: isDarkMode,
                pulseAnimation: _pulseAnimation,
                particleAnimation: _particleAnimation,
              ),
              // Main content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogoContainer(colorScheme),
                      SizedBox(height: ResponsiveUtil().getSize(24)),
                      _buildSloganText(colorScheme),
                      const SizedBox(height: 16),
                      // Loading indicator during security check
                      AdaptiveLoadingIndicator(
                        isLoading: _isSecurityCheckInProgress,
                        usePulseAnimation:
                            _performanceFlags.enableComplexAnimations,
                        color: colorScheme.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildFooter(colorScheme),
      ),
    );
  }

  /// Builds the logo container with adaptive styling
  Widget _buildLogoContainer(SplashColorScheme colorScheme) {
    final shouldSimplify = _performanceFlags.shouldUseSimplifiedUI;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.logoContainerColor,
        boxShadow: shouldSimplify
            ? null
            : [
                BoxShadow(
                  color: colorScheme.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
        border: shouldSimplify
            ? Border.all(
                color: colorScheme.decorationColor,
                width: 1,
              )
            : null,
      ),
      child: Center(
        child: _isLogoLoaded
            ? Image.asset(
                ImageConstant.oxygen7IconTransparentBackgroundSmall,
                width: ResponsiveUtil().getSize(80),
                height: ResponsiveUtil().getSize(80),
              )
            : SizedBox(
                width: ResponsiveUtil().getSize(80),
                height: ResponsiveUtil().getSize(80),
              ),
      ),
    );
  }

  /// Builds the slogan text with typewriter animation
  Widget _buildSloganText(SplashColorScheme colorScheme) {
    return Padding(
      padding: ResponsiveUtil().getPadding(left: 16, right: 16),
      child: _isTextAnimationReady
          ? DefaultTextStyle(
              style: TextStyle(
                color: colorScheme.textColor,
                fontSize: ResponsiveUtil().getFontSize(28),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              child: AnimatedTextKit(
                totalRepeatCount: 1,
                animatedTexts: [
                  TypewriterAnimatedText(
                    CommonConstants.beyondDigitalPayment.tr,
                    speed: Duration(
                      milliseconds:
                          _performanceFlags.shouldUseSimplifiedUI ? 30 : 50,
                    ),
                  ),
                ],
                onTap: () {},
              ),
            )
          : Text(
              '',
              style: TextStyle(
                color: colorScheme.textColor,
                fontSize: ResponsiveUtil().getFontSize(28),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    );
  }

  /// Builds the footer with version and copyright
  Widget _buildFooter(SplashColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CommonConstants.version.tr,
            style: TextStyle(
              color: colorScheme.secondaryTextColor,
              fontSize: ResponsiveUtil().getFontSize(12),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CommonConstants.copyright.tr,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colorScheme.textColor.withAlpha(204), // 0.8 opacity
              fontSize: ResponsiveUtil().getFontSize(12),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
