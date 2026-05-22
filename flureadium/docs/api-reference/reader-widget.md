# ReaderWidget

The `ReadiumReaderWidget` displays publication content and handles user interactions. It wraps native Readium navigator views for each platform, including EPUB, PDF, and image-based publications such as CBZ and DIVINA.

**Source:** [reader_widget.dart](../../lib/reader_widget.dart)

## Overview

```dart
ReadiumReaderWidget(
  publication: publication,
  initialLocator: savedPosition,
  onLocatorChanged: (locator) => saveProgress(locator),
)
```

## Constructor

```dart
const ReadiumReaderWidget({
  required Publication publication,
  Widget loadingWidget = const Center(child: CircularProgressIndicator()),
  Locator? initialLocator,
  VoidCallback? onTap,
  VoidCallback? onGoLeft,
  VoidCallback? onGoRight,
  VoidCallback? onSwipe,
  Function(String)? onExternalLinkActivated,
  void Function(Locator)? onLocatorChanged,
  VoidCallback? onReady,
  List<ReaderSelectionMenuItem>? selectionMenuItems,
  Map<ReaderSelectionMenuItem, String>? selectionMenuLabels,
  Key? key,
})
```

## Parameters

### publication

**Type:** `Publication` (required)

The publication to display. Obtain from `flureadium.openPublication()`.

```dart
final pub = await flureadium.openPublication('book.epub');
ReadiumReaderWidget(publication: pub, ...)
```

The same widget also renders image-based publications:

```dart
final comic = await flureadium.openPublication('issue.cbz');
ReadiumReaderWidget(publication: comic)
```

### loadingWidget

**Type:** `Widget`
**Default:** `Center(child: CircularProgressIndicator())`

Widget shown while the native reader is loading.

```dart
ReadiumReaderWidget(
  publication: pub,
  loadingWidget: const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading book...'),
      ],
    ),
  ),
)
```

### initialLocator

**Type:** `Locator?`

Starting position in the publication. If null, starts from the beginning.

```dart
// Restore saved position
final savedJson = prefs.getString('lastPosition');
final savedLocator = savedJson != null
    ? Locator.fromJsonString(savedJson)
    : null;

ReadiumReaderWidget(
  publication: pub,
  initialLocator: savedLocator,
)
```

### onTap

**Type:** `VoidCallback?`

Called when the user taps on the reader content.

```dart
ReadiumReaderWidget(
  publication: pub,
  onTap: () {
    setState(() => _showControls = !_showControls);
  },
)
```

### onGoLeft

**Type:** `VoidCallback?`

Called when the reader navigates left (previous page).

```dart
ReadiumReaderWidget(
  publication: pub,
  onGoLeft: () {
    print('Went to previous page');
  },
)
```

### onGoRight

**Type:** `VoidCallback?`

Called when the reader navigates right (next page).

```dart
ReadiumReaderWidget(
  publication: pub,
  onGoRight: () {
    print('Went to next page');
  },
)
```

### onSwipe

**Type:** `VoidCallback?`

Called on swipe gestures.

### onExternalLinkActivated

**Type:** `Function(String)?`

Called when the native reader reports that the user activated an external link
(a URL outside the publication). The callback is delivered to the host app, so
the host decides whether to block, confirm, or launch the URL.

```dart
ReadiumReaderWidget(
  publication: pub,
  onExternalLinkActivated: (url) async {
    // Host app controls external-link policy.
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  },
)
```

Use this seam to keep reader-originated links consistent with the rest of your
app's external URL policy. For example, apps that must avoid in-app browser
surfaces during restricted-content flows can always hand the URL off to the OS
browser instead.

### onLocatorChanged

**Type:** `void Function(Locator)?`

Called when the reading position changes. Use for saving progress.

```dart
ReadiumReaderWidget(
  publication: pub,
  onLocatorChanged: (locator) {
    final progress = locator.locations?.totalProgression ?? 0;
    print('Progress: ${(progress * 100).toStringAsFixed(1)}%');

    // Save to storage
    prefs.setString('lastPosition', locator.json);
  },
)
```

### onReady

**Type:** `VoidCallback?`

Called once when the native platform view has been created and all EventChannel handlers are registered. This is the correct place to subscribe to `Flureadium.onReaderStatusChanged`, `Flureadium.onTextLocatorChanged`, and `Flureadium.onErrorEvent`.

On iOS these channels are registered lazily inside `ReadiumReaderView.init()`, which runs just before `onReady` fires. Subscribing before `onReady` causes `MissingPluginException`, which permanently closes the stream's internal `StreamController` and silently drops all subsequent events. On Android and web the channels are always ready, but using `onReady` for consistency is recommended.

```dart
class _ReaderPageState extends State<ReaderPage> {
  final _flureadium = Flureadium();
  StreamSubscription<Locator>? _locatorSub;

  void _subscribeToChannels() {
    _locatorSub?.cancel();
    _locatorSub = _flureadium.onTextLocatorChanged.listen(
      (l) => setState(() => _locator = l),
    );
  }

  @override
  void dispose() {
    _locatorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReadiumReaderWidget(
      publication: _publication!,
      onReady: _subscribeToChannels,
    );
  }
}
```

### selectionMenuItems

**Type:** `List<ReaderSelectionMenuItem>?`
**Default:** `null` (all items)

Controls which items appear in the iOS text-selection (long-press) menu, and in
what order. `null` shows all of them.

