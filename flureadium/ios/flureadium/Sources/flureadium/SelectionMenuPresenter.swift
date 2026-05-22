//
//  SelectionMenuPresenter.swift
//  flureadium
//
//  Drives the UI for the custom "Look Up" and "Translate" selection-menu items.
//
//  iOS bundles Look Up / Search Web / Translate into a single `.lookup` editing-
//  action group, and Readium can only enable or disable that whole group. To
//  show Look Up + Translate *without* Search Web, flureadium drops the native
//  group and registers its own "Look Up" / "Translate" custom EditingActions
//  (see `ReadiumReaderView.epubEditingActions`). Because they are custom items,
//  flureadium must present the system UI itself — that is what this type does.
//

import UIKit
import SwiftUI
#if canImport(Translation)
import Translation
#endif

enum SelectionMenuPresenter {

    /// Top-most presented view controller of the active foreground window scene.
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }

    /// Presents the system dictionary / Look Up panel for `text`.
    static func lookUp(_ text: String) {
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, let presenter = topViewController() else { return }
        let refVC = UIReferenceLibraryViewController(term: term)
        refVC.modalPresentationStyle = .formSheet
        presenter.present(refVC, animated: true)
    }

    /// Presents the system Translate UI for `text` using the public Translation
    /// framework (iOS 17.4+). The "Translate" menu item is hidden below 17.4
    /// (see `ReadiumReaderView.epubEditingActions`), so this is a no-op there.
    static func translate(_ text: String) {
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        #if canImport(Translation)
        if #available(iOS 17.4, *) {
            presentSystemTranslation(term)
        }
        #endif
    }

    #if canImport(Translation)
    @available(iOS 17.4, *)
    private static func presentSystemTranslation(_ text: String) {
        guard let presenter = topViewController() else { return }
        // A clear, full-screen host onto which `.translationPresentation` shows
        // the system translate sheet. Dismiss the host when the sheet closes.
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .overFullScreen
        host.rootView = AnyView(
            TranslationOverlay(text: text) { [weak host] in
                host?.dismiss(animated: false)
            }
        )
        presenter.present(host, animated: false)
    }
    #endif

}

#if canImport(Translation)
@available(iOS 17.4, *)
private struct TranslationOverlay: View {
    let text: String
    let onFinished: () -> Void
    @State private var isPresented = false

    var body: some View {
        Color.clear
            .translationPresentation(isPresented: $isPresented, text: text)
            .onAppear { isPresented = true }
            .onChange(of: isPresented) { _, newValue in
                if !newValue { onFinished() }
            }
    }
}
#endif
