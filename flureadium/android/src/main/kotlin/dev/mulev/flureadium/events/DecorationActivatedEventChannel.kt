package dev.mulev.flureadium.events

import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.launch

/**
 * Event channel emitting decoration tap events to Flutter.
 *
 * Payload is a JSON string with shape:
 *   {
 *     "group": "favorites",
 *     "decorationId": "fav-...",
 *     "locator": { ... },        // Locator.toJSON() nested map
 *     "rect": { "x": ..., "y": ..., "width": ..., "height": ... }   // optional
 *   }
 */
class DecorationActivatedEventChannel(messenger: BinaryMessenger) :
    EventChannelWrapper<String>(messenger, "dev.mulev.flureadium/decoration-activated") {
    override fun sendEvent(data: String) {
        mainScope.launch {
            eventSink?.success(data)
        }
    }
}
