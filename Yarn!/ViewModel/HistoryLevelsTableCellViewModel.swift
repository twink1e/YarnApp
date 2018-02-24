//  Copyright © 2018 nus.cs3217.a0101010. All rights reserved.
import CoreData
import UIKit

/**
 View model for `HistoryLevelsTableViewCell`.
 It takes in a `NSManagedObject` and processes the model data to what should be presented in the view.
 */
struct HistoryLevelsTableCellViewModel {
    var name: String?
    var image: UIImage?
    var createdAt: String?
    var updatedAt: String?

    init(_ object: NSManagedObject?) {
        guard let level = object else {
            return
        }
        name = level.value(forKeyPath: Storage.nameKey) as? String

        if let screenshotData = level.value(forKeyPath: Storage.screenshotKey) as? Data {
            let screenshot = UIImage(data: screenshotData, scale: 1.0)
            image = screenshot
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let creationTime = level.value(forKeyPath: Storage.createdAtKey) as? Date {
            createdAt = "Created:  " + formatter.string(from: creationTime)
        }
        if let updateTime = level.value(forKeyPath: Storage.updatedAtKey) as? Date {
            updatedAt = "Updated: " + formatter.string(from: updateTime)
        }
    }
}
