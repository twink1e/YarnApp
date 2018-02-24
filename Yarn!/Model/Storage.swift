// Copyright © 2018 nus.cs3217.a0101010. All rights reserved.

import CoreData
import UIKit

/**
 Errors encountered by `StorageViewModel` that requires actions from callers.
 */
enum StorageError: Error {
    case encodeError(String)
}

/**
 Saves, deletes, and loads levels as `NSManagedData` from core data.
 */
class Storage {
    static let nameKey = "name"
    static let gridKey = "grid"
    static let screenshotKey = "screenshot"
    static let createdAtKey = "createdAt"
    static let updatedAtKey = "updatedAt"
    let jsonEncoder = JSONEncoder()
    let entityName = "Level"
    var storedLevels: [NSManagedObject] = []
    var managedContext: NSManagedObjectContext
    var entity: NSEntityDescription

    init(_ managedContext: NSManagedObjectContext, entity: NSEntityDescription) throws {
        self.managedContext = managedContext
        self.entity = entity
        self.storedLevels = try loadLevels()
    }

    /// Save a new level if `name` is new. Otherwise overwrites the old level with the same name with the new data.
    func saveLevel(_ name: String, grid: HexGrid, screenshot: UIImage?) throws {
        var screenshotData: Data? = nil
        if let image = screenshot {
           screenshotData = UIImagePNGRepresentation(image)
        }
        let gridData = try jsonEncoder.encode(grid)
        guard let gridString = String(data: gridData, encoding: .utf8) else {
            throw StorageError.encodeError("Cannot encode grid!")
        }
        if let oldLevelIndex = levelIndexWithName(name) {
            try overwriteLevel(oldLevelIndex, gridString: gridString, screenshot: screenshotData)
        } else {
            try saveNewLevel(name, gridString: gridString, screenshot: screenshotData)
        }
    }

    private func levelIndexWithName(_ name: String) -> Int? {
        guard let oldLevel = storedLevels.first(where: {
            $0.value(forKeyPath: Storage.nameKey) as? String == name }) else {
            return nil
        }
        return storedLevels.index(of: oldLevel)
    }

    /// Save as a new level, and insert it at the front of `storedLevels`.
    private func saveNewLevel(_ name: String, gridString: String, screenshot: Data?) throws {
        let level = NSManagedObject(entity: entity,
                                    insertInto: managedContext)
        level.setValue(name, forKeyPath: Storage.nameKey)
        level.setValue(gridString, forKey: Storage.gridKey)
        level.setValue(screenshot, forKey: Storage.screenshotKey)
        let date = Date()
        level.setValue(date, forKey: Storage.createdAtKey)
        level.setValue(date, forKey: Storage.updatedAtKey)
        try managedContext.save()
        storedLevels.insert(level, at: 0)
    }

    /// Overwrite the old level with the same name, and shift it to the front of `storedLevels`.
    private func overwriteLevel(_ levelIndex: Int, gridString: String, screenshot: Data?) throws {
        let level = storedLevels[levelIndex]
        level.setValue(gridString, forKey: Storage.gridKey)
        level.setValue(screenshot, forKey: Storage.screenshotKey)
        let date = Date()
        level.setValue(date, forKey: Storage.updatedAtKey)
        try managedContext.save()
        storedLevels.remove(at: levelIndex)
        storedLevels.insert(level, at: 0)
    }

    /// Delete the level with the given index in `storedLevels` from core data.
    func deleteLevel(_ index: Int) throws {
        managedContext.delete(storedLevels[index])
        try managedContext.save()
        storedLevels.remove(at: index)
    }

    /// Load all saved levels as an array of `NSManagedObject` with the most recently updated level at the front.
    func loadLevels() throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let sort = NSSortDescriptor(key: Storage.updatedAtKey, ascending: false)
        fetchRequest.sortDescriptors = [sort]
        return try managedContext.fetch(fetchRequest)
    }
}
