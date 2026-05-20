package dev.mulev.flureadium

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.readium.r2.shared.publication.Locator
import org.readium.r2.shared.util.AbsoluteUrl
import org.readium.r2.shared.util.toUri

internal class ReadiumReaderChannel(messenger: BinaryMessenger, name: String) :
    MethodChannel(messenger, name) {
    fun onPageChanged(locator: Locator?) =
        invokeMethod("onPageChanged", locator?.toJSON().toString())

    fun onExternalLinkActivated(url: AbsoluteUrl) =
        invokeMethod("onExternalLinkActivated", url.toString())

    // Per-view delivery for selection/decoration. The global EventChannels share
    // one channel name across all reader instances, so any instance's
    // subscribe/cancel clobbers the others. This per-view MethodChannel is tied
    // to a single reader, mirroring onPageChanged, and avoids that interference.
    fun onSelectionChanged(locator: Locator?) =
        invokeMethod("onSelectionChanged", locator?.toJSON().toString())

    fun onDecorationActivated(eventJson: String?) =
        invokeMethod("onDecorationActivated", eventJson)
}
