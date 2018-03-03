//  Created by Jun Ke Si on 10/2/18.
//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit

/**
 View for the table view cell that shows the details of a stored level.
 */
class LevelSelectorViewCell: UICollectionViewCell {
    @IBOutlet var createdAtTag: UILabel!
    @IBOutlet var updatedAtTag: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var screenshot: UIImageView!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var yarnLimit: NSLayoutConstraint!
    @IBOutlet var updatedTime: UILabel!
    @IBOutlet var createdTime: UILabel!
    let yarnPrefix = "Yarn limit: "
}
