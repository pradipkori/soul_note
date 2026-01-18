import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class GuestService {
  static const String _boxName = 'guestBox';
  static const String _key = 'guestId';

  static Future<String> getOrCreateGuestId() async {
    final box = await Hive.openBox(_boxName);

    String? guestId = box.get(_key);

    if (guestId == null) {
      guestId = 'guest_${const Uuid().v4()}';
      await box.put(_key, guestId);
    }

    return guestId;
  }
}
