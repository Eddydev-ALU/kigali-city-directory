import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../theme/app_theme.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Set<Marker> get _markers => {
    Marker(
      markerId: MarkerId(widget.listing.id),
      position: LatLng(widget.listing.latitude, widget.listing.longitude),
      infoWindow: InfoWindow(
        title: widget.listing.name,
        snippet: widget.listing.address,
      ),
    ),
  };

  Future<void> _launchNavigation() async {
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;
    final name = Uri.encodeComponent(widget.listing.name);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  Future<void> _callNumber() async {
    final uri = Uri(scheme: 'tel', path: widget.listing.contactNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                listing.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: GoogleMap(
                onMapCreated: (c) {
                  c.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(listing.latitude, listing.longitude),
                        zoom: 15,
                      ),
                    ),
                  );
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(listing.latitude, listing.longitude),
                  zoom: 15,
                ),
                markers: _markers,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.category,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      listing.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigate button
                    ElevatedButton.icon(
                      onPressed: _launchNavigation,
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Info rows
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: listing.address,
                      iconColor: Colors.red.shade400,
                    ),
                    if (listing.contactNumber.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Contact',
                        value: listing.contactNumber,
                        iconColor: Colors.green.shade500,
                        onTap: _callNumber,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.description_rounded,
                      label: 'Description',
                      value: listing.description,
                      iconColor: AppColors.lightBlue,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.my_location_rounded,
                      label: 'Coordinates',
                      value:
                          '${listing.latitude.toStringAsFixed(6)}, ${listing.longitude.toStringAsFixed(6)}',
                      iconColor: AppColors.accentYellow,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.person_outlined,
                      label: 'Added by',
                      value: listing.createdByEmail,
                      iconColor: AppColors.textMedium,
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date Added',
                      value: DateFormat('MMMM d, y').format(listing.timestamp),
                      iconColor: AppColors.textMedium,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: onTap != null
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    decoration: onTap != null
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
