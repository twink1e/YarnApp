/**
 All colors that a `ColoredBubble` can have.
 */
public enum BubbleColor: String, Codable {
    case red, green, blue, orange, noColor
}
/**
 All power that a `SpecialBubble` can have.
 */
public enum BubblePower: String, Codable {
    case indestructible, magnetic, lightning, star, bomb, noPower
}
