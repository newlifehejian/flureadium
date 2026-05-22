/// Items that can appear in the EPUB text-selection (long-press) menu.
///
/// Pass a subset to [ReadiumReaderWidget.selectionMenuItems] to control which
/// items appear, and in what order. `null` (the default) shows all of them.
///
/// Platform notes:
/// - **iOS only.** This controls the iOS selection menu. Android's menu shows
///   "Study" regardless (Look Up / Translate are not implemented there).
/// - **[translate]** additionally requires iOS 17.4+ (the public Translation
///   framework); it is hidden automatically on older iOS even if requested.
enum ReaderSelectionMenuItem {
  /// flureadium's custom "Study" item — emits the selection to Flutter via
  /// `onSelectionChanged` and presents no native UI.
  study,

  /// System dictionary "Look Up" panel.
  lookUp,

  /// System "Translate" sheet (iOS 17.4+ only).
  translate,
}
