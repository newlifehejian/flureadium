package dev.mulev.flureadium.events

import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.launch
import org.readium.r2.shared.publication.Locator

/**
 * Event channel emitting the current user text selection to Flutter.
 *
 * On Android the menu is kept; selection is emitted only when the user taps
 * the "Study" item that flureadium injects via `selectionActionModeCallback`.
 */
class SelectionEventChannel(messenger: BinaryMessenger) :
    EventChannelWrapper<Locator>(messenger, "dev.mulev.flureadium/selection") {
    override fun sendEvent(data: Locator) {
        mainScope.launch {
            eventSink?.success(data.toJSON().toString())
        }
    }
}
