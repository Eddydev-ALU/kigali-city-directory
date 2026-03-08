import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../theme/app_theme.dart';
import '../directory/listing_detail_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();

  static const _kigaliCenter = LatLng(-1.9441, 30.0619);
  static const _initialZoom = 14.0;

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Hospital':
        return Colors.red;
      case 'Police Station':
        return Colors.blue.shade700;
      case 'Restaurant':
        return Colors.orange;
      case 'Café':
        return Colors.amber.shade700;
      case 'Park':
        return Colors.green.shade600;
      case 'Tourist Attraction':
        return Colors.purple;
      case 'Hotel':
        return Colors.lightBlue.shade600;
      case 'Bank':
        return Colors.cyan.shade700;
      case 'School':
        return Colors.pink.shade400;
      default:
        return AppColors.primaryBlue;
    }
  }

  void _showListingSheet(BuildContext context, ListingModel listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  color: _colorForCategory(listing.category),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    listing.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _colorForCategory(listing.category).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                listing.category,
                style: TextStyle(
                  color: _colorForCategory(listing.category),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              listing.address,
              style: const TextStyle(color: AppColors.textMedium, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('View Details'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: listing),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(
    List<ListingModel> listings,
    BuildContext context,
  ) {
    return listings.where((l) => l.latitude != 0.0 || l.longitude != 0.0).map((
      listing,
    ) {
      final color = _colorForCategory(listing.category);
      return Marker(
        point: LatLng(listing.latitude, listing.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showListingSheet(context, listing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.location_pin, color: color, size: 38)],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(allListingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            tooltip: 'Back to Kigali',
            onPressed: () {
              _mapController.move(_kigaliCenter, _initialZoom);
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (e, _) => Center(child: Text('Error loading map data: $e')),
        data: (listings) {
          final markers = _buildMarkers(listings, context);
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _kigaliCenter,
                  initialZoom: _initialZoom,
                  maxZoom: 19,
                  minZoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kigali.city',
                    maxZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Location count badge
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${listings.length} location${listings.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // OSM attribution (required by OSM terms)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(220),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 9, color: AppColors.textMedium),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
