//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit
import PhysicsEngine

/**
 View model that encapsulates the image of the bubble.
 */
struct HexGridCellViewModel {
    var background: UIImage?
    var type: BubbleType?
    var color: BubbleColor = .noColor
    var power: BubblePower = .noPower

    private let colorToImage = [
        BubbleColor.blue: #imageLiteral(resourceName: "bubble-blue"),
        BubbleColor.red: #imageLiteral(resourceName: "bubble-red"),
        BubbleColor.orange: #imageLiteral(resourceName: "bubble-orange"),
        BubbleColor.green: #imageLiteral(resourceName: "bubble-green")
    ]
    private let powerToImage = [
        BubblePower.bomb: #imageLiteral(resourceName: "bubble-bomb"),
        BubblePower.indestructible: #imageLiteral(resourceName: "bubble-indestructible"),
        BubblePower.magnetic: #imageLiteral(resourceName: "bubble-magnetic"),
        BubblePower.lightning: #imageLiteral(resourceName: "bubble-lightning"),
        BubblePower.star: #imageLiteral(resourceName: "bubble-star")
    ]
    init(_ bubble: Bubble?) {
        if let coloredBubble = bubble as? ColoredBubble {
            type = .colored
            color = coloredBubble.color
            background = colorToImage[coloredBubble.color]
        } else if let specialBubble = bubble as? SpecialBubble {
            type = .special
            power = specialBubble.power
            background = powerToImage[specialBubble.power]
        }
    }
}
