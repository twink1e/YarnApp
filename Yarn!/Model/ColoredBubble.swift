//  Copyright © 2018 nus.cs3217. All rights reserved.
import PhysicsEngine
/**
 A basic type of bubble that has color.
 */
struct ColoredBubble: Codable {
    static var type = BubbleType.colored
    var color: BubbleColor

    init(_ color: BubbleColor) {
        self.color = color
    }
}

// MARK: - Equatable
extension ColoredBubble: Equatable {
    static func == (lhs: ColoredBubble, rhs: ColoredBubble) -> Bool {
        return lhs.color == rhs.color
    }
}

// MARK: - Bubble
extension ColoredBubble: Bubble {}
