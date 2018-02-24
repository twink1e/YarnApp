//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit
import PhysicsEngine

/**
 View model that encapsulates the image of the bubble.
 */
struct HexGridCellViewModel {
    let background: UIImage?
    let color: BubbleColor?

    private let colorToImage = [
        BubbleColor.blue: #imageLiteral(resourceName: "bubble-blue"),
        BubbleColor.red: #imageLiteral(resourceName: "bubble-red"),
        BubbleColor.orange: #imageLiteral(resourceName: "bubble-orange"),
        BubbleColor.green: #imageLiteral(resourceName: "bubble-green")
    ]
    init(_ bubble: Bubble?) {
        guard let coloredBubble = bubble as? ColoredBubble else {
            background = nil
            color = nil
            return
        }
        color = coloredBubble.color
        background = colorToImage[color!]
    }
}
