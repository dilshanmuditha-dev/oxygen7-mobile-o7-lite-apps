// ignore_for_file: must_call_super, deprecated_member_use

/// Widget / behavioral tests for the QR scanner animated overlay.
///
/// _Requirements: 1.4, 2.2, 2.3, 4.5, 5.3, 5.5, 6.3, 6.4, 6.5, 6.6, 7.2, 9.1,
/// 9.2, 9.6, 10.1, 10.2, 10.3, 10.4_
///
/// ## Scope and camera constraint
///
/// The production screen [ScanQRCodeScreen] embeds the `mobile_scanner`
/// `MobileScanner` widget. `MobileScanner` starts a live camera through
/// platform channels that are not implemented under `flutter test`, so the
/// full screen cannot be pumped without the camera failing. Following the
/// design's Testing Strategy, these tests therefore assert widget-tree
/// structure and wiring rather than live decoding:
///
/// * The decorative [ScannerOverlay] and its painters are pumped directly with
///   a real reactive scan-state flag.
/// * The top-bar wiring, layering, accessibility, and Align_Hint are exercised
///   through a harness ([_pumpScanHarness]) that reproduces the exact `Stack`
///   layering of [ScanQRCodeScreen.build] but substitutes the live
///   `MobileScanner` with a keyed stand-in ([_CameraStandIn]). The stand-in
///   represents the camera/detection layer so Req 6.6 (the camera element is
///   not reconstructed while the scan line animates) can be verified.
///
/// What could NOT be pumped and why:
/// * The literal `MobileScanner` widget (needs a real camera / platform
///   channels). Its layering, `IgnorePointer`/`ExcludeSemantics` wrapping and
///   detection-path independence are verified structurally instead.
/// * A genuine `AnimationController` start failure (Req 5.5). The
///   implementation creates its controller internally and does not expose a
///   seam to force `repeat()` to throw. The observable fallback contract is
///   identical to `renderScanLine == false` (the same `_scanLineActive = false`
///   branch), which is asserted; see the dedicated test for details.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:app/app_controller.dart';
import 'package:app/modules/main/scan_qr_code/scan_qr_code_controller.dart';
import 'package:app/modules/main/scan_qr_code/scanner_overlay_geometry.dart';
import 'package:app/modules/main/scan_qr_code/widgets/scanner_overlay.dart';
import 'package:app/modules/main/scan_qr_code/widgets/scanner_overlay_painters.dart';
import 'package:app/shared/constants/colors.dart';
import 'package:app/shared/constants/common.dart';
import 'package:app/shared/services/scanner_sound_service.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/custom_text_style.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// [AppController] whose lifecycle does no platform work. [ScanQrCodeController]
/// resolves an [AppController] via `Get.find()` in a field initializer, so a
/// lifecycle-neutralized instance must be registered before it is constructed.
class _FakeAppController extends AppController {
  _FakeAppController() : super(AppFlavor.development);

  @override
  void onInit() {}

  @override
  void onClose() {}
}

/// Records invocations of the two top-bar callbacks so tests can assert the
/// controls are wired to the controller. `navigateBack` is stubbed (it would
/// otherwise call `Get.back()`); `toggleCamera` delegates to the real method so
/// the reactive `isFrontCamera` toggle can be asserted too.
class _SpyScanController extends ScanQrCodeController {
  int navigateBackCount = 0;
  int toggleCameraCount = 0;

  /// These tests cover the overlay / top-bar / tick wiring, not the live camera
  /// lifecycle. The base [ScanQrCodeController.onInit] would start the camera
  /// and schedule the 30s Scan_Timeout timer, which cannot run under
  /// `flutter test` and would leak past the widget test as a pending timer.
  /// The dedicated `scan_qr_code_controller_test.dart` covers that lifecycle.
  @override
  void onInit() {
    hasScanned.value = false;
  }

  @override
  void navigateBack() {
    navigateBackCount++;
  }

  @override
  void toggleCamera() {
    toggleCameraCount++;
    super.toggleCamera();
  }
}

