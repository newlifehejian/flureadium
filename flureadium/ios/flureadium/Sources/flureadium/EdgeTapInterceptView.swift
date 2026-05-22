//
//  EdgeTapInterceptView.swift
//  flureadium
//
//  Edge tap detection overlay for reader navigation.
//  Used by both EPUB and PDF readers to enable page navigation
//  by tapping on the left/right edges of the screen.
//

import UIKit

/// View that intercepts edge taps for page navigation when Readium's
/// gesture recognizers fail to receive touches through Flutter's platform view.
class EdgeTapInterceptView: UIView {
    /// Callback for left edge tap
    var onLeftEdgeTap: (() -> Void)?
    /// Callback for right edge tap
    var onRightEdgeTap: (() -> Void)?
    /// Callback for swipe left gesture (in edge zones)
    var onSwipeLeft: (() -> Void)?
    /// Callback for swipe right gesture (in edge zones)
    var onSwipeRight: (() -> Void)?
    /// Edge threshold in absolute points (default 44pt, iOS HIG minimum tap target)
    var edgeThresholdPoints: CGFloat = 44.0
    /// When true, hitTest returns self for any touch in an edge zone,
    /// preventing downstream gesture recognizers (e.g. DirectionalNavigationAdapter)
    /// from seeing those touches. Set to true in paginated mode regardless of
    /// whether edge tap callbacks are configured.
    var interceptEdgeTaps: Bool = false

    /// Callbacks for the custom text-selection menu items. They live here
    /// because EdgeTapInterceptView is the topmost UIView in the platform-view
    /// hierarchy, so it sits on the responder chain above the WKWebView and iOS
    /// finds these selectors here when dispatching a custom menu action.
    var onStudyAction: (() -> Void)?
    var onLookupAction: (() -> Void)?
    var onTranslateAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }

    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        addGestureRecognizer(tapGesture)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        swipeLeft.cancelsTouchesInView = false
        swipeLeft.delaysTouchesBegan = false
        swipeLeft.delaysTouchesEnded = false
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        swipeRight.cancelsTouchesInView = false
        swipeRight.delaysTouchesBegan = false
        swipeRight.delaysTouchesEnded = false
        addGestureRecognizer(swipeRight)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            onSwipeLeft?()
        case .right:
            onSwipeRight?()
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let edgeSize = edgeThresholdPoints

        if location.x < edgeSize {
            onLeftEdgeTap?()
        } else if location.x > bounds.width - edgeSize {
            onRightEdgeTap?()
        }
    }

    @objc func studyAction(_ sender: Any?) {
        onStudyAction?()
    }

    @objc func lookupAction(_ sender: Any?) {
        onLookupAction?()
    }

    @objc func translateAction(_ sender: Any?) {
        onTranslateAction?()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(studyAction(_:)):
            return onStudyAction != nil
        case #selector(lookupAction(_:)):
            return onLookupAction != nil
        case #selector(translateAction(_:)):
            return onTranslateAction != nil
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)

        let edgeSize = edgeThresholdPoints
        let isLeftEdge = point.x < edgeSize
        let isRightEdge = point.x > bounds.width - edgeSize

        if interceptEdgeTaps && (isLeftEdge || isRightEdge) {
            return self
        }

        return result
    }
}
