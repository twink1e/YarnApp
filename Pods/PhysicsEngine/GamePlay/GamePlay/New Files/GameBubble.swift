import UIKit

/**
 A class that encapsulates the physical dimension and the UIImageView of the bubble in the game.
 */
open class GameBubble {
    public var color: BubbleColor
    public var power: BubblePower
    public var view: UIImageView
    public var snapping = true
    public var target = true

    // - MARK: Computed properties
    public var centerX: CGFloat {
        return view.frame.midX
    }
    public var centerY: CGFloat {
        return view.frame.midY
    }
    public var radius: CGFloat {
        return view.frame.width / 2.0
    }
    public var touchingCeiling: Bool {
        return abs(topY) <= Config.calculationErrorMargin
    }
    public var leftX: CGFloat {
        return centerX - radius
    }
    public var rightX: CGFloat {
        return centerX + radius
    }
    public var topY: CGFloat {
        return centerY - radius
    }

    public init(color: BubbleColor, power: BubblePower,view: UIImageView) {
        self.color = color
        self.power = power
        self.view = view
    }

    /// Create a deep copy of the given bubble.
    public convenience init(_ bubble: GameBubble) {
        let view = UIImageView(image: bubble.view.image)
        let radius = bubble.view.frame.width / 2.0
        view.frame = CGRect(x: bubble.centerX - radius, y: bubble.centerY - radius, width: radius * 2, height: radius * 2)
        view.layer.cornerRadius = radius
        self.init(color: bubble.color, power: bubble.power, view: view)
    }
}

// - MARK: Hashable
// Bubbles are considered the same if they have the same center point.
extension GameBubble: Hashable {
    public var hashValue: Int {
        return centerX.hashValue ^ centerY.hashValue &* 16_777_619
    }

    public static func == (lhs: GameBubble, rhs: GameBubble) -> Bool {
        return lhs.centerX == rhs.centerX && lhs.centerY == rhs.centerY
    }
}

// - MARK: CustomStringConvertible
extension GameBubble: CustomStringConvertible {
    public var description: String {
        return "(\(centerX), \(centerY), \(color), \(power), \(touchingCeiling))"
    }
}
