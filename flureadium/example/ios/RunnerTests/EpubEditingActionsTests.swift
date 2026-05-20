import XCTest
@testable import flureadium

final class EpubEditingActionsTests: XCTestCase {

    func testEpubEditingActionsIsStudyOnly() {
        XCTAssertEqual(
            ReadiumReaderView.epubEditingActions.count,
            1,
            "editingActions must have exactly 1 item: the custom Study action"
        )
        XCTAssertTrue(
            ReadiumReaderView.epubEditingActions.contains(ReadiumReaderView.studyEditingAction),
            "editingActions must contain the custom Study action"
        )
    }

    func testEpubEditingActionsDropsSystemActions() {
        // System actions are intentionally removed so the selection menu shows
        // only "Study", matching Android's StudyActionModeCallback.
        XCTAssertFalse(
            ReadiumReaderView.epubEditingActions.contains(.copy),
            "editingActions must not include the system .copy action"
        )
        XCTAssertFalse(
            ReadiumReaderView.epubEditingActions.contains(.lookup),
            "editingActions must not include the system .lookup action"
        )
        XCTAssertFalse(
            ReadiumReaderView.epubEditingActions.contains(.translate),
            "editingActions must not include the system .translate action"
        )
    }
}
