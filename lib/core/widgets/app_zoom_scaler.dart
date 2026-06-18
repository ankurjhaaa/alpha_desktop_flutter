import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppZoomScaler extends StatefulWidget {
  final Widget child;

  const AppZoomScaler({super.key, required this.child});

  static _AppZoomScalerState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppZoomScalerState>();
  }

  @override
  State<AppZoomScaler> createState() => _AppZoomScalerState();
}

class _AppZoomScalerState extends State<AppZoomScaler> {
  double _scale = 1.0;

  double get scale => _scale;

  @override
  void initState() {
    super.initState();
    _loadScale();
  }

  Future<void> _loadScale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScale = prefs.getDouble('app_zoom_scale');
    if (savedScale != null) {
      setState(() {
        _scale = savedScale;
      });
    }
  }

  Future<void> _saveScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_zoom_scale', scale);
  }

  void zoomIn() {
    if (_scale < 2.0) {
      setState(() {
        _scale = (_scale + 0.05).clamp(0.5, 2.0);
        _saveScale(_scale);
      });
    }
  }

  void zoomOut() {
    if (_scale > 0.5) {
      setState(() {
        _scale = (_scale - 0.05).clamp(0.5, 2.0);
        _saveScale(_scale);
      });
    }
  }

  void resetZoom() {
    setState(() {
      _scale = 1.0;
      _saveScale(_scale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final originalSize = mediaQuery.size;
    final scaledSize = Size(originalSize.width / _scale, originalSize.height / _scale);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // Scaled app content
          Positioned(
            top: 0,
            left: 0,
            width: scaledSize.width,
            height: scaledSize.height,
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: scaledSize,
                ),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
