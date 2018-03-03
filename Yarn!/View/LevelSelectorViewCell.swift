import UIKit
import CoreData

/**
 View for the table view cell that shows the details of a stored level.
 */
class LevelSelectorViewCell: UICollectionViewCell {
    @IBOutlet private var createdAtTag: UILabel!
    @IBOutlet private var updatedAtTag: UILabel!
    @IBOutlet private var name: UILabel!
    @IBOutlet private var screenshot: UIImageView!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var yarnLimit: UILabel!
    @IBOutlet private var updatedTime: UILabel!
    @IBOutlet private var createdTime: UILabel!
    let yarnPrefix = "Yarn limit: "
    let timeFormat = "yyyy-MM-dd HH:mm:ss"
    let formatter = DateFormatter()
    weak var levelSelectorDelegate: LevelSelectorDelegate?

    func setContent(_ level: NSManagedObject, tag: Int, delegate: LevelSelectorDelegate) {
        levelSelectorDelegate = delegate
        name.text = level.value(forKeyPath: Storage.nameKey) as? String
        if let yarnNum = level.value(forKeyPath: Storage.yarnKey) as? Int {
            yarnLimit.text = yarnPrefix + String(yarnNum)
        }
        if let screenshotData = level.value(forKeyPath: Storage.screenshotKey) as? Data {
            screenshot.image = UIImage(data: screenshotData, scale: 1.0)
        }
        let locked = level.value(forKeyPath: Storage.lockedKey) as? Bool ?? true
        guard !locked else {
            createdAtTag.isHidden = true
            updatedAtTag.isHidden = true
            deleteButton.isHidden = true
            return
        }
        formatter.dateFormat = timeFormat
        if let creation = level.value(forKeyPath: Storage.createdAtKey) as? Date {
            createdTime.text = formatter.string(from: creation)
        }
        if let update = level.value(forKeyPath: Storage.updatedAtKey) as? Date {
            updatedTime.text = formatter.string(from: update)
        }
        deleteButton.tag = tag
        deleteButton.addTarget(self, action: #selector(deleteLevel(_:)), for: .touchUpInside)

    }

    @objc func deleteLevel(_ sender: UIButton) {
        levelSelectorDelegate?.deleteLevel(sender.tag)
    }
}
