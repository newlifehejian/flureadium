import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'flureadium_platform_interface.dart';

/// An implementation of [FlureadiumPlatform] that uses method channels.
class MethodChannelFlureadium extends FlureadiumPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  MethodChannel methodChannel = const MethodChannel(
    'dev.mulev.flureadium/main',
  );

  /// The event channel used to receive text Locator changes from the native platform.
  @visibleForTesting
  EventChannel textLocatorChannel = const EventChannel(
    'dev.mulev.flureadium/text-locator',
  );

  @visibleForTesting
  EventChannel timebasedStateChannel = const EventChannel(
    'dev.mulev.flureadium/timebased-state',
  );

  @visibleForTesting
  EventChannel errorEventChannel = const EventChannel(
    'dev.mulev.flureadium/error',
  );

  /// The event channel used to receive text Locator changes from the native platform.
  @visibleForTesting
  EventChannel readerStatusChannel = const EventChannel(
    'dev.mulev.flureadium/reader-status',
  );

  @visibleForTesting
  EventChannel selectionChannel = const EventChannel(
    'dev.mulev.flureadium/selection',
  );

  @visibleForTesting
  EventChannel decorationActivatedChannel = const EventChannel(
    'dev.mulev.flureadium/decoration-activated',
  );

  // 这些 reader 事件流(EventChannel)不缓存。native 侧每个 reader view 用独立的
  // EventStreamHandler，view dispose 时会发 FlutterEndOfEventStream 关闭 Dart 端
  // 的流。若用 `??=` 缓存，第一次关闭 reader 后缓存的流就永久 close，重开 reader
  // 再 listen 也收不到事件(native onListen 不再触发，新 view 的 sink 接不上)。
  // 因此每次取用都返回新的 receiveBroadcastStream，让新 view 的 handler 重新接上。
  // 用法约定：同一时刻每条流只有一个订阅者，订阅者在 view dispose 时 cancel。

  /// Fires whenever the Reader's current Locator changes.
  @override
  Stream<Locator> get onTextLocatorChanged =>
      textLocatorChannel.receiveBroadcastStream().map(
        (dynamic event) =>
            Locator.fromJson(json.decode(event) as Map<String, dynamic>)!,
      );

  /// Fires every time the native reader is about to show its edit menu for a
  /// text selection. Emitted locator's `text.highlight` carries the selected
  /// string. iOS only as of 0.12.0.
  @override
  Stream<Locator> get onSelectionChanged =>
      selectionChannel.receiveBroadcastStream().map(
        (dynamic event) =>
            Locator.fromJson(json.decode(event) as Map<String, dynamic>)!,
      );

  /// Fires when the user taps a previously-applied decoration.
  @override
  Stream<ReaderDecorationActivatedEvent> get onDecorationActivated =>
      decorationActivatedChannel.receiveBroadcastStream().map(
        (dynamic event) => ReaderDecorationActivatedEvent.fromJsonMap(
          json.decode(event) as Map<String, dynamic>,
        ),
      );

  /// Fires whenever the TimebasedNavigator changes state
  @override
  Stream<ReadiumTimebasedState> get onTimebasedPlayerStateChanged =>
      timebasedStateChannel.receiveBroadcastStream().map(
        (dynamic event) => ReadiumTimebasedState.fromJsonMap(
          json.decode(event) as Map<String, dynamic>,
        ),
      );

  @override
  Stream<ReadiumReaderStatus> get onReaderStatusChanged =>
      readerStatusChannel.receiveBroadcastStream().map(
        (dynamic event) => ReadiumReaderStatus.values.firstWhere(
          (e) => e.name == event as String,
        ),
      );

  @override
  Stream<ReadiumError> get onErrorEvent =>
      errorEventChannel.receiveBroadcastStream().map(
        (dynamic event) =>
            ReadiumError.fromJson((event as Map).cast<String, dynamic>()),
      );

  @override
  Future<Publication> loadPublication(String pubUrl) async {
    final publicationString = await methodChannel
        .invokeMethod<String>('loadPublication', [pubUrl])
        .then<String>((dynamic result) => result);

    return Publication.fromJson(
      json.decode(publicationString) as Map<String, dynamic>,
    )!;
  }

  @override
  Future<void> setCustomHeaders(Map<String, String> headers) async {
    await methodChannel.invokeMethod<void>('setCustomHeaders', {
      'httpHeaders': headers,
    });
  }

  @override
  Future<Publication> openPublication(String pubUrl) async {
    final publicationString = await methodChannel
        .invokeMethod<String>('openPublication', [pubUrl])
        .then<String>((dynamic result) => result);
    return Publication.fromJson(
      json.decode(publicationString) as Map<String, dynamic>,
    )!;
  }

  @override
  Future<void> closePublication() async =>
      await methodChannel.invokeMethod<void>('closePublication');

  @override
  Future<void> goLeft() async => await currentReaderWidget?.goLeft();

  @override
  Future<void> goRight() async => await currentReaderWidget?.goRight();

  @override
  Future<void> skipToNext() async => await currentReaderWidget?.skipToNext();

  @override
  Future<void> skipToPrevious() async =>
      await currentReaderWidget?.skipToPrevious();

  @override
  Future<bool> goToLocator(Locator locator) async =>
      await methodChannel.invokeMethod<bool>('goToLocator', [
        locator.toJson(),
      ]) ??
      false;

  @override
  Future<Locator?> getCurrentSelection() async =>
      await currentReaderWidget?.getCurrentSelection();

  @override
  Future<Uint8List?> extractPageThumbnail(
    String href,
    int maxHeight,
    int quality,
  ) async => await methodChannel.invokeMethod<Uint8List>(
    'extractPageThumbnail',
    [href, maxHeight, quality],
  );

  @override
  Future<void> setEPUBPreferences(EPUBPreferences preferences) async {
    defaultPreferences = preferences;
    await currentReaderWidget?.setEPUBPreferences(preferences);
  }

  @override
  Future<void> setNavigationConfig(ReaderNavigationConfig config) async {
    defaultNavigationConfig = config;
    await currentReaderWidget?.setNavigationConfig(config);
  }

  @override
  Future<void> applyDecorations(
    String id,
    List<ReaderDecoration> decorations,
  ) async => await currentReaderWidget?.applyDecorations(id, decorations);

  @override
  Future<void> ttsEnable(TTSPreferences? preferences, {Locator? fromLocator}) =>
      methodChannel.invokeMethod('ttsEnable', [
        preferences?.toMap(),
        fromLocator?.toJson(),
      ]);

  @override
  Future<bool> ttsCanSpeak() async {
    final result = await methodChannel.invokeMethod<bool>('ttsCanSpeak');
    return result ?? false;
  }

  @override
  Future<void> ttsRequestInstallVoice() async {
    await methodChannel.invokeMethod<void>('ttsRequestInstallVoice');
  }

  @override
  Future<void> play(Locator? fromLocator) async =>
      await methodChannel.invokeMethod('play', [fromLocator?.toJson()]);

  @override
  Future<void> stop() async => await methodChannel.invokeMethod('stop');

  @override
  Future<void> pause() async => await methodChannel.invokeMethod('pause');

  @override
  Future<void> resume() async => await methodChannel.invokeMethod('resume');

  @override
  Future<void> next() async => await methodChannel.invokeMethod('next');

  @override
  Future<void> previous() async => await methodChannel.invokeMethod('previous');

  @override
  Future<void> setDecorationStyle(
    ReaderDecorationStyle? utteranceDecoration,
    ReaderDecorationStyle? rangeDecoration,
  ) => methodChannel.invokeMethod('setDecorationStyle', [
    utteranceDecoration?.toJson(),
    rangeDecoration?.toJson(),
  ]);

  @override
  Future<List<ReaderTTSVoice>> ttsGetAvailableVoices() async {
    final voicesStr = await methodChannel.invokeMethod<List<dynamic>>(
      'ttsGetAvailableVoices',
    );
    final voices =
        voicesStr
            ?.whereType<String>()
            .map<Map<String, dynamic>>(
              (str) => json.decode(str) as Map<String, dynamic>,
            )
            .map<ReaderTTSVoice>((map) => ReaderTTSVoice.fromJsonMap(map))
            .toList() ??
        <ReaderTTSVoice>[];
    return voices;
  }

  @override
  Future<List<ReaderTTSVoice>> ttsGetSystemVoices() async {
    final voicesStr = await methodChannel.invokeMethod<List<dynamic>>(
      'ttsGetSystemVoices',
    );
    final voices =
        voicesStr
            ?.whereType<String>()
            .map<Map<String, dynamic>>(
              (str) => json.decode(str) as Map<String, dynamic>,
            )
            .map<ReaderTTSVoice>((map) => ReaderTTSVoice.fromJsonMap(map))
            .toList() ??
        <ReaderTTSVoice>[];
    return voices;
  }

  @override
  Future<void> ttsSetVoice(String voiceIdentifier, String? forLanguage) async {
    await methodChannel.invokeMethod('ttsSetVoice', [
      voiceIdentifier,
      forLanguage,
    ]);
  }

  @override
  Future<void> ttsSetPreferences(TTSPreferences preferences) =>
      methodChannel.invokeMethod('ttsSetPreferences', preferences.toMap());

  @override
  Future<String?> getLinkContent(final Link link) => methodChannel
      .invokeMethod<String>('getLinkContent', [jsonEncode(link.toJson())]);

  @override
  Future<void> audioEnable({AudioPreferences? prefs, Locator? fromLocator}) =>
      methodChannel.invokeMethod('audioEnable', [
        prefs?.toMap(),
        fromLocator?.toJson(),
      ]);

  @override
  Future<void> audioSetPreferences(AudioPreferences prefs) =>
      methodChannel.invokeMethod('audioSetPreferences', prefs.toMap());

  @override
  Future<void> audioSeekBy(Duration offset) =>
      methodChannel.invokeMethod('audioSeekBy', offset.inSeconds);

  @override
  Future<Uint8List?> renderFirstPage(
    String pubUrl, {
    int maxWidth = 600,
    int maxHeight = 800,
  }) async {
    final result = await methodChannel.invokeMethod<Uint8List>(
      'renderFirstPage',
      [pubUrl, maxWidth, maxHeight],
    );
    return result;
  }
}
