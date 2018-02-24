//  Copyright © 2018 nus.cs3217 All rights reserved.

/**
 Enum for the types of bubbles that conform to `Bubble` protocol.
 Necessary for encoding and decoding of `Bubble`.
 */
enum BubbleType: String, Codable {
    case colored

    var metatype: Bubble.Type {
        switch self {
        case .colored:
            return ColoredBubble.self
        }
    }
}

/**
 Protocol that all types of bubbles should conform to.
 */
protocol Bubble: Codable {
    static var type: BubbleType { get }
    func isEqualTo(_ other: Bubble) -> Bool
}

/// Equatable with type erasure.
extension Bubble where Self: Equatable {
    func isEqualTo(_ other: Bubble) -> Bool {
        guard let otherBubble = other as? Self else {
            return false
        }
        return self == otherBubble
    }
}
