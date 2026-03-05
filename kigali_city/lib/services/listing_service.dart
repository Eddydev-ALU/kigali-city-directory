import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  /// Stream of all listings ordered by timestamp (newest first)
  Stream<List<ListingModel>> getAllListings() {
    return _listings
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ListingModel.fromFirestore).toList());
  }

  /// Stream of listings created by a specific user.
  /// Intentionally no orderBy to avoid requiring a composite Firestore index
  /// (where + orderBy on different fields). Sorting is done in-memory by the provider.
  Stream<List<ListingModel>> getMyListings(String uid) {
    return _listings
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(ListingModel.fromFirestore).toList());
  }

  /// Create a new listing
  Future<DocumentReference> createListing(ListingModel listing) async {
    return await _listings.add(listing.toMap());
  }

  /// Update an existing listing (only fields that changed)
  Future<void> updateListing(ListingModel listing) async {
    await _listings.doc(listing.id).update(listing.toMap());
  }

  /// Delete a listing by ID
  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  /// Fetch a single listing by ID
  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }
}
