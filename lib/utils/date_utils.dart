import 'package:intl/intl.dart';

class ChatDateUtils {
  static String formatMessageTime(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      final date = DateTime.parse(isoDate);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  static String formatDateSeparator(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return 'Today';
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else if (messageDate.year == now.year) {
        return DateFormat('MMMM d').format(date);
      } else {
        return DateFormat('MMMM d, yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  static bool shouldShowDateSeparator(
      String currentMessageDate, String? previousMessageDate) {
    if (previousMessageDate == null || currentMessageDate.isEmpty) return true;

    try {
      final current = DateTime.parse(currentMessageDate);
      final previous = DateTime.parse(previousMessageDate);

      final currentDay = DateTime(current.year, current.month, current.day);
      final previousDay = DateTime(previous.year, previous.month, previous.day);

      return !currentDay.isAtSameMomentAs(previousDay);
    } catch (e) {
      return false;
    }
  }

  static String formatLastMessageTime(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(date.year, date.month, date.day);

      if (messageDate == today) {
        return DateFormat('HH:mm').format(date);
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else if (messageDate.year == now.year) {
        return DateFormat('MMM d').format(date);
      } else {
        return DateFormat('M/d/yy').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}
