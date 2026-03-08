// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Police Station':
        return Icons.local_police_rounded;
      case 'Library':
        return Icons.local_library_rounded;
      case 'Restaurant':
        return Icons.restaurant_rounded;
      case 'Café':
        return Icons.coffee_rounded;
      case 'Park':
        return Icons.park_rounded;
      case 'Tourist Attraction':
        return Icons.attractions_rounded;
      case 'School':
        return Icons.school_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'Supermarket':
        return Icons.shopping_cart_rounded;
      case 'Embassy':
        return Icons.flag_rounded;
      case 'Government Office':
        return Icons.business_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Hospital':
        return Colors.red.shade400;
      case 'Police Station':
        return Colors.indigo.shade400;
      case 'Library':
        return Colors.brown.shade400;
      case 'Restaurant':
        return Colors.orange.shade600;
      case 'Café':
        return Colors.brown.shade300;
      case 'Park':
        return Colors.green.shade500;
      case 'Tourist Attraction':
        return Colors.purple.shade400;
      case 'School':
        return Colors.teal.shade400;
      case 'Bank':
        return Colors.blueGrey.shade500;
      case 'Hotel':
        return Colors.amber.shade700;
      case 'Supermarket':
        return Colors.green.shade700;
      case 'Embassy':
        return Colors.red.shade700;
      case 'Government Office':
        return Colors.blueGrey.shade700;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredListingsProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    // Extract first name only
    final displayName = userProfile.asData?.value?.displayName ?? '';
    final firstName = displayName.trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  // Profile avatar with initial
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMedium,
                        ),
                        children: [
                          const TextSpan(text: 'Hello, '),
                          TextSpan(
                            text: firstName.isNotEmpty ? firstName : 'there',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const TextSpan(text: ' 👋'),
                        ],
                      ),
                    ),
                  ),
                  // Notification bell (decorative)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textDark,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ── Headline ────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Discover Your Next\nDestination in Kigali',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  height: 1.25,
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  ref.read(searchQueryProvider.notifier).state = v;
                  setState(() {});
                },
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search places, restaurants…',
                  hintStyle: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMedium,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: AppColors.textMedium,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Categories label + clear ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (selectedCategory != null)
                    GestureDetector(
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state =
                              null,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Category square cards ────────────────────────────────────────
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                children: [
                  _CategorySquare(
                    label: 'All',
                    icon: Icons.apps_rounded,
                    color: AppColors.primaryBlue,
                    isSelected: selectedCategory == null,
                    onTap: () =>
                        ref.read(categoryFilterProvider.notifier).state = null,
                  ),
                  ...ListingModel.categories.map(
                    (cat) => _CategorySquare(
                      label: cat,
                      icon: _categoryIcon(cat),
                      color: _categoryColor(cat),
                      isSelected: selectedCategory == cat,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state = cat,
                    ),
                  ),
                ],
              ),
            ),

            // ── Listings label + count ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    selectedCategory ?? 'All Listings',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  filteredAsync.when(
                    data: (list) => Text(
                      '${list.length} place${list.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // ── Listings ────────────────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
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
                        'Error loading listings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                data: (listings) {
                  if (listings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.primaryBlue.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No listings found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try a different search or category',
                            style: TextStyle(color: AppColors.textMedium),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryBlue,
                    onRefresh: () async {
                      ref.invalidate(allListingsStreamProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return ListingCard(
                          listing: listing,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          ),
                        );
                      },
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
}

// ─── Category square card ────────────────────────────────────────────────────

class _CategorySquare extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySquare({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 76,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withAlpha(80)
                    : Colors.black.withAlpha(18),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 26),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
