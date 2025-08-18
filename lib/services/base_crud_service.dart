import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseCrudService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Generic insert method
  Future<void> insert(String collection, dynamic data) async {
    await firestore.collection(collection).doc(data.id).set(data.toJson());
  }

  // Generic insert with auto-generated ID
  Future<String?> insertAuto(
      String collection, Map<String, dynamic> data) async {
    try {
      final docRef = await firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      print('Error inserting document in $collection: $e');
      return null;
    }
  }

  // Generic get by ID
  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    try {
      final doc = await firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...(doc.data() as Map<String, dynamic>)};
      }
      return null;
    } catch (e) {
      print('Error getting document from $collection: $e');
      return null;
    }
  }

  // Generic update method
  Future<void> update(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Error updating document in $collection: $e');
      throw e;
    }
  }

  // Generic delete method
  Future<void> delete(String collection, String documentId) async {
    try {
      await firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Error deleting document from $collection: $e');
      throw e;
    }
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(
    String collection, {
    String? field,
    dynamic value,
    Query<Map<String, dynamic>>? customQuery,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection(collection);

      if (customQuery != null) {
        query = customQuery;
      } else if (field != null && value != null) {
        query = query.where(field, isEqualTo: value);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((d) => {'id': d.id, ...(d.data())}).toList();
    } catch (e) {
      print('Error querying $collection: $e');
      return [];
    }
  }

  // Generic stream method
  Stream<List<Map<String, dynamic>>> getStream(
    String collection, {
    String? field,
    dynamic value,
    Query<Map<String, dynamic>>? customQuery,
  }) {
    try {
      Query<Map<String, dynamic>> query = firestore.collection(collection);

      if (customQuery != null) {
        query = customQuery;
      } else if (field != null && value != null) {
        query = query.where(field, isEqualTo: value);
      }

      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((d) => {'id': d.id, ...(d.data())}).toList());
    } catch (e) {
      print('Error creating stream for $collection: $e');
      return Stream.value([]);
    }
  }

  // Batch operations
  WriteBatch getBatch() => firestore.batch();

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      print('Error committing batch: $e');
      throw e;
    }
  }
}
