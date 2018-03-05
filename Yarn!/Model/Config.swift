import PhysicsEngine

/**
 Config to be shared.
 */
extension Config {
    static let gridRow = 9
    static let gridColEvenRow = 12
    static let levelDesignCellWidthReduction: CGFloat = 2
    static let projectileSpeed: CGFloat = 1_000
    static let framePerSecond = 60
    static let magneticAttraction: CGFloat = 1_000
    static let snappingToNonSnappingRatio = 5
    static let canonAnimationSpriteRow = 2
    static let canonAnimationSpriteCol = 5
    static let bubbleBurstAnimationDuration = 0.3
    static let waitingBubbleBottomHeight: CGFloat = 53
    static let nextBubbleTrailing: CGFloat = 50
    static let currentBubbleTrailing: CGFloat = 150
    static let burstPoints = 10
    static let unusedPoints = 20
    static let fellPoints = 30
    static let maxNameLength = 20
    static let maxYarnLength = 3
    static let minYarnLimit = 1
    static let maxYarnLimit = 999
}
