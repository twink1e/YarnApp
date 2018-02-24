//  Copyright © 2018 nus.cs3217. All rights reserved.

/**
 A wrapper struct for all structs that conform to `Bubble`.
 Necessary for decoding and encoding of bubbles since protocols do not conform to themselves.
 Reference: https://stackoverflow.com/a/44473156/6403358
 */
struct CodableBubble: Codable {

    var bubble: Bubble

    init?(_ base: Bubble?) {
        guard let bubble = base else {
            return nil
        }
        self.bubble = bubble
    }

    private enum CodingKeys: CodingKey {
        case type, bubble
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BubbleType.self, forKey: .type)
        self.bubble = try type.metatype.init(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type(of: bubble).type, forKey: .type)
        try bubble.encode(to: encoder)
    }
}
