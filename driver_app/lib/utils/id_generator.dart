import 'dart:math';

class IdGenerator {
  static final _random = Random();
  static const _chars = '1234567890';

  static String _generateRandomString(int length) {
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
  }

  static String generateUserId() {
    return 'USR-${_generateRandomString(4)}';
  }

  static String generateDriverId() {
    return 'DRV-${_generateRandomString(4)}';
  }

  static String generateBookingId() {
    return 'BK-${_generateRandomString(4)}';
  }

  static String generateMessageId() {
    return 'MSG-${_generateRandomString(6)}';
  }
}
