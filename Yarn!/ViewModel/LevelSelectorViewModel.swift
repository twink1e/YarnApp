import CoreData

/**
 View model for level selector.
 Responsible for levels reading and deleting.
 **/
class LevelSelectorViewModel {
    var storage: Storage
    weak var levelSelectorDelegate: LevelSelectorDelegate?

    let storageLoadErrorMsg = "Can't load saved levels."
    let storageDeleteErrorMsg = "Can't delete level."
    var levels: [NSManagedObject] = []

    /// Init `LevelSelectorViewModel` with `delegate` responsible for display,
    /// and a context for storage.
    init(_ delegate: LevelSelectorDelegate, context: NSManagedObjectContext) {
        levelSelectorDelegate = delegate
        storage = Storage(context)
        do {
            try levels = storage.loadLevels()
        } catch {
            levelSelectorDelegate?.alertStorageError(storageLoadErrorMsg)
        }
    }

    /// Return the id of the level at the given index of `levels`.
    func levelIdAtIndex(_ index: Int) -> Int? {
        guard index < levels.count else {
            return nil
        }
        let level = levels[index]
        return level.value(forKey: Storage.idKey) as? Int
    }

    /// Delete the level at the given index of `levels`.
    /// Show error message if failed to delete.
    func deleteLevel(_ index: Int) {
        do {
            guard index < levels.count else {
                return
            }
            try storage.deleteLevel(levels[index])
            levels.remove(at: index)
        } catch {
            levelSelectorDelegate?.alertStorageError(storageDeleteErrorMsg)
        }
    }
}
