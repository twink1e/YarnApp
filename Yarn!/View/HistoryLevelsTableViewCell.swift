//  Created by Jun Ke Si on 10/2/18.
//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit

/**
 View for the table view cell that shows the details of a stored level.
 */
class HistoryLevelsTableViewCell: UITableViewCell {
    @IBOutlet var createdAt: UILabel!
    @IBOutlet var updatedAt: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var overviewImage: UIImageView!
    @IBOutlet var deleteButton: UIButton!
}
