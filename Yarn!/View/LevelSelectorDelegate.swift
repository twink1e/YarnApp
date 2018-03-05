/**
 Protocol for class that handles UI updates in the Level Selector scene.
 */
protocol LevelSelectorDelegate: class {
    /// Refresh the view of all levels.
    func reloadGridView()

    /// Show alert for storage error with the given string.
    func alertStorageError(_: String)

    /// Delete the level at the given index in the collection view.
    func deleteLevel(_: Int)
}
