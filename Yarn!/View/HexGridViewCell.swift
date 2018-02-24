//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit

/**
 View for the cell in the hex grid.
 */
class HexGridViewCell: UICollectionViewCell {

    /// Make the cell as a circle.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.cornerRadius = self.frame.size.width / 2.0
    }
    /// Remove any subview in case to be used as an empty cell.
    override func prepareForReuse() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
}
