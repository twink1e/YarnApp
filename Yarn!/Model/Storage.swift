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
    static let idKey = "id"
    static let nameKey = "name"
    static let gridKey = "grid"
    static let yarnKey = "yarn"
    static let lockedKey = "locked"
    static let screenshotKey = "screenshot"
    static let createdAtKey = "createdAt"
    static let updatedAtKey = "updatedAt"
    static let levelCountKey = "levelCount"
    let jsonEncoder = JSONEncoder()
    let userDefaults = UserDefaults()
    let entityName = "Level"
    let idFormat = "id == %d"
    var managedContext: NSManagedObjectContext
    var entity: NSEntityDescription

    init(_ managedContext: NSManagedObjectContext, entity: NSEntityDescription) throws {
        self.managedContext = managedContext
        self.entity = entity
    }

    private func getImageData(_ screenshot: UIImage?) throws -> Data {
        guard let image = screenshot, let data = UIImagePNGRepresentation(image) else {
            throw StorageError.encodeError("Cannot encode image!")
        }
        return data
    }

    private func getGridString(_ grid: HexGrid) throws -> String {
        let gridData = try jsonEncoder.encode(grid)
        guard let gridString = String(data: gridData, encoding: .utf8) else {
            throw StorageError.encodeError("Cannot encode grid!")
        }
        return gridString
    }

    func levelWithId(_ id: Int) throws -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: idFormat, id)
        return try managedContext.fetch(fetchRequest).first
    }

    func saveNewLevel(_ name: String, yarnLimit: Int, grid: HexGrid, screenshot: UIImage?) throws {
        let id = userDefaults.integer(forKey: Storage.levelCountKey) + 1
        userDefaults.set(id, forKey: Storage.levelCountKey)
        let level = NSManagedObject(entity: entity,
                                    insertInto: managedContext)
        level.setValue(id, forKey: Storage.idKey)
        let date = Date()
        level.setValue(date, forKey: Storage.createdAtKey)
        try setCommonProperties(level, name: name, yarnLimit: yarnLimit, grid: grid, screenshot: screenshot)
        try managedContext.save()
    }

    func overwriteLevel(_ level: NSManagedObject, name: String, yarnLimit: Int, grid: HexGrid, screenshot: UIImage?) throws {
        try setCommonProperties(level, name: name, yarnLimit: yarnLimit, grid: grid, screenshot: screenshot)
        try managedContext.save()
    }

    private func setCommonProperties(_ level: NSManagedObject, name: String, yarnLimit: Int, grid: HexGrid, screenshot: UIImage?) throws {
        level.setValue(name, forKeyPath: Storage.nameKey)
        level.setValue(yarnLimit, forKey: Storage.yarnKey)
        level.setValue(false, forKey: Storage.lockedKey)
        try level.setValue(getGridString(grid), forKey: Storage.gridKey)
        try level.setValue(getImageData(screenshot), forKey: Storage.screenshotKey)
        let date = Date()
        level.setValue(date, forKey: Storage.updatedAtKey)
   }

    func deleteLevel(_ level: NSManagedObject) throws {
        managedContext.delete(level)
        try managedContext.save()
    }

    /// Load all saved levels as an array of `NSManagedObject` with the most recently updated level at the front.
    func loadLevels() throws -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let sort = NSSortDescriptor(key: Storage.updatedAtKey, ascending: false)
        fetchRequest.sortDescriptors = [sort]
        return try managedContext.fetch(fetchRequest)
    }
}