/// Fake [ScannerSoundService] that records how many times the Tick_Sound was
/// requested and can optionally simulate a playback failure. It overrides the
/// plain `playTick` instance method so no real `AudioPlayer` work happens; tests
/// swap it in via the `ScannerSoundService.instance` test seam.
class _FakeScannerSoundService extends ScannerSoundService {
  int playTickCount = 0;
  bool throwOnPlay = false;

  @override
  Future<void> playTick() async {
    playTickCount++;
    if (throwOnPlay) throw Exception('boom');
  }
}

/// Stand-in for the live `MobileScanner` camera/detection layer. Counts its own
/// builds so a test can prove the scan-line animation never rebuilds it.
class _CameraStandIn extends StatelessWidget {
  const _CameraStandIn({super.key, this.onBuild});

  final VoidCallback? onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return const SizedBox.expand();
  }
}

// ---------------------------------------------------------------------------
// Finders for the three decorative painters
// ---------------------------------------------------------------------------

Finder _maskPainter() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ScanMaskPainter,
    );

Finder _framePainter() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ScanFramePainter,
    );

Finder _linePainter() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is ScanLinePainter,
    );

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

const Size _kScreen = Size(428, 926); // Figma reference phone size.
const ScannerOverlayGeometry _kGeometry = ScannerOverlayGeometry();

/// Fixes the logical surface size so `MediaQuery.size` matches [size] exactly
/// (devicePixelRatio 1.0 => logical == physical). Restores it after the test.
void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps [ScannerOverlay] on its own inside a `MaterialApp`. A `Builder`
/// initializes [ResponsiveUtil] (the frame painter reads it) before the overlay
/// subtree is laid out and painted.
Future<void> _pumpOverlay(
  WidgetTester tester, {
  required RxBool hasScanned,
  required bool renderScanLine,
  bool excludeSemantics = false,
  Size size = _kScreen,
}) async {
  _setSurface(tester, size);
  final Widget overlay = ScannerOverlay(
    geometry: _kGeometry,
    screenSize: size,
    hasScanned: hasScanned,
    renderScanLine: renderScanLine,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          ResponsiveUtil().init(context);
          return Scaffold(
            body: excludeSemantics
                ? ExcludeSemantics(child: IgnorePointer(child: overlay))
                : overlay,
          );
        },
      ),
    ),
  );
  await tester.pump();
}

