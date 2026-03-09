import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';
import 'auth_provider.dart';


final listingServiceProvider = Provider<ListingService>(
  (ref) => ListingService(),
);

final allListingsStreamProvider = StreamProvider<List<ListingModel>>((ref) {
  final uid = ref.watch(
    authStateChangesProvider.select((v) => v.asData?.value?.uid),
  );
  if (uid == null) return Stream.value([]);
  return ref.read(listingServiceProvider).getAllListings();
});


final myListingsStreamProvider = StreamProvider.autoDispose<List<ListingModel>>(
  (ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    if (user == null) return Stream.value([]);
    return ref
        .read(listingServiceProvider)
        .getMyListings(user.uid)
        .map(
          (list) => list..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  },
);


final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);


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


final likedListingsProvider = Provider<AsyncValue<List<ListingModel>>>((ref) {
  final allAsync = ref.watch(allListingsStreamProvider);
  final likedIdsAsync = ref.watch(likedListingIdsProvider);
  return allAsync.whenData((listings) {
    final likedIds = likedIdsAsync.asData?.value ?? [];
    return listings.where((l) => likedIds.contains(l.id)).toList();
  });
});
