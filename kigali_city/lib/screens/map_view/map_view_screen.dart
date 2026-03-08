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
  static const _flyToZoom = 17.0;

  // Rwanda bounding box — prevents panning outside the country.
  // SW: (-2.8389, 28.8617)  NE: (-1.0474, 30.8990)
  static final _rwandaBounds = LatLngBounds(
    const LatLng(-2.8389, 28.8617),
    const LatLng(-1.0474, 30.8990),
  );

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

  /// Fly the map to [listing] then open its info sheet.
  void _flyToAndShow(BuildContext context, ListingModel listing) {
    _mapController.move(
      LatLng(listing.latitude, listing.longitude),
      _flyToZoom,
    );
    // Small delay so the camera animation is visible before the sheet appears.
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) return;
      _showListingSheet(context, listing);
    });
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

  /// Shows a searchable list of all listings so the user can pick one to
  /// fly to. Used when there are 2 or more locations.
  void _showLocationChooser(BuildContext context, List<ListingModel> listings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _LocationChooser(
        listings: listings,
        colorForCategory: _colorForCategory,
        onSelected: (listing) {
          Navigator.of(sheetCtx).pop();
          _flyToAndShow(context, listing);
        },
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
        width: 38,
        height: 44,
        // Align the bottom-centre of the widget (the pin tip) to the
        // coordinate, so the marker points at the exact location.
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => _flyToAndShow(context, listing),
          child: Icon(Icons.location_pin, color: color, size: 38),
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
            onPressed: () => _mapController.move(_kigaliCenter, _initialZoom),
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (e, _) => Center(child: Text('Error loading map data: $e')),
        data: (listings) {
          final validListings = listings
              .where((l) => l.latitude != 0.0 || l.longitude != 0.0)
              .toList();
          final markers = _buildMarkers(listings, context);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _kigaliCenter,
                  initialZoom: _initialZoom,
                  // Zoom limits: 8 gives a full Rwanda overview; 19 is street-level.
                  minZoom: 8,
                  maxZoom: 19,
                  // Prevent the user from panning outside Rwanda.
                  cameraConstraint: CameraConstraint.containCenter(
                    bounds: _rwandaBounds,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kigali.city',
                    maxZoom: 19,
                    // Fetch higher-res tiles on retina / high-DPI screens.
                    retinaMode: MediaQuery.devicePixelRatioOf(context) >= 2,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // ── Tappable location badge ────────────────────────────────────
              Positioned(
                bottom: 16,
                left: 16,
                child: GestureDetector(
                  onTap: validListings.isEmpty
                      ? null
                      : validListings.length == 1
                      ? () => _flyToAndShow(context, validListings.first)
                      : () => _showLocationChooser(context, validListings),
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
                          '${validListings.length} location${validListings.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 13,
                          ),
                        ),
                        if (validListings.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ],
                    ),
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

// ─── Location Chooser Sheet ────────────────────────────────────────────────────

class _LocationChooser extends StatefulWidget {
  final List<ListingModel> listings;
  final Color Function(String) colorForCategory;
  final void Function(ListingModel) onSelected;

  const _LocationChooser({
    required this.listings,
    required this.colorForCategory,
    required this.onSelected,
  });

  @override
  State<_LocationChooser> createState() => _LocationChooserState();
}

class _LocationChooserState extends State<_LocationChooser> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.listings
        : widget.listings
              .where(
                (l) =>
                    l.name.toLowerCase().contains(_query) ||
                    l.category.toLowerCase().contains(_query) ||
                    l.address.toLowerCase().contains(_query),
              )
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Go to location',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search by name, category or address…',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching locations',
                      style: TextStyle(color: AppColors.textMedium),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final listing = filtered[i];
                      final color = widget.colorForCategory(listing.category);
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.location_pin,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          listing.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${listing.category} · ${listing.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        onTap: () => widget.onSelected(listing),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
