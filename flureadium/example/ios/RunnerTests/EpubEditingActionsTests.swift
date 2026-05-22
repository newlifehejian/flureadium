import XCTest
@testable import flureadium

final class EpubEditingActionsTests: XCTestCase {

    func testStudyAndLookupAlwaysPresent() {
        XCTAssertTrue(
            ReadiumReaderView.epubEditingActions.contains(ReadiumReaderView.studyEditingAction),
            "editingActions must contain the custom Study action"
        )
        XCTAssertTrue(
            ReadiumReaderView.epubEditingActions.contains(ReadiumReaderView.lookupEditingAction),
            "editingActions must contain the custom Look Up action"
        )
    }

    func testTranslateOnlyOniOS17_4Plus() {
        if #available(iOS 17.4, *) {
            XCTAssertEqual(ReadiumReaderView.epubEditingActions.count, 3)
            XCTAssertTrue(
                ReadiumReaderView.epubEditingActions.contains(ReadiumReaderView.translateEditingAction),
                "Translate must be present on iOS 17.4+"
            )
        } else {
            XCTAssertEqual(ReadiumReaderView.epubEditingActions.count, 2)
            XCTAssertFalse(
                ReadiumReaderView.epubEditingActions.contains(ReadiumReaderView.translateEditingAction),
                "Translate must be hidden below iOS 17.4"
            )
        }
    }

    func testSelectionMenuRespectsRequestedItemsAndOrder() {
        // Only the requested item.
        XCTAssertEqual(
            ReadiumReaderView.epubEditingActions(for: ["study"]),
            [ReadiumReaderView.studyEditingAction]
        )

        // Names match case-insensitively ("lookUp" from Dart -> lookup).
        XCTAssertEqual(
            ReadiumReaderView.epubEditingActions(for: ["lookUp"]),
            [ReadiumReaderView.lookupEditingAction]
        )

        // Order is preserved.
        XCTAssertEqual(
            ReadiumReaderView.epubEditingActions(for: ["lookUp", "study"]),
            [ReadiumReaderView.lookupEditingAction, ReadiumReaderView.studyEditingAction]
        )

        // Empty list => empty menu.
        XCTAssertTrue(ReadiumReaderView.epubEditingActions(for: []).isEmpty)

        // nil => default (all items present; Study + Look Up at least).
        XCTAssertTrue(
            ReadiumReaderView.epubEditingActions(for: nil)
                .contains(ReadiumReaderView.studyEditingAction)
        )
    }

    func testSelectionMenuLabelsOverrideTitles() {
        // No override -> the default action instance is used as-is.
        XCTAssertTrue(
            ReadiumReaderView.epubEditingActions(for: ["study"], labels: nil)
                .contains(ReadiumReaderView.studyEditingAction)
        )

        // With an override, a fresh action with the custom title is built, so it
        // is no longer the default instance (different title => not equal).
        let custom = ReadiumReaderView.epubEditingActions(for: ["study"], labels: ["study": "学习"])
        XCTAssertEqual(custom.count, 1)
        XCTAssertFalse(custom.contains(ReadiumReaderView.studyEditingAction))

        // Label keys match case-insensitively ("lookUp" applies to lookup).
        let lookup = ReadiumReaderView.epubEditingActions(for: ["lookUp"], labels: ["lookUp": "查词"])
        XCTAssertEqual(lookup.count, 1)
        XCTAssertFalse(lookup.contains(ReadiumReaderView.lookupEditingAction))
    }

    func testEpubEditingActionsUseNoNativeActions() {
        // We deliberately avoid the native actions: the native `.lookup` group
        // also drags in "Search Web", which we don't want. Look Up and Translate
        // are custom items driven by SelectionMenuPresenter instead.
        XCTAssertFalse(ReadiumReaderView.epubEditingActions.contains(.copy))
        XCTAssertFalse(ReadiumReaderView.epubEditingActions.contains(.lookup))
        XCTAssertFalse(ReadiumReaderView.epubEditingActions.contains(.translate))
        XCTAssertFalse(ReadiumReaderView.epubEditingActions.contains(.share))
    }
}
