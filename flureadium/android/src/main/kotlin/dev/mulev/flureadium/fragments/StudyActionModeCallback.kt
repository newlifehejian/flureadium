package dev.mulev.flureadium.fragments

import android.view.ActionMode
import android.view.Menu
import android.view.MenuItem

/**
 * Selection ActionMode callback used by flureadium's EPUB navigator on Android.
 *
 * NOTE on Readium behaviour (verified against kotlin-toolkit 3.1.2
 * R2BasicWebView.startActionMode): once you provide a `selectionActionModeCallback`
 * via `EpubNavigatorFragment.Configuration`, the WebView's *default* items
 * (Copy / Translate / Look up / Share) are dropped entirely — only the items
 * this callback adds will show. There is no "wrap on top of default".
 *
 * --- CUSTOMISATION ENTRY POINT ---------------------------------------------
 * To change which items the menu shows, edit [populateMenu]. To handle taps,
 * edit [onActionItemClicked]. Existing per-item callbacks (e.g. `onStudy`) can
 * be added as constructor parameters in the obvious way.
 *
 * Example — add Copy back, mapping it to the system clipboard:
 *
 *   private fun populateMenu(menu: Menu) {
 *       menu.add(Menu.NONE, STUDY_MENU_ID, 1, STUDY_LABEL)
 *       menu.add(Menu.NONE, COPY_MENU_ID,  2, "Copy")
 *   }
 *   override fun onActionItemClicked(mode: ActionMode, item: MenuItem) = when (item.itemId) {
 *       STUDY_MENU_ID -> { onStudy(); mode.finish(); true }
 *       COPY_MENU_ID  -> { onCopy();  mode.finish(); true }
 *       else -> false
 *   }
 * ---------------------------------------------------------------------------
 */
class StudyActionModeCallback(
    private val onStudy: () -> Unit,
) : ActionMode.Callback {

    companion object {
        // Avoid colliding with WebView / Android built-in ids by staying high.
        const val STUDY_MENU_ID: Int = 100_001
        const val STUDY_LABEL: String = "Study"
    }

    /** Edit here to change which items appear in the selection menu. */
    private fun populateMenu(menu: Menu) {
        menu.add(Menu.NONE, STUDY_MENU_ID, Menu.FIRST, STUDY_LABEL)
    }

    override fun onCreateActionMode(mode: ActionMode, menu: Menu): Boolean {
        menu.clear()
        populateMenu(menu)
        return true
    }

    override fun onPrepareActionMode(mode: ActionMode, menu: Menu): Boolean = false

    override fun onActionItemClicked(mode: ActionMode, item: MenuItem): Boolean {
        return when (item.itemId) {
            STUDY_MENU_ID -> {
                onStudy()
                mode.finish()
                true
            }
            else -> false
        }
    }

    override fun onDestroyActionMode(mode: ActionMode) {}
}
