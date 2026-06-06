import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// Captures the widget wrapped by [boundaryKey]'s RepaintBoundary and shares it
/// as a PNG image using the platform share sheet.
class ShareCard {
  ShareCard._();

  static Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    String fileName = 'ramadan_tracker_card.png',
    String? text,
    double pixelRatio = 3.0,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final Uint8List bytes = byteData.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
