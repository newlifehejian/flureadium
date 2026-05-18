import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/reader/reader_lifecycle_mixin.dart';

import '../mocks/mock_platform.dart';

// Test class that uses the mixin and implements required interface
class TestLifecycleManager
    with ReaderLifecycleMixin
    implements ReadiumReaderWidgetInterface {
  @override
  Future<void> applyDecorations(
    String id,
    List<ReaderDecoration> decorations,
  ) async {}

  @override
  Future<void> go(
    Locator locator, {
    required bool isAudioBookWithText,
    bool animated = false,
  }) async {}

  @override
  Future<Locator?> getCurrentLocator() async => null;

  @override
  Future<Locator?> getCurrentSelection() async => null;

  @override
  Future<Locator?> getLocatorFragments(Locator locator) async => null;

  @override
  Future<void> goLeft({bool animated = true}) async {}

  @override
  Future<void> goRight({bool animated = true}) async {}

  @override
  Future<void> setEPUBPreferences(EPUBPreferences preferences) async {}

  @override
  Future<void> setPDFPreferences(PDFPreferences preferences) async {}

  @override
  Future<void> setNavigationConfig(ReaderNavigationConfig config) async {}

  @override
  Future<void> skipToNext({bool animated = true}) async {}

  @override
  Future<void> skipToPrevious({bool animated = true}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderLifecycleMixin', () {
    late TestLifecycleManager manager;
    late MockFlureadiumPlatform mockPlatform;

    setUp(() {
      manager = TestLifecycleManager();
      mockPlatform = MockFlureadiumPlatform();
      FlureadiumPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('provides access to platform instance', () {
      expect(manager.readium, equals(mockPlatform));
    });

    test('sets current widget interface', () {
      manager.setCurrentWidgetInterface(manager);

      expect(mockPlatform.currentReaderWidget, equals(manager));
    });

    test('cleans up widget interface', () {
      manager.setCurrentWidgetInterface(manager);
      expect(mockPlatform.currentReaderWidget, isNotNull);

      manager.cleanupWidgetInterface('test-channel');
      expect(mockPlatform.currentReaderWidget, isNull);
    });

    test('cleanup without prior set', () {
      manager.cleanupWidgetInterface('test-channel');

      // Should not throw, currentReaderWidget should remain null
      expect(mockPlatform.currentReaderWidget, isNull);
    });

    test('set can be called multiple times', () {
      manager.setCurrentWidgetInterface(manager);
      manager.setCurrentWidgetInterface(manager);

      // Last set should win
      expect(mockPlatform.currentReaderWidget, equals(manager));
    });

    test('cleanup can be called multiple times', () {
      manager.setCurrentWidgetInterface(manager);
      manager.cleanupWidgetInterface('test-channel-1');
      manager.cleanupWidgetInterface('test-channel-2');

      expect(mockPlatform.currentReaderWidget, isNull);
    });
  });
}