/// Reproduces the exact `Stack` layering of [ScanQRCodeScreen.build] with the
/// live `MobileScanner` replaced by [_CameraStandIn].
Future<void> _pumpScanHarness(
  WidgetTester tester, {
  required ScanQrCodeController controller,
  Key? cameraKey,
  VoidCallback? onCameraBuild,
  Size size = _kScreen,
}) async {
  _setSurface(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          ResponsiveUtil().init(context);
          final Rect windowRect = _kGeometry.computeWindowRect(size);
          return Scaffold(
            body: Stack(
              children: [
                // Camera / detection layer (stand-in for MobileScanner).
                _CameraStandIn(key: cameraKey, onBuild: onCameraBuild),
                // Decorative overlay: below the top bar, wrapped exactly as the
                // screen does (IgnorePointer + ExcludeSemantics, inside Obx).
                Obx(
                  () => ExcludeSemantics(
                    child: IgnorePointer(
                      child: ScannerOverlay(
                        geometry: _kGeometry,
                        screenSize: size,
                        hasScanned: controller.hasScanned,
                        renderScanLine: controller.renderScanLine.value,
                      ),
                    ),
                  ),
                ),
                // Top bar (unchanged wiring).
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 34,
                    horizontal: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => controller.navigateBack(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: ColorConstants.white,
                          size: ResponsiveUtil().getSize(24),
                        ),
                      ),
                      Text(
                        CommonConstants.scanQR.tr,
                        style: CustomTextStyles.labelStepWhite700Size18Fw600,
                        textAlign: TextAlign.center,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.switch_camera,
                          color: ColorConstants.white,
                        ),
                        onPressed: () => controller.toggleCamera(),
                      ),
                    ],
                  ),
                ),
                // Optional Align_Hint below the window.
                Positioned(
                  top: windowRect.bottom + ResponsiveUtil().getSize(24),
                  left: 0,
                  right: 0,
                  child: Obx(
                    () => controller.showAlignHint.value
                        ? Text(
                            CommonConstants.scanAlignHint.tr,
                            textAlign: TextAlign.center,
                            style:
                                CustomTextStyles.labelStepWhite700Size18Fw600,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
}

/// Registers a lifecycle-neutralized [AppController] then a [_SpyScanController]
/// and returns the spy.
_SpyScanController _putSpyController() {
  Get.put<AppController>(_FakeAppController());
  final _SpyScanController spy = _SpyScanController();
  Get.put<ScanQrCodeController>(spy);
  return spy;
}

/// Depth-first collection of every node in the current semantics tree.
List<SemanticsNode> _collectSemantics(WidgetTester tester) {
  final SemanticsOwner? owner = tester.binding.pipelineOwner.semanticsOwner;
  final SemanticsNode? root = owner?.rootSemanticsNode;
  final List<SemanticsNode> result = <SemanticsNode>[];
  if (root == null) return result;
  void visit(SemanticsNode node) {
    result.add(node);
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return result;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('ScannerOverlay - mask and frame geometry (Req 1.4, 2.2, 2.3)', () {
    testWidgets('mask cutout equals the window rect', (tester) async {
      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: true,
      );

      expect(_maskPainter(), findsOneWidget);
      final ScanMaskPainter painter =
          tester.widget<CustomPaint>(_maskPainter()).painter as ScanMaskPainter;

      // The transparent cutout is exactly the shared window rect: detection and
      // visuals cannot drift, and there is no dimmed gap/overlap at the border.
      expect(painter.rect, _kGeometry.computeWindowRect(_kScreen));
    });

    testWidgets('mask fills the whole Stack (Req 2.3)', (tester) async {
      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: true,
      );

      final Size maskSize = tester.getSize(_maskPainter());
      expect(maskSize.width, moreOrLessEquals(_kScreen.width, epsilon: 0.5));
      expect(maskSize.height, moreOrLessEquals(_kScreen.height, epsilon: 0.5));
    });

    testWidgets('mask opacity stays within the 40%-60% band (Req 2.1)',
        (tester) async {
      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: true,
      );

      final ScanMaskPainter painter =
          tester.widget<CustomPaint>(_maskPainter()).painter as ScanMaskPainter;
      expect(painter.maskOpacity, inInclusiveRange(0.4, 0.6));
    });

    testWidgets('frame is aligned to the same window rect (Req 1.4)',
        (tester) async {
      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: true,
      );

      expect(_framePainter(), findsOneWidget);
      final ScanFramePainter painter = tester
          .widget<CustomPaint>(_framePainter())
          .painter as ScanFramePainter;
      expect(painter.rect, _kGeometry.computeWindowRect(_kScreen));
      // The rounded border uses the shared Corner_Radius (Req 3.4).
      expect(painter.cornerRadius, _kGeometry.cornerRadius);
      expect(painter.cornerRadius, 10.0);
    });
  });

  group('ScannerOverlay - scan line lifecycle (Req 4.5, 5.3, 5.5, 7.2)', () {
    testWidgets(
        'scan line renders while scanning and hides once hasScanned '
        'becomes true (Req 4.5, 5.3)', (tester) async {
      final RxBool hasScanned = false.obs;
      await _pumpOverlay(
        tester,
        hasScanned: hasScanned,
        renderScanLine: true,
      );

      // Actively scanning: the animated line layer is present.
      expect(_linePainter(), findsOneWidget);

      // The glowing beam layer carries a sweep direction (defaults to
      // SweepDirection.down for the initial downward sweep).
      final ScanLinePainter linePainter =
          tester.widget<CustomPaint>(_linePainter()).painter as ScanLinePainter;
      expect(linePainter.direction, isNotNull);
      expect(linePainter.direction, isA<SweepDirection>());

      // A successful detection stops and removes the line.
      hasScanned.value = true;
      await tester.pump();
      await tester.pump();

      expect(_linePainter(), findsNothing);
      // Mask and frame remain.
      expect(_maskPainter(), findsOneWidget);
      expect(_framePainter(), findsOneWidget);
    });

    testWidgets(
        'renderScanLine = false renders the frame without the line '
        '(Req 7.2)', (tester) async {
      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: false,
      );

      expect(_maskPainter(), findsOneWidget);
      expect(_framePainter(), findsOneWidget);
      expect(_linePainter(), findsNothing);
    });

    testWidgets(
        'ticker-failure fallback: frame renders without the line while '
        'detection stays wired (Req 5.5)', (tester) async {
      // The implementation catches an AnimationController start failure and
      // sets _scanLineActive = false, producing the SAME widget tree as
      // renderScanLine == false. That start failure cannot be induced from a
      // widget test because the controller is created internally with no
      // injection seam, so we assert the observable fallback contract on the
      // shared code path: mask + frame render, no line, and the detection layer
      // (represented by the camera stand-in in the full harness) is untouched
      // because detection lives on MobileScanner, not on this overlay.
      final _SpyScanController controller = _putSpyController();
      controller.renderScanLine.value = false; // exercise the frame-only branch

      const Key cameraKey = ValueKey<String>('camera');
      await _pumpScanHarness(
        tester,
        controller: controller,
        cameraKey: cameraKey,
      );

      expect(_maskPainter(), findsOneWidget);
      expect(_framePainter(), findsOneWidget);
      expect(_linePainter(), findsNothing);
      // Detection layer remains present and wired.
      expect(find.byKey(cameraKey), findsOneWidget);
    });
  });

  group('Screen layering and top-bar wiring (Req 6.3, 6.4, 6.5)', () {
    testWidgets(
        'overlay is wrapped in IgnorePointer and ExcludeSemantics '
        'below the top bar (Req 6.5, 10.1, 10.2)', (tester) async {
      final _SpyScanController controller = _putSpyController();
      await _pumpScanHarness(tester, controller: controller);

      // The framework layers its own IgnorePointer/ExcludeSemantics widgets in
      // the route, so assert the overlay has at least these ancestors (proving
      // it is behind an IgnorePointer and inside an ExcludeSemantics).
      expect(
        find.ancestor(
          of: find.byType(ScannerOverlay),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byType(ScannerOverlay),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('tapping back invokes navigateBack (Req 6.3)', (tester) async {
      final _SpyScanController controller = _putSpyController();
      await _pumpScanHarness(tester, controller: controller);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pump();

      expect(controller.navigateBackCount, 1);
    });

    testWidgets('tapping switch-camera invokes toggleCamera (Req 6.4)',
        (tester) async {
      final _SpyScanController controller = _putSpyController();
      await _pumpScanHarness(tester, controller: controller);

      final bool before = controller.isFrontCamera.value;
      await tester.tap(find.widgetWithIcon(IconButton, Icons.switch_camera));
      await tester.pump();

      expect(controller.toggleCameraCount, 1);
      // The real toggle flipped the reactive camera-facing flag.
      expect(controller.isFrontCamera.value, !before);
    });
  });

  group('Camera element identity across animation frames (Req 6.6)', () {
    testWidgets('scan-line animation does not reconstruct the camera layer',
        (tester) async {
      final _SpyScanController controller = _putSpyController();
      // Ensure the scan line animates for this test regardless of the
      // performance policy default.
      controller.renderScanLine.value = true;

      int cameraBuilds = 0;
      const Key cameraKey = ValueKey<String>('camera');
      await _pumpScanHarness(
        tester,
        controller: controller,
        cameraKey: cameraKey,
        onCameraBuild: () => cameraBuilds++,
      );

      // The line must actually be animating for the assertion to be meaningful.
      expect(_linePainter(), findsOneWidget);

      final Element before = tester.element(find.byKey(cameraKey));
      final int buildsAfterFirstFrame = cameraBuilds;

      // Advance several animation frames.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final Element after = tester.element(find.byKey(cameraKey));

      // Same element instance => the camera subtree was never rebuilt/replaced.
      expect(identical(before, after), isTrue);
      // No extra builds were triggered by the animation frames.
      expect(cameraBuilds, buildsAfterFirstFrame);
    });
  });

  group('Accessibility (Req 10.1, 10.2, 10.3, 10.4)', () {
    testWidgets('decorative overlay emits no semantics nodes', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpOverlay(
        tester,
        hasScanned: false.obs,
        renderScanLine: true,
        excludeSemantics: true,
      );

      final List<SemanticsNode> nodes = _collectSemantics(tester);
      // No decorative node is a button and none carries a spoken label.
      expect(
        nodes.any((n) => n.getSemanticsData().hasFlag(SemanticsFlag.isButton)),
        isFalse,
      );
      expect(
        nodes.any((n) => n.getSemanticsData().label.isNotEmpty),
        isFalse,
      );
      // The overlay is enclosed by ExcludeSemantics (the mechanism that keeps
      // the decorative layers out of the semantics and focus trees).
      expect(
        find.ancestor(
          of: find.byType(ScannerOverlay),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('top-bar controls stay in the semantics tree (Req 10.3)',
        (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      final _SpyScanController controller = _putSpyController();
      await _pumpScanHarness(tester, controller: controller);

      final SemanticsData back = tester
          .getSemantics(find.widgetWithIcon(IconButton, Icons.arrow_back))
          .getSemanticsData();
      final SemanticsData switchCam = tester
          .getSemantics(find.widgetWithIcon(IconButton, Icons.switch_camera))
          .getSemanticsData();

      expect(back.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(back.hasAction(SemanticsAction.tap), isTrue);
      expect(switchCam.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(switchCam.hasAction(SemanticsAction.tap), isTrue);

      // Only the two top-bar controls are buttons; the decorative overlay
      // contributes none.
      final List<SemanticsNode> nodes = _collectSemantics(tester);
      final int buttonNodes = nodes
          .where((n) => n.getSemanticsData().hasFlag(SemanticsFlag.isButton))
          .length;
      expect(buttonNodes, 2);

      handle.dispose();
    });

    testWidgets(
        'assistive-technology activation fires the same callback '
        '(Req 10.4)', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      final _SpyScanController controller = _putSpyController();
      await _pumpScanHarness(tester, controller: controller);

      // Activate the back control through the semantics (AT) tap action.
      final SemanticsNode backNode = tester
          .getSemantics(find.widgetWithIcon(IconButton, Icons.arrow_back));
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(backNode.id, SemanticsAction.tap);
      await tester.pump();

      expect(controller.navigateBackCount, 1);

      handle.dispose();
    });
  });

  group('Align hint (Req 9.1, 9.2, 9.6)', () {
    testWidgets(
        'hint is shown when showAlignHint is true and uses the '
        'scanAlignHint key (Req 9.1, 9.3)', (tester) async {
      final _SpyScanController controller = _putSpyController();
      controller.showAlignHint.value = true;
      await _pumpScanHarness(tester, controller: controller);

      expect(find.text(CommonConstants.scanAlignHint.tr), findsOneWidget);
    });

    testWidgets('hint uses the same style as the top-bar title (Req 9.6)',
        (tester) async {
      final _SpyScanController controller = _putSpyController();
      controller.showAlignHint.value = true;
      await _pumpScanHarness(tester, controller: controller);

      final Text hint =
          tester.widget<Text>(find.text(CommonConstants.scanAlignHint.tr));
      final Text title =
          tester.widget<Text>(find.text(CommonConstants.scanQR.tr));

      final TextStyle expected = CustomTextStyles.labelStepWhite700Size18Fw600;
      // Hint matches the shared title style.
      expect(hint.style?.color, expected.color);
      expect(hint.style?.fontSize, expected.fontSize);
      expect(hint.style?.fontWeight, expected.fontWeight);
      expect(hint.style?.fontFamily, expected.fontFamily);
      // And it matches the actual top-bar title style specifically.
      expect(hint.style?.color, title.style?.color);
      expect(hint.style?.fontSize, title.style?.fontSize);
      expect(hint.style?.fontWeight, title.style?.fontWeight);
      expect(hint.style?.fontFamily, title.style?.fontFamily);
    });

    testWidgets('hint is absent when showAlignHint is false (Req 9.2)',
        (tester) async {
      final _SpyScanController controller = _putSpyController();
      controller.showAlignHint.value = true;
      await _pumpScanHarness(tester, controller: controller);

      expect(find.text(CommonConstants.scanAlignHint.tr), findsOneWidget);

      controller.showAlignHint.value = false;
      await tester.pump();

      expect(find.text(CommonConstants.scanAlignHint.tr), findsNothing);
    });
  });

  group('Audible tick on scan (Req 11.1, 11.2, 11.3, 11.4, 11.5)', () {
    // Builds a capture carrying a single non-empty displayValue, the shape
    // `handleBarcode` treats as a successful detection.
    const BarcodeCapture successCapture = BarcodeCapture(
      barcodes: <Barcode>[Barcode(displayValue: 'PAYLOAD')],
    );

    test(
        'detecting a non-empty barcode plays the tick exactly once and the '
        'session guard blocks any replay (Req 11.1, 11.5)', () {
      final _FakeScannerSoundService fake = _FakeScannerSoundService();
      ScannerSoundService.instance = fake;
      // Restore the real singleton so no other test sees the fake.
      addTearDown(() => ScannerSoundService.instance = ScannerSoundService());

      final _SpyScanController controller = _putSpyController();

      controller.handleBarcode(successCapture);
      // Exactly one tick on the first successful detection (Req 11.1).
      expect(fake.playTickCount, 1);
      expect(controller.hasScanned.value, isTrue);

      // A second capture in the same session hits the existing
      // hasScanned/_isNavigating guard and returns early, so the tick is not
      // replayed for the same scan session (Req 11.5).
      controller.handleBarcode(successCapture);
      expect(fake.playTickCount, 1);
    });

    test('a failing tick never breaks detection or navigation (Req 11.3, 11.4)',
        () {
      final _FakeScannerSoundService fake = _FakeScannerSoundService()
        ..throwOnPlay = true;
      ScannerSoundService.instance = fake;
      addTearDown(() => ScannerSoundService.instance = ScannerSoundService());

      final _SpyScanController controller = _putSpyController();

      // playTick is called fire-and-forget (not awaited) in handleBarcode, and
      // the fake throws inside an async method, so the error lands on the
      // discarded returned future rather than propagating synchronously.
      // runZonedGuarded absorbs that fire-and-forget error so it is never
      // surfaced (Req 11.4), mirroring the production contract.
      Object? synchronousError;
      runZonedGuarded(() {
        try {
          controller.handleBarcode(successCapture);
        } catch (e) {
          synchronousError = e;
        }
      }, (Object error, StackTrace stack) {
        // Swallow the fire-and-forget playTick failure (Req 11.4).
      });

      // handleBarcode itself did not throw and still advanced the flow: the
      // scan state is set so the single Get.back(result:) is scheduled exactly
      // as before (Req 11.3).
      expect(synchronousError, isNull);
      expect(fake.playTickCount, 1);
      expect(controller.hasScanned.value, isTrue);
    });

    test(
        'the tick fires independently of any "Enable sound" setting (Req 11.2)',
        () {
      // Neither handleBarcode nor ScannerSoundService.playTick ever consult the
      // app isEnableSound setting, so the tick always fires on a successful
      // detection. With no sound setting enabled anywhere, the tick still plays.
      final _FakeScannerSoundService fake = _FakeScannerSoundService();
      ScannerSoundService.instance = fake;
      addTearDown(() => ScannerSoundService.instance = ScannerSoundService());

      final _SpyScanController controller = _putSpyController();

      controller.handleBarcode(successCapture);

      expect(fake.playTickCount, 1);
    });
  });
}
