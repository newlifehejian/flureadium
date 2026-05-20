import 'package:flutter/material.dart';
import 'package:flureadium/flureadium.dart';

import 'reader_channel.dart';

const _viewType = 'dev.mulev.flureadium/ReadiumReaderWidget';

@visibleForTesting
ReadiumReaderChannel createReadiumReaderChannel(
  int id, {
  required ValueChanged<Locator> onPageChanged,
  ValueChanged<String>? onExternalLinkActivated,
  ValueChanged<Locator>? onSelectionChanged,
  ValueChanged<ReaderDecorationActivatedEvent>? onDecorationActivated,
}) {
  return ReadiumReaderChannel(
    '$_viewType:$id',
    onPageChanged: onPageChanged,
    onExternalLinkActivated: onExternalLinkActivated,
    onSelectionChanged: onSelectionChanged,
    onDecorationActivated: onDecorationActivated,
  );
}

class ReadiumReaderWidget extends StatelessWidget {
  const ReadiumReaderWidget({
    required this.publication,
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.initialLocator,
    this.onTap,
    this.onGoLeft,
    this.onGoRight,
    this.onSwipe,
    this.onExternalLinkActivated,
    this.onLocatorChanged,
    this.onSelectionChanged,
    this.onDecorationActivated,
    this.onReady,
    super.key,
  });

  final Publication publication;
  final Widget loadingWidget;
  final Locator? initialLocator;
  final VoidCallback? onTap;
  final VoidCallback? onGoLeft;
  final VoidCallback? onGoRight;
  final VoidCallback? onSwipe;
  final Function(String)? onExternalLinkActivated;
  final void Function(Locator)? onLocatorChanged;
  final void Function(Locator)? onSelectionChanged;
  final void Function(ReaderDecorationActivatedEvent)? onDecorationActivated;

  /// Not invoked on unsupported platforms.
  final VoidCallback? onReady;

  @override
  Widget build(final BuildContext context) =>
      Center(child: Text('ReaderWidget is not available on this platform.'));
}
