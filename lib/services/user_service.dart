import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'base_crud_service.dart';

class UserService extends BaseCrudService {
  static const String collection = 'users';

  // Insert user with specific ID
  Future<bool> insertUser({
    required String userId,
    required String name,
  }) async {
    try {
      await firestore.collection(collection).doc(userId).set({
        'id': userId,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      print('User inserted successfully: $userId');
      return true;
    } catch (e) {
      print('Error inserting user: $e');
      return false;
    }
  }

  // Insert user with auto-generated ID
  Future<String?> insertUserAuto({
    required String name,
  }) async {
    try {
      final docRef = await firestore.collection(collection).add({
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'isOnline': true,
      });
      print('User inserted with auto id: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error inserting user with auto id: $e');
      return null;
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await firestore.collection(collection).doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        print('User found: $data');
        return UserModel.fromJson(data);
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Bulk fetch users by IDs
  Future<Map<String, UserModel>> getUsersByIds(List<String> ids) async {
    final result = <String, UserModel>{};
    if (ids.isEmpty) return result;

    try {
      // Firestore allows up to 10 items in 'in' queries; batch accordingly
      const batchSize = 10;
      for (var i = 0; i < ids.length; i += batchSize) {
        final slice = ids.sublist(
            i, i + batchSize > ids.length ? ids.length : i + batchSize);
        final snap = await firestore
            .collection(collection)
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          data['id'] = d.id;
          result[d.id] = UserModel.fromJson(data);
        }
      }
    } catch (e) {
      print('Error bulk fetching users: $e');
    }
    return result;
  }

  // Get users data as Map (backward compatibility)
  Future<Map<String, Map<String, dynamic>>> getUsersByIdsAsMap(
      List<String> ids) async {
    final result = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return result;

    try {
      const batchSize = 10;
      for (var i = 0; i < ids.length; i += batchSize) {
        final slice = ids.sublist(
            i, i + batchSize > ids.length ? ids.length : i + batchSize);
        final snap = await firestore
            .collection(collection)
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (final d in snap.docs) {
          result[d.id] = (d.data())..['id'] = d.id;
        }
      }
    } catch (e) {
      print('Error bulk fetching users: $e');
    }
    return result;
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await update(collection, userId, {
        'isOnline': isOnline,
      });
    } catch (e) {
      print('Error updating user online status: $e');
    }
  }
}
