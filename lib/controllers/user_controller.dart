import '../models/models.dart';
import '../services/services.dart';

class UserController {
  final UserService _userService = UserService();

  // User management methods
  Future<bool> createUser({
    required String userId,
    required String name,
  }) async {
    return await _userService.insertUser(userId: userId, name: name);
  }

  Future<String?> createUserWithAutoId({
    required String name,
  }) async {
    return await _userService.insertUserAuto(name: name);
  }

  Future<UserModel?> getUserById(String userId) async {
    return await _userService.getUser(userId);
  }

  Future<Map<String, UserModel>> getUsersByIds(List<String> ids) async {
    return await _userService.getUsersByIds(ids);
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    await _userService.updateUserOnlineStatus(userId, isOnline);
  }

  // Business logic methods
  Future<bool> isUserOnline(String userId) async {
    final user = await getUserById(userId);
    return user?.isOnline ?? false;
  }

  Future<List<UserModel>> searchUsersByName(String nameQuery) async {
    // This would require a more complex query implementation
    // For now, returning empty list as this wasn't in original implementation
    return [];
  }
}
