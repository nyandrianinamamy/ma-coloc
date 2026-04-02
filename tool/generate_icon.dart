// Generates the MaColoc app launcher icon PNG.
// Run with: dart run tool/generate_icon.dart

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Fill background white
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

  // Draw rounded rectangle mask (clip corners to transparent)
  final cornerRadius = (size * 0.22).round(); // iOS-style rounded rect
  _clipRoundedCorners(image, cornerRadius);

  // Draw top emerald gradient
  for (int y = 0; y < (size * 0.45).round(); y++) {
    final t = y / (size * 0.45);
    final alpha = ((1 - t) * 40).round().clamp(0, 255);
    for (int x = 0; x < size; x++) {
      if (image.getPixel(x, y).a > 0) {
        // Blend emerald50 (#ECFDF5) over white
        final r = (255 + (236 - 255) * alpha / 255).round();
        final g = (255 + (253 - 255) * alpha / 255).round();
        final b = (255 + (245 - 255) * alpha / 255).round();
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  // Draw house icon
  final cx = size ~/ 2;
  final houseY = (size * 0.38).round();
  final hs = (size * 0.30).round(); // house scale

  // Roof
  final strokeWidth = (size * 0.032).round();
  _drawThickLine(image, cx - (hs * 0.6).round(), houseY,
      cx, houseY - (hs * 0.55).round(), strokeWidth, 0xFF1E293B);
  _drawThickLine(image, cx, houseY - (hs * 0.55).round(),
      cx + (hs * 0.6).round(), houseY, strokeWidth, 0xFF1E293B);

  // House body
  final bodyL = cx - (hs * 0.45).round();
  final bodyR = cx + (hs * 0.45).round();
  final bodyT = houseY - (hs * 0.05).round();
  final bodyB = houseY + (hs * 0.55).round();
  _drawThickRect(image, bodyL, bodyT, bodyR, bodyB, strokeWidth, 0xFF1E293B);

  // Door
  final doorW = (hs * 0.25).round();
  final doorH = (hs * 0.35).round();
  _drawThickRect(
    image,
    cx - doorW ~/ 2,
    bodyB - doorH,
    cx + doorW ~/ 2,
    bodyB,
    strokeWidth,
    0xFF1E293B,
  );

  // Three colored dots
  final dotY = (size * 0.72).round();
  final dotR = (size * 0.035).round();
  final dotSpacing = (size * 0.065).round();

  _fillCircle(image, cx - dotSpacing, dotY, dotR, 0xFF34D399); // emerald
  _fillCircle(image, cx, dotY, dotR, 0xFF2DD4BF); // teal
  _fillCircle(image, cx + dotSpacing, dotY, dotR, 0xFF60A5FA); // blue

  // Save
  final pngBytes = img.encodePng(image);
  File('assets/app_icon.png').writeAsBytesSync(pngBytes);
  print('Generated assets/app_icon.png (${pngBytes.length} bytes)');
}

void _clipRoundedCorners(img.Image image, int radius) {
  final w = image.width;
  final h = image.height;
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      // Check if point is outside the rounded rectangle
      double dx = 0, dy = 0;
      if (x < radius) dx = (radius - x).toDouble();
      if (x > w - 1 - radius) dx = (x - (w - 1 - radius)).toDouble();
      if (y < radius) dy = (radius - y).toDouble();
      if (y > h - 1 - radius) dy = (y - (h - 1 - radius)).toDouble();

      if (dx > 0 && dy > 0) {
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > radius) {
          image.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (dist > radius - 1.5) {
          // Anti-alias edge
          final alpha = ((radius - dist) / 1.5 * 255).round().clamp(0, 255);
          image.setPixelRgba(x, y, 255, 255, 255, alpha);
        }
      }
    }
  }
}

void _drawThickLine(
    img.Image image, int x0, int y0, int x1, int y1, int thickness, int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  final a = (argb >> 24) & 0xFF;
  final half = thickness ~/ 2;

  // Bresenham
  int dx = (x1 - x0).abs();
  int dy = -(y1 - y0).abs();
  int sx = x0 < x1 ? 1 : -1;
  int sy = y0 < y1 ? 1 : -1;
  int err = dx + dy;
  int cx = x0, cy = y0;

  while (true) {
    // Draw thick point
    for (int oy = -half; oy <= half; oy++) {
      for (int ox = -half; ox <= half; ox++) {
        if (ox * ox + oy * oy <= half * half) {
          final px = cx + ox;
          final py = cy + oy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixelRgba(px, py, r, g, b, a);
          }
        }
      }
    }
    if (cx == x1 && cy == y1) break;
    int e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      cx += sx;
    }
    if (e2 <= dx) {
      err += dx;
      cy += sy;
    }
  }
}

void _drawThickRect(
    img.Image image, int l, int t, int r, int b, int thickness, int argb) {
  _drawThickLine(image, l, t, r, t, thickness, argb); // top
  _drawThickLine(image, r, t, r, b, thickness, argb); // right
  _drawThickLine(image, r, b, l, b, thickness, argb); // bottom
  _drawThickLine(image, l, b, l, t, thickness, argb); // left
}

void _fillCircle(img.Image image, int cx, int cy, int radius, int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  final a = (argb >> 24) & 0xFF;

  for (int y = cy - radius; y <= cy + radius; y++) {
    for (int x = cx - radius; x <= cx + radius; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }
  }
}
