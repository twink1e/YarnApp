protocol LevelSelectorDelegate: class {
    func reloadGridView()
    func alertStorageError(_: String)
    func deleteLevel(_: Int)
}