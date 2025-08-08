import 'package:cloud_firestore/cloud_firestore.dart';

class CrudServices {
  final FirebaseFirestore service = FirebaseFirestore.instance;

  Future<void> insert(String collection, dynamic data) async {
    await service.collection(collection).doc(data.id).set(data.toJson());
  }

  // Test endpoint to insert user data into users collection
  Future<bool> insertUser({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      await service.collection('users').doc(userId).set({
        'id': userId,
        'name': name,
        'email': email,
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

  // Test endpoint to get a user from users collection
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await service.collection('users').doc(userId).get();
      if (doc.exists) {
        print('User found: ${doc.data()}');
        return doc.data() as Map<String, dynamic>;
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Future<dynamic> findOne(
  //     {required String collection, required String filed}) async {
  //   late List data = [];

  //   try {
  //     await service.collection(collection).doc(filed).get().then((value) {

  //       // login user data collect
  //       if (collection == "Users") {
  //         data.add(UserModel.fromSnapshot(value));
  //       }
  //     });
  //     return data;
  //   } on FirebaseException catch (e) {

  //     final ex = CrudFailure.code(e.code);
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: ex.message,
  //       type: 1,
  //     );

  //     throw ex;
  //   } catch (_) {
  //     final ex = CrudFailure();
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: "${ex.message}.",
  //       type: 1,
  //     );
  //     // print("exception-1 ${ex.message}");
  //     throw ex;
  //   }
  // }

  // Future<void> update({
  //   required String collection,
  //   required String documentId,
  //   required dynamic data
  // }) async {
  //     try{
  //       await service.collection(collection).doc(documentId).update(data.toJson());
  //     } on FirebaseException catch(e) {
  //       final ex = CrudFailure.code(e.code);
  //       PopupWarning.Warning(
  //         title: "Try again later",
  //         message: ex.message,
  //         type: 1
  //       );
  //       throw ex;
  //     } catch(e) {
  //       final ex = CrudFailure();
  //       PopupWarning.Warning(
  //           title: "Try again later",
  //           message: ex.message,
  //           type: 1
  //       );
  //       throw ex;
  //     }
  // }

  // Future<List<T>> findAll<T>({
  //   required String collection,
  //   required T Function(dynamic doc) fromSnapshot,
  // }) async {
  //   try {
  //     final snapshot = await service.collection(collection).get();

  //     return snapshot.docs.map<T>((doc) => fromSnapshot(doc)).toList();
  //   } catch (e) {
  //     throw e;
  //   }
  // }

  // Future<T?> findById<T>({
  //   required String collection,
  //   required String docId,
  //   required T Function(DocumentSnapshot doc) fromSnapshot,
  // }) async {
  //   try {
  //     final doc = await service.collection(collection).doc(docId).get();

  //     if (!doc.exists) return null;

  //     return fromSnapshot(doc);
  //   } on FirebaseException catch (e) {
  //     final ex = CrudFailure.code(e.code);
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: ex.message,
  //       type: 1,
  //     );
  //     throw ex;
  //   } catch (_) {
  //     final ex = CrudFailure();
  //     PopupWarning.Warning(
  //       title: "Try again later",
  //       message: "${ex.message}.",
  //       type: 1,
  //     );
  //     throw ex;
  //   }
  // }
}
