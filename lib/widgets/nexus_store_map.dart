import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/map_config.dart';
import '../models/catalog_models.dart';
import '../theme/nexus_palette.dart';

class NexusStoreMap extends StatefulWidget {
  const NexusStoreMap({
    super.key,
    required this.locations,
    this.selectedName,
    this.onMarkerTap,
  });

  final List<StoreLocationSpec> locations;
  final String? selectedName;
  final ValueChanged<StoreLocationSpec>? onMarkerTap;

  @override
  State<NexusStoreMap> createState() => _NexusStoreMapState();
}

class _NexusStoreMapState extends State<NexusStoreMap> {
  final MapController _mapController = MapController();

  List<StoreLocationSpec> get _mapped =>
      widget.locations.where((s) => s.hasCoordinates).toList();

  LatLng get _initialCenter {
    final mapped = _mapped;
    if (mapped.isEmpty) {
      return const LatLng(MapConfig.defaultLat, MapConfig.defaultLng);
    }
    for (final spot in mapped) {
      if (spot.name == widget.selectedName) {
        return LatLng(spot.lat!, spot.lng!);
      }
    }
    final first = mapped.first;
    return LatLng(first.lat!, first.lng!);
  }

  void _focusStore(StoreLocationSpec spot) {
    if (!spot.hasCoordinates) return;
    _mapController.move(LatLng(spot.lat!, spot.lng!), 15);
  }

  @override
  void didUpdateWidget(covariant NexusStoreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedName != oldWidget.selectedName &&
        widget.selectedName != null) {
      for (final spot in _mapped) {
        if (spot.name == widget.selectedName) {
          _focusStore(spot);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = [
      for (final spot in _mapped)
        Marker(
          point: LatLng(spot.lat!, spot.lng!),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => widget.onMarkerTap?.call(spot),
            child: Icon(
              Icons.location_on_rounded,
              size: 40,
              color: spot.name == widget.selectedName
                  ? NexusPalette.cyan
                  : NexusPalette.violet,
            ),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: MapConfig.defaultZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                subdomains: MapConfig.tileSubdomains,
                userAgentPackageName: 'com.nexus.shop.csf_f',
              ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),
          if (_mapped.isEmpty)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Store pins will appear when catalog has coordinates',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  '© OSM · CARTO',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> openStoreDirections(StoreLocationSpec spot) async {
  if (!spot.hasCoordinates) return false;
  final uri = Uri.parse(
    'https://www.openstreetmap.org/directions?to=${spot.lat},${spot.lng}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
