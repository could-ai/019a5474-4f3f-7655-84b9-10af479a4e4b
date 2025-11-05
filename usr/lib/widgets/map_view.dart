import 'package:flutter/material.dart';
import '../models/location_point.dart';
import 'dart:math' as math;

class MapView extends StatefulWidget {
  final List<LocationPoint> path;
  final LocationPoint currentPosition;

  const MapView({
    super.key,
    required this.path,
    required this.currentPosition,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double _zoom = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Map Canvas
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoom = (_zoom * details.scale).clamp(0.5, 3.0);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _offset += details.delta;
                });
              },
              child: CustomPaint(
                painter: MapPainter(
                  path: widget.path,
                  currentPosition: widget.currentPosition,
                  zoom: _zoom,
                  offset: _offset,
                ),
                size: Size.infinite,
              ),
            ),
            // Zoom controls
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom * 1.2).clamp(0.5, 3.0);
                      });
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      setState(() {
                        _zoom = (_zoom / 1.2).clamp(0.5, 3.0);
                      });
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'reset_view',
                    onPressed: () {
                      setState(() {
                        _zoom = 1.0;
                        _offset = Offset.zero;
                      });
                    },
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<LocationPoint> path;
  final LocationPoint currentPosition;
  final double zoom;
  final Offset offset;

  MapPainter({
    required this.path,
    required this.currentPosition,
    required this.zoom,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFE8F4F8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (path.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // Calculate bounds
    final bounds = _calculateBounds();
    final center = Offset(size.width / 2, size.height / 2);

    // Path paint
    final pathPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw grid
    _drawGrid(canvas, size, center);

    // Draw path
    if (path.length > 1) {
      final pathPoints = path.map((point) {
        return _latLngToOffset(point, bounds, size, center);
      }).toList();

      final pathPath = Path();
      pathPath.moveTo(pathPoints[0].dx, pathPoints[0].dy);
      for (int i = 1; i < pathPoints.length; i++) {
        pathPath.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      canvas.drawPath(pathPath, pathPaint);
    }

    // Draw markers
    if (path.isNotEmpty) {
      final startPoint = _latLngToOffset(path.first, bounds, size, center);
      _drawMarker(canvas, startPoint, Colors.green, 'S');

      if (path.length > 1) {
        final endPoint = _latLngToOffset(path.last, bounds, size, center);
        _drawMarker(canvas, endPoint, Colors.red, 'E');
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, Offset center) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const gridSpacing = 50.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Start tracking to see your path',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawMarker(Canvas canvas, Offset position, Color color, String label) {
    // Outer circle
    final outerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 16, outerPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 10, innerPaint);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  _Bounds _calculateBounds() {
    double minLat = path.first.latitude;
    double maxLat = path.first.latitude;
    double minLon = path.first.longitude;
    double maxLon = path.first.longitude;

    for (final point in path) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lonPadding = (maxLon - minLon) * 0.2;

    return _Bounds(
      minLat: minLat - latPadding,
      maxLat: maxLat + latPadding,
      minLon: minLon - lonPadding,
      maxLon: maxLon + lonPadding,
    );
  }

  Offset _latLngToOffset(_Bounds bounds, Size size, Offset center) {
    final normalizedX = (currentPosition.longitude - bounds.minLon) / (bounds.maxLon - bounds.minLon);
    final normalizedY = 1 - (currentPosition.latitude - bounds.minLat) / (bounds.maxLat - bounds.minLat);

    final x = normalizedX * size.width * zoom + offset.dx;
    final y = normalizedY * size.height * zoom + offset.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(MapPainter oldDelegate) {
    return oldDelegate.path.length != path.length ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset;
  }
}

class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });
}
