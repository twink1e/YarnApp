import UIKit

/**
 Protocol for class that handles UI updates in the Level Designer scene.
 */
protocol LevelDesignerDelegate: class {
    /// Refresh the cell at the indexPath.
    func reloadGridCells(_: [IndexPath])

    /// Refresh the entire grid.
    func reloadGridView()

    /// Show alert for storage error.
    func alertStorageError(_: String)

    /// Show UI updates for storage saving success.
    func showSaveSuccess()

    /// Update UI with the level name.
    func setName(_: String)

    /// Update UI with the yarn limit.
    func setYarnLimit(_: Int)
}
