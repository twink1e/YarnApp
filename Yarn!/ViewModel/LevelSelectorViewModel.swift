import CoreData

class LevelSelectorViewModel {
    let entityName = "Level"
    let storageLoadErrorMsg = "Can't load saved levels."
    let storageDeleteErrorMsg = "Can't delete level."
    var storage: Storage?
    var levels: [NSManagedObject] = []
    weak var levelSelectorDelegate: LevelSelectorDelegate?

    init(_ delegate: LevelSelectorDelegate, context: NSManagedObjectContext) {
        levelSelectorDelegate = delegate
        setStorage(context)
        do {
            try levels = storage?.loadLevels() ?? []
        } catch {
            levelSelectorDelegate?.alertStorageError(storageLoadErrorMsg)
        }
    }

    // Init core data storage with the given context.
    private func setStorage(_ managedContext: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: managedContext) else {
            levelSelectorDelegate?.alertStorageError(storageLoadErrorMsg)
            return
        }
        do {
            try self.storage = Storage(managedContext, entity: entity)
        } catch {
            levelSelectorDelegate?.alertStorageError(storageLoadErrorMsg)
        }
    }

    func levelIdAtIndex(_ index: Int) -> Int? {
        guard index < levels.count else {
            return nil
        }
        let level = levels[index]
        return level.value(forKey: Storage.idKey) as? Int
    }
    func deleteLevel(_ index: Int) {
        do {
            guard index < levels.count else {
                return
            }
            try storage?.deleteLevel(levels[index])
        } catch {
            levelSelectorDelegate?.alertStorageError(storageDeleteErrorMsg)
        }
    }
}
