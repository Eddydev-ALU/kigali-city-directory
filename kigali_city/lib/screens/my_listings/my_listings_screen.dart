import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_card.dart';
import '../directory/listing_detail_screen.dart';
import 'add_edit_listing_screen.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ListingModel listing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text(
          'Are you sure you want to delete "${listing.name}"? This cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(listingNotifierProvider.notifier)
          .deleteListing(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Listing deleted' : 'Failed to delete listing',
            ),
            backgroundColor: success ? Colors.green : Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myListingsAsync = ref.watch(myListingsStreamProvider);
    final likedListingsValue = ref.watch(likedListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentYellow,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withAlpha(160),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'My Listings'),
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Liked'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddEditListingScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Listing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: My Listings ────────────────────────────────────────────
          myListingsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading your listings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.post_add_rounded,
                        size: 80,
                        color: AppColors.primaryBlue.withAlpha(100),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No listings yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the button below to add your first listing',
                        style: TextStyle(color: AppColors.textMedium),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 88),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = listings[index];
                  return ListingCard(
                    listing: listing,
                    showActions: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: listing),
                      ),
                    ),
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditListingScreen(existingListing: listing),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, listing),
                  );
                },
              );
            },
          ),

          // ── Tab 2: Liked Listings ─────────────────────────────────────────
          likedListingsValue.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading liked listings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            data: (likedListings) {
              if (likedListings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 80,
                        color: Colors.red.shade200,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No liked listings yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap ♥ on any listing to save it here',
                        style: TextStyle(color: AppColors.textMedium),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: likedListings.length,
                itemBuilder: (context, index) {
                  final listing = likedListings[index];
                  return ListingCard(
                    listing: listing,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: listing),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
