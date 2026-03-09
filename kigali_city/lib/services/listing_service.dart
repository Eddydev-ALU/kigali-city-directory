import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  Stream<List<ListingModel>> getAllListings() {
    return _listings
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ListingModel.fromFirestore).toList());
  }

  Stream<List<ListingModel>> getMyListings(String uid) {
    return _listings
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map(ListingModel.fromFirestore).toList());
  }

  Future<DocumentReference> createListing(ListingModel listing) async {
    return await _listings.add(listing.toMap());
  }

  Future<void> updateListing(ListingModel listing) async {
    await _listings.doc(listing.id).update(listing.toMap());
  }

  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  Future<ListingModel?> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) return null;
    return ListingModel.fromFirestore(doc);
  }
}