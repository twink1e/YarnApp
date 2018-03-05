import CoreData
import UIKit

/**
 Errors encountered by `StorageViewModel` that requires actions from callers.
 */
enum StorageError: Error {
    case encodeError(String)
    case preloadError(String)
}

/**
 Saves, deletes, and loads levels as `NSManagedData` from core data.
 */
class Storage {
    static let entityName = "Level"
    static let idKey = "id"
    static let nameKey = "name"
    static let gridKey = "grid"
    static let yarnKey = "yarn"
    static let lockedKey = "locked"
    static let screenshotKey = "screenshot"
    static let createdAtKey = "createdAt"
    static let updatedAtKey = "updatedAt"

    // User defaults.
    let userDefaults = UserDefaults()
    static let levelCountKey = "levelCount"

    // Preload level.
    let jsonEncoder = JSONEncoder()
    let preloadStringDelimiter = "|"
    let preloadStringFieldNum = 3
    let preloadFormatErrorMsg = "Wrong format for preloaded level."

    let idFormat = "id == %d"
    let encodeImageErrorMsg = "Cannot encode image!"
    let encodeGridErrorMsg = "Cannot encode grid!"

    var managedContext: NSManagedObjectContext
    var entity: NSEntityDescription!

    /// Init Storage with the given context.
    init(_ managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext
        entity = NSEntityDescription.entity(forEntityName: Storage.entityName, in: managedContext)
    }

    /// Return the level with the given id.
    func levelWithId(_ levelId: Int) throws -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Storage.entityName)
        fetchRequest.predicate = NSPredicate(format: idFormat, levelId)
        return try managedContext.fetch(fetchRequest).first
    }

    /// Save a level with data that comes in the specified format in String.
    func savePreloadedLevel(_ dataString: String, levelId: Int, screenshotData: Data) throws {
        let data = dataString.components(separatedBy: preloadStringDelimiter)
        guard data.count == preloadStringFieldNum, let yarnLimit = Int(data[1]) else {
            throw StorageError.preloadError(preloadFormatErrorMsg)
        }
        let level = NSManagedObject(entity: entity,
                                    insertInto: managedContext)
        level.setValue(levelId, forKey: Storage.idKey)
        let date = Date()
        level.setValue(date, forKey: Storage.createdAtKey)
        try setCommonProperties(level, name: data[0], yarnLimit: yarnLimit,
                                gridString: data[2], screenshot: screenshotData, locked: true)
        try managedContext.save()
    }

    /// Save a new level and assign an id that is persistently incremental.
    func saveNewLevel(_ name: String, yarnLimit: Int, grid: HexGrid, screenshot: UIImage?) throws {
        let id = userDefaults.integer(forKey: Storage.levelCountKey) + 1
        userDefaults.set(id, forKey: Storage.levelCountKey)
        let level = NSManagedObject(entity: entity,
                                    insertInto: managedContext)
        level.setValue(id, forKey: Storage.idKey)
        let date = Date()
        level.setValue(date, forKey: Storage.createdAtKey)
        level.setValue(date, forKey: Storage.updatedAtKey)
        let gridString = try getGridString(grid)
        let screenshotData = try getImageData(screenshot)
        try setCommonProperties(level, name: name, yarnLimit: yarnLimit,
                                gridString: gridString, screenshot: screenshotData, locked: false)
        try managedContext.save()
    }

    /// Update the given level.
    func overwriteLevel(_ level: NSManagedObject, name: String, yarnLimit: Int,
                        grid: HexGrid, screenshot: UIImage?) throws {
        let gridString = try getGridString(grid)
        let screenshotData = try getImageData(screenshot)
        let date = Date()
        level.setValue(date, forKey: Storage.updatedAtKey)
        try setCommonProperties(level, name: name, yarnLimit: yarnLimit,
                                gridString: gridString, screenshot: screenshotData, locked: false)
        try managedContext.save()
    }

    func deleteLevel(_ level: NSManagedObject) throws {
        managedContext.delete(level)
        try managedContext.save()
    }

    /// Load all saved levels as an array of `NSManagedObject` with the most recently updated level at the front.
    func loadLevels() throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Storage.entityName)
        let sort = NSSortDescriptor(key: Storage.updatedAtKey, ascending: true)
        fetchRequest.sortDescriptors = [sort]
        return try managedContext.fetch(fetchRequest)
    }

    private func getImageData(_ screenshot: UIImage?) throws -> Data {
        guard let image = screenshot, let data = UIImagePNGRepresentation(image) else {
            throw StorageError.encodeError(encodeImageErrorMsg)
        }
        return data
    }

    private func getGridString(_ grid: HexGrid) throws -> String {
        let gridData = try jsonEncoder.encode(grid)
        guard let gridString = String(data: gridData, encoding: .utf8) else {
            throw StorageError.encodeError(encodeGridErrorMsg)
        }
        return gridString
    }

    // Set all properties except id, created and updated time.
    private func setCommonProperties(_ level: NSManagedObject, name: String,
                                     yarnLimit: Int, gridString: String, screenshot: Data, locked: Bool) throws {
        level.setValue(name, forKeyPath: Storage.nameKey)
        level.setValue(yarnLimit, forKey: Storage.yarnKey)
        level.setValue(locked, forKey: Storage.lockedKey)
        level.setValue(gridString, forKey: Storage.gridKey)
        level.setValue(screenshot, forKey: Storage.screenshotKey)
   }
}
