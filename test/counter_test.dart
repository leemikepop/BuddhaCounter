import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buddha_counter/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuddhaCounter Storage & Model Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        StorageService.keyCounter: 108,
      });
    });

    test('Loads initial counter value from storage', () async {
      final storage = await StorageService.init();
      expect(storage.getCounter(), 108);
    });

    test('Updates counter value in storage', () async {
      final storage = await StorageService.init();
      await storage.setCounter(1000);
      expect(storage.getCounter(), 1000);
    });

    test('Default sound effect is woodfish', () async {
      final storage = await StorageService.init();
      expect(storage.getSoundEffect(), SoundEffectType.woodfish);
    });

    test('Default UI mode is legacy', () async {
      final storage = await StorageService.init();
      expect(storage.getUiMode(), AppUiMode.legacy);
    });
  });
}
