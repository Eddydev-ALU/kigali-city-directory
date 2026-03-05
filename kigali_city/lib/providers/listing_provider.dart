import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import 'auth_provider.dart';

// ─── Service Provider ────────────────────────────────────────────────────────

final listingServiceProvider = Provider<ListingService>(
  (ref) => ListingService(),
);

// ─── All Listings (real-time stream) ─────────────────────────────────────────
// Watch authStateChangesProvider so the stream is (re)created only after the
// Firebase Auth token is fully available. This prevents the
// permission-denied error that occurs when Firestore is queried
// before the token has propagated on first login.
final allListingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.read(listingServiceProvider).getAllListings();
});

// ─── My Listings (real-time stream, current user only) ───────────────────────

final myListingsStreamProvider = StreamProvider.autoDispose<List<ListingModel>>(
  (ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    if (user == null) return Stream.value([]);
    // getMyListings no longer uses orderBy to avoid requiring a composite
    // Firestore index. Results are sorted in-memory here instead.
    return ref
        .read(listingServiceProvider)
        .getMyListings(user.uid)
        .map(
          (list) => list..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  },
);

// ─── Search & Filter State ────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// ─── Filtered Listings ────────────────────────────────────────────────────────

final filteredListingsProvider = Provider<AsyncValue<List<ListingModel>>>((
  ref,
) {
  final allAsync = ref.watch(allListingsStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final category = ref.watch(categoryFilterProvider);

  return allAsync.whenData((listings) {
    return listings.where((l) {
      final matchesSearch =
          query.isEmpty ||
          l.name.toLowerCase().contains(query) ||
          l.address.toLowerCase().contains(query) ||
          l.description.toLowerCase().contains(query);
      final matchesCategory = category == null || l.category == category;
      return matchesSearch && matchesCategory;
    }).toList();
  });
});

// ─── Listing CRUD Operations State ───────────────────────────────────────────

class ListingOperationState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  const ListingOperationState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });
}

class ListingNotifier extends StateNotifier<ListingOperationState> {
  final ListingService _listingService;

  ListingNotifier(this._listingService) : super(const ListingOperationState());

  Future<bool> createListing(ListingModel listing) async {
    state = const ListingOperationState(isLoading: true);
    try {
      await _listingService.createListing(listing);
      state = const ListingOperationState(success: true);
      return true;
    } on Exception catch (e) {
      state = ListingOperationState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateListing(ListingModel listing) async {
    state = const ListingOperationState(isLoading: true);
    try {
      await _listingService.updateListing(listing);
      state = const ListingOperationState(success: true);
      return true;
    } on Exception catch (e) {
      state = ListingOperationState(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteListing(String id) async {
    state = const ListingOperationState(isLoading: true);
    try {
      await _listingService.deleteListing(id);
      state = const ListingOperationState(success: true);
      return true;
    } on Exception catch (e) {
      state = ListingOperationState(errorMessage: e.toString());
      return false;
    }
  }

  void reset() => state = const ListingOperationState();
}

final listingNotifierProvider =
    StateNotifierProvider<ListingNotifier, ListingOperationState>((ref) {
      return ListingNotifier(ref.read(listingServiceProvider));
    });

// ─── Liked Listings (derived from allListings + likedIds) ────────────────────

final likedListingsProvider = Provider<AsyncValue<List<ListingModel>>>((ref) {
  final allAsync = ref.watch(allListingsStreamProvider);
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  return allAsync.whenData((listings) {
    final likedIds = likedIdsAsync.asData?.value ?? [];
    return listings.where((l) => likedIds.contains(l.id)).toList();
  });
});
