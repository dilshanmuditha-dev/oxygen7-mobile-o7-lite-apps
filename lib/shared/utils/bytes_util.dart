// ignore_for_file: unused_local_variable, dead_code, non_constant_identifier_names

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BytesUtil {
  // static Future<ui.Image> convertView(RenderBox view) async {
  //   final pixelRatio = ui.window.devicePixelRatio;
  //   final width = (view.size.width * pixelRatio).toInt();
  //   final height = (view.size.height * pixelRatio).toInt();
  //   final pictureRecorder = ui.PictureRecorder();
  //   final canvas = Canvas(pictureRecorder);
  //   view.paint(canvas, Offset.zero);
  //   final picture = pictureRecorder.endRecording();
  //   final image = await picture.toImage(width, height);
  //   return image;
  // }

  /// Default pixel ratio for print captures.
  /// 2.0 balances quality vs memory usage on most POS devices.
  /// Use 3.0 only on high-RAM devices if sharper output is needed.
  static const double _defaultPrintPixelRatio = 2.0;

  static Future<Uint8List> capturePng(GlobalKey globalKey,
      {double pixelRatio = _defaultPrintPixelRatio}) async {
    final context = globalKey.currentContext;
    if (context == null) {
      throw StateError(
          'capturePng failed: widget is not mounted (currentContext is null)');
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
          'capturePng failed: renderObject is not a RenderRepaintBoundary');
    }

    ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose(); // Release native image memory immediately
    if (byteData == null) {
      throw StateError('capturePng failed: toByteData returned null');
    }

    return byteData.buffer.asUint8List();
  }

  // static ui.Image convertView(Widget view) {
  //   final RenderRepaintBoundary boundary = RenderRepaintBoundary();
  //   final RenderBox renderBox = boundary;
  //   final RenderObject? childRenderObject = view.createRenderObject(context);
  //   final BoxConstraints constraints = BoxConstraints.tight(Size(
  //     view.getWidth(),
  //     view.getHeight(),
  //   ));

  //   boundary.child = childRenderObject;
  //   boundary.constraints = constraints;
  //   childRenderObject!.relayoutIfNeeded();
  //   final ui.Image image = renderBox.paintImage(
  //     ImageByteDecoder(),
  //     null,
  //   );
  //   return image;
  // }

  static Future<ui.Image> convertToImage(RenderBox view) async {
    // Create a `ui.PictureRecorder` to record the rendering of the view
    ui.PictureRecorder recorder = ui.PictureRecorder();

    // Create a `Canvas` using the `ui.PictureRecorder`
    ui.Canvas canvas = ui.Canvas(recorder);

    // Create a `Offset` to translate the canvas to the top-left corner of the view
    Offset offset = -view.localToGlobal(Offset.zero);

    // Create a `ContainerLayer` to manage the layer hierarchy
    ContainerLayer containerLayer = ContainerLayer();

    // Create a `PaintingContext` using the `canvas` and `containerLayer`
    PaintingContext paintContext = PaintingContext(
      containerLayer,
      view.paintBounds,
    );

    // Paint the view onto the `PaintingContext`
    view.paint(paintContext, offset);

    // End recording and obtain the `ui.Picture`
    ui.Picture picture = recorder.endRecording();

    // Convert the `ui.Picture` to a `ui.Image`
    return await picture.toImage(
      view.paintBounds.width.toInt(),
      view.paintBounds.height.toInt(),
    );
  }

  static Future<Uint8List> getBytesFromImage(ui.Image image) async {
    final width = image.width;
    final height = image.height;

    final byteData = await image.toByteData();
    if (byteData != null) {
      final bytes = byteData.buffer.asUint8List();
      final bytesPerRow = width * 4; // Assuming 32-bit RGBA image

      final rv = Uint8List(height * bytesPerRow + 4);
      rv[0] = bytesPerRow & 0xff; // xL
      rv[1] = (bytesPerRow >> 8) & 0xff; // xH
      rv[2] = height & 0xff;
      rv[3] = (height >> 8) & 0xff;

      for (var i = 0; i < height; i++) {
        rv.setRange(i * bytesPerRow + 4, (i + 1) * bytesPerRow + 4,
            bytes.sublist(i * bytesPerRow, (i + 1) * bytesPerRow));
      }

      return rv;
    }

    return Uint8List(0);
  }

  // Uint8List getBytesFromBitmap(ui.Image bitmap) {
  //   final width = bitmap.width;
  //   final height = bitmap.height;
  //   final bw = (width - 1) ~/ 8 + 1;

  //   final rv = Uint8List(height * bw + 4);
  //   rv[0] = bw & 0xff; // xL
  //   rv[1] = (bw >> 8) & 0xff; // xH
  //   rv[2] = height & 0xff;
  //   rv[3] = (height >> 8) & 0xff;

  //   final pixels = Uint32List(width * height);
  //   bitmap.getPixels(pixels, 0, width, 0, 0, width, height);

  //   for (var i = 0; i < height; i++) {
  //     for (var j = 0; j < width; j++) {
  //       final clr = pixels[width * i + j];
  //       final red = (clr & 0x00ff0000) >> 16;
  //       final green = (clr & 0x0000ff00) >> 8;
  //       final blue = clr & 0x000000ff;
  //       final gray = RGB2Gray(red, green, blue);
  //       rv[(width * i + j) ~/ 8 + 4] = (rv[(width * i + j) ~/ 8 + 4] |
  //           (gray << (7 - ((width * i + j) % 8))));
  //     }
  //   }

  //   return rv;
  // }

  static int RGB2Gray(int r, int g, int b) {
    return (false
            ? ((0.29900 * r + 0.58700 * g + 0.11400 * b) > 200)
            : ((0.29900 * r + 0.58700 * g + 0.11400 * b) < 200))
        ? 1
        : 0;
  }

  static Uint8List byteMerger(Uint8List byte1, Uint8List byte2) {
    final byte3 = Uint8List(byte1.length + byte2.length);
    byte3.setRange(0, byte1.length, byte1);
    byte3.setRange(byte1.length, byte3.length, byte2);
    return byte3;
  }

  static ui.Image getResizedImage(ui.Image image, int newHeight, int newWidth) {
    final srcWidth = image.width;
    final srcHeight = image.height;
    final scaleWidth = newWidth / srcWidth;
    final scaleHeight = newHeight / srcHeight;
    final matrix = Matrix4.identity()..scale(scaleWidth, scaleHeight);
    final resizedImage = image;
    return resizedImage;
  }

  static String bytesToString(Uint8List bytes) {
    return String.fromCharCodes(bytes);
  }
}
