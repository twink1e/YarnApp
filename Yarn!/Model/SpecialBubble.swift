import PhysicsEngine
/**
 A special type of bubble that has power.
 */
struct SpecialBubble: Codable {
    static var type = BubbleType.special
    var power: BubblePower

    init(_ power: BubblePower) {
        self.power = power
    }
}

// MARK: - Equatable
extension SpecialBubble: Equatable {
    static func == (lhs: SpecialBubble, rhs: SpecialBubble) -> Bool {
        return lhs.power == rhs.power
    }
}

// MARK: - Bubble
extension SpecialBubble: Bubble {}
