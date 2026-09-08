import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

class LeafletMap extends StatefulWidget {
  final Map<String, dynamic>? location;
  final Function(Map<String, double>)? onRegionChangeComplete;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final List<Polygon>? polygons;
  final MapController? mapController;

  const LeafletMap({
    super.key,
    this.location,
    this.onRegionChangeComplete,
    this.markers,
    this.polylines,
    this.polygons,
    this.mapController,
  });

  @override
  State<LeafletMap> createState() => _LeafletMapState();
}

class _LeafletMapState extends State<LeafletMap> with TickerProviderStateMixin {
  late final MapController _mapController;
  AnimationController? _moveAnimationController;
  // Use Mumbai as default center
  final LatLng _defaultLocation = const LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  void dispose() {
    _moveAnimationController?.stop();
    _moveAnimationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LeafletMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location && widget.location != null) {
      final lat = _parseDouble(widget.location!['lat']);
      final lng = _parseDouble(widget.location!['lng']);
      if (lat != 0.0 && lng != 0.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController.camera.center.latitude.isFinite) {
            _animatedMapMove(LatLng(lat, lng), 15.0);
          }
        });
      }
    }

    if (widget.polylines != oldWidget.polylines ||
        widget.polygons != oldWidget.polygons ||
        widget.markers != oldWidget.markers) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    final List<LatLng> points = [];
    if (widget.polylines != null) {
      for (var p in widget.polylines!) {
        points.addAll(p.points);
      }
    }
    if (widget.polygons != null) {
      for (var pg in widget.polygons!) {
        points.addAll(pg.points);
      }
    }
    if (widget.markers != null) {
      for (var m in widget.markers!) {
        points.add(m.point);
      }
    }

    if (points.isNotEmpty && points.length > 1) {
      final bounds = LatLngBounds.fromPoints(points);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50.0),
            ),
          );
        }
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted || !_mapController.camera.center.latitude.isFinite) return;

    _moveAnimationController?.stop();
    _moveAnimationController?.dispose();

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _moveAnimationController = controller;

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_moveAnimationController == controller) {
          controller.dispose();
          _moveAnimationController = null;
        }
      }
    });

    controller.forward();
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialCenter = _defaultLocation;
    if (widget.location != null) {
      final lat = _parseDouble(widget.location!['lat']);
      final lng = _parseDouble(widget.location!['lng']);
      if (lat != 0.0 && lng != 0.0) {
        initialCenter = LatLng(lat, lng);
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && widget.onRegionChangeComplete != null) {
            widget.onRegionChangeComplete!({
              'latitude': position.center.latitude,
              'longitude': position.center.longitude,
              'latitudeDelta': 0.01,
              'longitudeDelta': 0.01,
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: Theme.of(context).brightness == Brightness.dark
              ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.transglobal.user_app',
          retinaMode: false,
        ),
        if (widget.polygons != null)
          PolygonLayer(
            polygons: widget.polygons!
                .where((p) => p.points.isNotEmpty)
                .toList(),
          ),
        if (widget.polylines != null)
          PolylineLayer(
            polylines: widget.polylines!
                .where((p) => p.points.isNotEmpty)
                .toList(),
          ),
        MarkerLayer(
          markers: [
            if (widget.location != null)
              Marker(
                point: LatLng(
                  _parseDouble(widget.location!['lat']),
                  _parseDouble(widget.location!['lng']),
                ),
                width: 60,
                height: 60,
                child: _buildPulsingMarker(),
              ),
            if (widget.markers != null) ...widget.markers!,
          ],
        ),
      ],
    );
  }

  Widget _buildPulsingMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
