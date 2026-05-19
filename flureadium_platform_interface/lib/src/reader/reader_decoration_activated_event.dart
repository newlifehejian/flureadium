import 'dart:ui' show Rect;

import '../index.dart';

/// Fired when the user activates (taps) a previously-applied decoration in
/// the reader. The host app typically responds by showing a contextual UI
/// (e.g. "remove highlight", "open note").
class ReaderDecorationActivatedEvent {
  ReaderDecorationActivatedEvent({
    required this.group,
    required this.decorationId,
    required this.locator,
    this.rect,
  });

  factory ReaderDecorationActivatedEvent.fromJsonMap(
    final Map<String, dynamic> map,
  ) {
    final rectMap = map['rect'] as Map<String, dynamic>?;
    return ReaderDecorationActivatedEvent(
      group: map['group'] as String,
      decorationId: map['decorationId'] as String,
      locator: Locator.fromJson(map['locator'] as Map<String, dynamic>)!,
      rect: rectMap == null
          ? null
          : Rect.fromLTWH(
              (rectMap['x'] as num).toDouble(),
              (rectMap['y'] as num).toDouble(),
              (rectMap['width'] as num).toDouble(),
              (rectMap['height'] as num).toDouble(),
            ),
    );
  }

  /// The decoration group as passed to [applyDecorations] (e.g. "favorites").
  final String group;

  /// The per-item id of the activated decoration.
  final String decorationId;

  /// The original locator the decoration was applied at. `locator.text` is
  /// populated as captured at apply time.
  final Locator locator;

  /// Bounding rectangle of the activated decoration in reader-view
  /// coordinates. Useful for positioning a floating UI. Null if the native
  /// layer didn't supply one.
  final Rect? rect;

  @override
  String toString() =>
      'ReaderDecorationActivatedEvent('
      'group=$group, decorationId=$decorationId, '
      'highlight="${locator.text?.highlight}", rect=$rect)';
}
