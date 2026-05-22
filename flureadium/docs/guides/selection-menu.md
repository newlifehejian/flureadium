# Customizing the text selection menu

When the user long-presses text in an EPUB, flureadium shows a selection menu.
This guide covers the three things you can do with it from your Flutter app:

1. [Choose which items appear](#choosing-which-items-appear) — `selectionMenuItems`
2. [Localize the item titles](#localizing-the-titles) — `selectionMenuLabels`
3. [Route Look Up / Translate to your own code](#advanced-route-look-up--translate-to-flutter) (e.g. a paywall)

## The default menu

Out of the box the iOS EPUB selection menu shows three **custom** items:

| Item | What it does |
|---|---|
| **Study** | Emits the selection to Flutter via `onSelectionChanged`; presents no native UI. |
| **Look Up** | Opens the system dictionary panel (`UIReferenceLibraryViewController`). |
| **Translate** | Opens the system Translate sheet (public `Translation` framework). |

Platform notes that apply throughout this guide:

- This is **iOS-specific.** On Android the selection menu only has "Study" (Look
  Up / Translate aren't implemented there), and the configuration below is
  accepted but ignored.
- **Translate requires iOS 17.4+.** The public translate API only exists from
  17.4; on older iOS the Translate item is hidden automatically (we don't ship
  the private `translate:` selector). See
  [platform-specific/ios.md](../platform-specific/ios.md) for the full rationale
  on why these items are custom rather than native.

## Choosing which items appear

Pass `selectionMenuItems` — a list of [`ReaderSelectionMenuItem`] values. The
list is both the **filter** and the **order**. `null` (the default) shows all
items.

```dart
// Study only — drop Look Up and Translate:
ReadiumReaderWidget(
  publication: pub,
  selectionMenuItems: const [ReaderSelectionMenuItem.study],
)

// Study + Look Up, no Translate:
ReadiumReaderWidget(
  publication: pub,
  selectionMenuItems: const [
    ReaderSelectionMenuItem.study,
    ReaderSelectionMenuItem.lookUp,
  ],
)

// Reorder — Look Up first, then Study:
ReadiumReaderWidget(
  publication: pub,
  selectionMenuItems: const [
    ReaderSelectionMenuItem.lookUp,
    ReaderSelectionMenuItem.study,
  ],
)
```

## Localizing the titles

Pass `selectionMenuLabels` — a `Map<ReaderSelectionMenuItem, String>` of title
overrides. Any item you omit keeps its English default ("Study" / "Look Up" /
"Translate").

```dart
ReadiumReaderWidget(
  publication: pub,
  selectionMenuLabels: const {
    ReaderSelectionMenuItem.study: '学习',
    ReaderSelectionMenuItem.lookUp: '查词',
    ReaderSelectionMenuItem.translate: '翻译',
  },
)
```

Hook it to your app's localizations so it follows the device language:

```dart
ReadiumReaderWidget(
  publication: pub,
  selectionMenuLabels: {
    ReaderSelectionMenuItem.study: AppLocalizations.of(context)!.study,
    ReaderSelectionMenuItem.lookUp: AppLocalizations.of(context)!.lookUp,
    ReaderSelectionMenuItem.translate: AppLocalizations.of(context)!.translate,
  },
)
```

Combine the two parameters to control both which items appear and their titles:

```dart
ReadiumReaderWidget(
  publication: pub,
  selectionMenuItems: const [ReaderSelectionMenuItem.study, ReaderSelectionMenuItem.lookUp],
  selectionMenuLabels: const {
    ReaderSelectionMenuItem.study: '学习',
    ReaderSelectionMenuItem.lookUp: '查词',
  },
)
```

> Android note: the Android "Study" label is currently hardcoded and not
> affected by `selectionMenuLabels`.

### How it flows to native

Both parameters travel in the platform view's `creationParams`
(`selectionMenuItems` / `selectionMenuLabels`, keyed by the enum name), and iOS
builds the menu in `ReadiumReaderView.epubEditingActions(for:labels:)`:
requested items, in order, each as an `EditingAction` whose title is the
override or the English default. Item names are matched case-insensitively, and
Translate is dropped on iOS < 17.4 regardless of configuration.

## Advanced: route Look Up / Translate to Flutter

> Status: **design guide / not yet wired up.** Today Look Up and Translate
> present the system UI directly. This section describes how to switch them to a
> "notify Flutter, let Flutter drive it" model — for example to run a
> **paywall / entitlement check** before the system window appears, or show your
> own UI. Nothing needs to be deleted to adopt it: the existing native
> presentation code (`SelectionMenuPresenter`) is **reused**, just triggered
> from Flutter instead of directly.

### Why this is straightforward

"Study" already works this way: it presents **no** native UI — it just emits the
selection to Flutter (`onSelectionChanged`) and your app decides what to do.
Look Up / Translate can follow the same model. flureadium already has both
channel directions, so you're just adding two messages each way:

- **Native → Flutter (notify).** Swift `invokeMethod("onSelectionChanged", …)`;
  [reader_channel.dart](../../lib/reader_channel.dart) `onMethodCall` dispatches
  it to a widget callback.
- **Flutter → Native (command).** Dart `applyDecorations(...)` →
  `_invokeMethod(...)`; `ReadiumReaderView.onMethodCall(call:result:)` handles
  the matching `case`.

### 1. iOS — notify instead of present

Add notify methods to `ReadiumReaderChannel.swift`, mirroring
`onSelectionChanged`:

```swift
func onLookupRequested(payloadJson: String?) {
    invokeMethod("onLookupRequested", arguments: payloadJson)
}
func onTranslateRequested(payloadJson: String?) {
    invokeMethod("onTranslateRequested", arguments: payloadJson)
}
```

In `ReadiumReaderView` `init`, change the Look Up / Translate wiring to emit to
Flutter instead of presenting (compare the current `onStudyAction` block):

```swift
edgeTapView.onLookupAction = { [weak self] in
    guard let self,
          let selection = self.readiumViewController.currentSelection,
          let text = selection.locator.text.highlight else { return }
    // Build {text, locator} JSON safely (e.g. JSONSerialization); illustrative:
    let payload = "{\"text\": …, \"locator\": \(selection.locator.jsonString)}"
    self.channel.onLookupRequested(payloadJson: payload)
    self.readiumViewController.clearSelection()
}
// onTranslateAction → channel.onTranslateRequested(payloadJson:) — same shape
```

`selection.locator.text.highlight` is the selected string; capture it **now**,
because the paywall round-trip is async and the selection may be gone later.

### 2. iOS — let Flutter request the native UI after its check

Keep `SelectionMenuPresenter` and expose it as commands in
`ReadiumReaderView.onMethodCall(call:result:)`:

```swift
case "presentSystemLookup":
    SelectionMenuPresenter.lookUp((call.arguments as? [Any])?.first as? String ?? "")
    result(nil)
case "presentSystemTranslate":
    SelectionMenuPresenter.translate((call.arguments as? [Any])?.first as? String ?? "")
    result(nil)
```

(Translate stays iOS 17.4+ only — `SelectionMenuPresenter.translate` is already
a no-op below that.)

### 3. Dart — channel + widget plumbing

In [reader_channel.dart](../../lib/reader_channel.dart):

```dart
// A request payload model:
class SelectionActionRequest {
  SelectionActionRequest({required this.text, this.locator});
  final String text;
  final Locator? locator;
  factory SelectionActionRequest.fromJson(Map<String, dynamic> j) =>
      SelectionActionRequest(
        text: j['text'] as String? ?? '',
        locator: j['locator'] == null
            ? null
            : Locator.fromJson(j['locator'] as Map<String, dynamic>),
      );
}

// New callbacks + handlers in onMethodCall:
case 'onLookupRequested':
  onLookupRequested?.call(SelectionActionRequest.fromJson(
      json.decode(call.arguments as String) as Map<String, dynamic>));
  return null;
case 'onTranslateRequested': // same, calling onTranslateRequested

// New command senders (mirror applyDecorations):
Future<void> presentSystemLookup(String text) =>
    _invokeMethod(_ReaderChannelMethodInvoke.presentSystemLookup, [text]);
Future<void> presentSystemTranslate(String text) =>
    _invokeMethod(_ReaderChannelMethodInvoke.presentSystemTranslate, [text]);
```

In [reader_widget.dart](../../lib/reader_widget.dart): add `onLookupRequested` /
`onTranslateRequested` widget callbacks (forward them into the channel next to
`onSelectionChanged`), and expose `presentSystemLookup` / `presentSystemTranslate`
on the widget state, delegating to `_channel` like `applyDecorations`.

### 4. Flutter app usage

```dart
ReadiumReaderWidget(
  publication: pub,
  onSelectionChanged: handleStudy, // existing
  onLookupRequested: (req) async {
    if (await entitlements.isPro) {
      await readerController.presentSystemLookup(req.text);
    } else {
      showPaywall(reason: 'lookup');
    }
  },
  onTranslateRequested: (req) async {
    if (await entitlements.isPro) {
      await readerController.presentSystemTranslate(req.text);
    } else {
      showPaywall(reason: 'translate');
    }
  },
)
```

### Notes & caveats

- **Async round-trip.** There's a small gap between the tap and the native
  window because Flutter decides in between. Cache the entitlement state on the
  Flutter side so the check is effectively synchronous for paid users.
- **Android.** Look Up / Translate are iOS-only; adding Flutter-controlled
  versions on Android means adding those menu items there first
  (`StudyActionModeCallback.kt`).
- **Alternative (allow/deny only).** If you only need to gate (not take over the
  UX), have the native handler `await` a single `invokeMethod` that returns a
  `Bool` and present only when `true`. Smaller change, less flexible.

## See also

- [ReaderWidget API reference](../api-reference/reader-widget.md) — the
  `selectionMenuItems` / `selectionMenuLabels` parameters.
- [iOS platform notes](../platform-specific/ios.md) — why the items are custom.