```dart
// Study only — drop Look Up and Translate:
ReadiumReaderWidget(publication: pub, selectionMenuItems: [ReaderSelectionMenuItem.study])

// Study + Look Up, no Translate:
ReadiumReaderWidget(
  publication: pub,
  selectionMenuItems: const [ReaderSelectionMenuItem.study, ReaderSelectionMenuItem.lookUp],
)
```

Platform notes: applies on **iOS only** — Android's menu shows "Study"
regardless (Look Up / Translate aren't implemented there). `translate`
additionally requires iOS 17.4+ and is hidden automatically below that even if
requested. For the full story — configuring items, localizing titles, and
running your own logic (e.g. a paywall) when Look Up / Translate is tapped — see
the [Selection Menu guide](../guides/selection-menu.md).

### selectionMenuLabels

**Type:** `Map<ReaderSelectionMenuItem, String>?`
**Default:** `null` (English defaults: "Study" / "Look Up" / "Translate")

Localized titles for the iOS selection-menu items. Provide your own text per
item; any item omitted from the map keeps its English default.

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

Wire it to your app's localizations to switch with the device language, e.g.:

```dart
selectionMenuLabels: {
  ReaderSelectionMenuItem.study: AppLocalizations.of(context)!.study,
  ReaderSelectionMenuItem.lookUp: AppLocalizations.of(context)!.lookUp,
  ReaderSelectionMenuItem.translate: AppLocalizations.of(context)!.translate,
},
```

iOS only (like `selectionMenuItems`). Combine the two to control both which
items appear and their titles.

## Interface Methods

The widget implements `ReadiumReaderWidgetInterface`, providing these methods:

### go

Navigate to a specific locator.

```dart
Future<void> go(
  Locator locator, {
  required bool isAudioBookWithText,
  bool animated = false,
})
```

### goLeft

Navigate to the previous page.

```dart
Future<void> goLeft({bool animated = true})
```

### goRight

Navigate to the next page.

```dart
Future<void> goRight({bool animated = true})
```

### skipToNext

Skip to the next chapter.

```dart
Future<void> skipToNext({bool animated = true})
```

Moves to the next TOC entry. For EPUB3 books with a nested `toc.xhtml`, this is the next chapter at any depth — not the next top-level sibling. If the current page has no TOC entry, scans the reading order to find the nearest TOC entry ahead.

### skipToPrevious

Skip to the previous chapter.

```dart
Future<void> skipToPrevious({bool animated = true})
```

Moves to the previous TOC entry, with the same hierarchical and between-entries behavior as `skipToNext`.

### getCurrentLocator

Get the current reading position.

```dart
Future<Locator?> getCurrentLocator()
```

### getLocatorFragments

Get additional locator fragments for a position.

```dart
Future<Locator?> getLocatorFragments(Locator locator)
```

### setEPUBPreferences

Apply EPUB visual preferences.

```dart
Future<void> setEPUBPreferences(EPUBPreferences preferences)
```

### setPDFPreferences

Apply PDF visual preferences.

```dart
Future<void> setPDFPreferences(PDFPreferences preferences)
```

### applyDecorations

Apply decorations to the content.

```dart
Future<void> applyDecorations(String id, List<ReaderDecoration> decorations)
```

## Platform Implementation

The widget uses platform-specific views:

### Android

Uses `PlatformViewLink` with `AndroidViewSurface` for high-performance native view embedding.

### iOS

Uses `UiKitView` for iOS native view integration.

### macOS

Uses Swift native view (similar to iOS).

### Web

Uses `ReadiumWebView` with JavaScript interop.

## Lifecycle Management

The widget automatically manages:

### Wakelock

Keeps the screen on while reading. Uses `WakelockManagerMixin`.

### Orientation

Handles device orientation changes. Uses `OrientationHandlerMixin`.

### Reader Registration

Manages widget registration with the platform. Uses `ReaderLifecycleMixin`.

## Complete Example

```dart
class ReaderScreen extends StatefulWidget {
  final String publicationPath;

  const ReaderScreen({required this.publicationPath, super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _flureadium = Flureadium();
  Publication? _publication;
  Locator? _initialLocator;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadPublication();
  }

  Future<void> _loadPublication() async {
    // Load saved position
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString('position_${widget.publicationPath}');
    if (savedJson != null) {
      _initialLocator = Locator.fromJsonString(savedJson);
    }

    // Open publication
    final pub = await _flureadium.openPublication(widget.publicationPath);
    setState(() => _publication = pub);
  }

  @override
  void dispose() {
    _flureadium.closePublication();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_publication == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Reader
          ReadiumReaderWidget(
            publication: _publication!,
            initialLocator: _initialLocator,
            loadingWidget: const Center(
              child: CircularProgressIndicator(),
            ),
            onTap: () {
              setState(() => _showControls = !_showControls);
            },
            onExternalLinkActivated: (url) {
              launchUrl(Uri.parse(url));
            },
            onLocatorChanged: (locator) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'position_${widget.publicationPath}',
                locator.json,
              );
            },
          ),

          // Overlay controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                title: Text(_publication!.metadata.title ?? 'Reader'),
                backgroundColor: Colors.black54,
              ),
            ),

          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () => _flureadium.skipToPrevious(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _flureadium.goLeft(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _flureadium.goRight(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () => _flureadium.skipToNext(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## See Also

- [Flureadium Class](flureadium-class.md) - Main API
- [Publication](publication.md) - Publication model
- [Locator](locator.md) - Position tracking
- [Preferences](preferences.md) - Visual customization
