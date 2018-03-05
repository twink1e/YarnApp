import UIKit
import PhysicsEngine
/**
 Handles the game logic, including movement of projectile,
 and removal of bursted and fallen bubbles.
 It relies on a Renderer for display and animation,
 and a PhysicsEngine for path computation and collision detection.
 */
class GameEngine {
    let renderer: Renderer
    let physicsEngine: PhysicsEngine
    weak var gamePlayDelegate: GamePlayDelegate?

    // Projectile handling
    var numOfProjectileLeft = 0
    let noBubbleLeftLabel = 0
    let nonSnappingLotteryNumber = 0
    let allColors: [BubbleColor] = [.red, .orange, .green, .blue]
    var currentProjectile: ProjectileBubble!
    var nextProjectile: ProjectileBubble?

    // Point system
    var points = 0
    let initialPointString = "0"
    let numberFormatter = NumberFormatter()
    var pointString: String {
        return numberFormatter.string(from: NSNumber(value: points))!
    }

    // Size specs
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let bubbleRadius: CGFloat
    var bubbleDiameter: CGFloat {
        return renderer.bubbleDiameter
    }
    var rowHeight: CGFloat {
        return renderer.rowHeight
    }

    /// Constructs a game engine with bubble radius, screen width, screen height
    /// and a delegate that updates the view.
    init(radius: CGFloat, width: CGFloat, height: CGFloat, delegate: GamePlayDelegate) {
        bubbleRadius = radius
        screenWidth = width
        screenHeight = height
        gamePlayDelegate = delegate
        renderer = Renderer(bubbleRadius: radius, screenWidth: width, screenHeight: height, delegate: delegate)
        physicsEngine = PhysicsEngine(screenHeight: height, bubbleDiameter: radius * 2)
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
    }

    /// Clear the game state when player exits.
    func clear() {
        currentProjectile = nil
        nextProjectile = nil
        renderer.clearBubbleViews(Array(physicsEngine.adjList.keys))
        physicsEngine.clear()
        points = 0
        gamePlayDelegate?.updatePoints(initialPointString)
        numOfProjectileLeft = 0
    }

    /// Start the game by building the initial game bubble grid and supply the projectiles.
    /// Check if target exists in case this is an empty grid.
    func startGame(_ initialBubbles: [GameBubble], yarnLimit: Int) {
        numOfProjectileLeft = yarnLimit
        let bubbles = initialBubbles.map { GameBubble($0) }
        buildGraph(bubbles)
        addNewProjectile()
        guard moveUpProjectile() else {
            gamePlayDelegate?.loseGame()
            return
        }
        guard targetBubbleExists() else {
            points += yarnLimit * Config.unusedPoints
            gamePlayDelegate?.winGame(pointString)
            return
        }
    }

    /// Update the projectile for the elapse of time `duration` in seconds.
    /// Backtrack the projectile if it has moved excessively, e.g. overlapping with another bubble, out of screen.
    /// Check if bubbles are attracted by magnets.
    /// Then stop or move the projectile accordingly.
    func moveProjectile(_ duration: CGFloat) {
        backtrackProjectileToInScreen()

        // Collided.
        if let collidedBubbleAndDistance = physicsEngine.closestCollidedBubbleAndDistance(currentProjectile) {
            handleCollision(collidedBubbleAndDistance)
            return
        }

        // Hitting ceiling.
        if abs(currentProjectile.topY) <= Config.calculationErrorMargin {
            stopProjectileAndRemoveBubbles()
            return
        }
        // Hitting side wall.
       if abs(currentProjectile.leftX) <= Config.calculationErrorMargin
        || abs(currentProjectile.rightX - screenWidth) <= Config.calculationErrorMargin {
            currentProjectile.reverse()
        }
        checkMagnets()
        currentProjectile.moveForTime(duration)
    }

    // Attract projectile to magnets that are not obstructed.
    private func checkMagnets() {
        let magnets = physicsEngine.adjList.keys.filter { $0.power == .magnetic }
        magnets.forEach { renderer.showInactiveMagnet($0) }
        magnets
            .filter { physicsEngine.clearPath(currentProjectile, to: $0) }
            .forEach {
                renderer.showActiveMagnet($0)
                currentProjectile.attractsTowards(CGPoint(x: $0.centerX, y: $0.centerY))
            }
    }

    private func backtrackProjectileToInScreen() {
        if currentProjectile.topY < 0 {
            currentProjectile.moveForY(-currentProjectile.topY)
        }
        if currentProjectile.leftX < 0 {
            currentProjectile.moveForX(-currentProjectile.leftX)
        }
        if currentProjectile.rightX > screenWidth {
            currentProjectile.moveForX(screenWidth - currentProjectile.rightX)
        }
    }

    private func handleCollision(_ collided: (GameBubble, CGFloat)) {
        if !collided.0.snapping {
            currentProjectile.setNonSnapping()
        }
        var collidedBubbleAndDistance: (GameBubble, CGFloat)? = collided
        while let collidedBubble = collidedBubbleAndDistance?.0,
            let distance = collidedBubbleAndDistance?.1, distance < -Config.calculationErrorMargin {
                physicsEngine.backtrackToTouching(currentProjectile, with: collidedBubble)
                if !collidedBubble.snapping {
                    currentProjectile.setNonSnapping()
                }
                collidedBubbleAndDistance = physicsEngine.closestCollidedBubbleAndDistance(currentProjectile)
        }
        stopProjectileAndRemoveBubbles()
    }

    // Handles the logic when the projectile has landed.
    private func stopProjectileAndRemoveBubbles() {
        currentProjectile.stop()
        gamePlayDelegate?.pauseGameLoop()
        maybeSnapProjectile()
        // Ensure no overlap with other bubbles
        assert(physicsEngine.closestDistanceFromExistingBubble(currentProjectile) >= -Config.calculationErrorMargin)
        physicsEngine.addToGraph(currentProjectile)
        guard !projectileTouchingCuttingLine() else {
            gamePlayDelegate?.loseGame()
            return
        }
        clearRemovedBubbles()
        guard targetBubbleExists() else {
            points += (nextProjectile?.label ?? 0) * Config.unusedPoints
            gamePlayDelegate?.winGame(pointString)
            return
        }
        guard moveUpProjectile() else {
            gamePlayDelegate?.loseGame()
            return
        }
    }

    private func projectileTouchingCuttingLine() -> Bool {
        return currentProjectile.centerY + bubbleRadius >= screenWidth
    }

    private func targetBubbleExists() -> Bool {
        let targets = physicsEngine.adjList.keys.filter { $0.target }
        return !targets.isEmpty
    }

    // get all the colors of target bubbles.
    private func targetColors() -> [BubbleColor]? {
        var colors: Set<BubbleColor> = []
        physicsEngine.adjList.keys
            .filter { $0.target && $0.color != .noColor }
            .forEach { colors.insert($0.color) }
        return colors.isEmpty ? nil : Array(colors)
    }

    // Snap bubble if itself is snapping and also it does not contact a non-snapping bubble.
    private func maybeSnapProjectile() {
        if !currentProjectile.snapping {
            return
        }
        let originalPos = CGPoint(x: currentProjectile.leftX, y: currentProjectile.topY)
        let gridPos = renderer.snappedPos(currentProjectile.leftX, currentProjectile.topY)
        renderer.snapBubble(currentProjectile, to: gridPos)
        // Don't snap if it overlaps with a non-snapping bubble after snap.
        if let collidedBubble = physicsEngine.closestCollidedBubbleAndDistance(currentProjectile)?.0,
            !collidedBubble.snapping {
            currentProjectile.setNonSnapping()
            renderer.snapBubble(currentProjectile, to: originalPos)
        }
    }

    // Clear bursted and fallen bubbles and add points.
    private func clearRemovedBubbles() {
        let powerBursted = physicsEngine.bubblesBurstedByPower(currentProjectile)
        let colorBursted = physicsEngine.getBurstedBubbles(currentProjectile)
        let bursted = powerBursted.union(colorBursted)
        let fell = physicsEngine.getFellBubbles(bursted)
        let burstedArray = Array(bursted)
        let fellArray = Array(fell)
        removeBurstedBubbles(burstedArray)
        removeFellBubbles(fellArray)
        addPoints(bursted: burstedArray, fell: fellArray)
    }

    private func addPoints(bursted: [GameBubble], fell: [GameBubble]) {
        let burstedTargetCount = bursted
            .filter { $0.target }
            .count
        let fellTargetCount = fell
            .filter { $0.target }
            .count
        points += Config.burstPoints * burstedTargetCount + Config.fellPoints * fellTargetCount
        gamePlayDelegate?.updatePoints(pointString)
    }

    // Add a new projectile waiting to be launched.
    // Color is a random color of the target bubbles.
    // If all target bubbles have no color, randomly choose from all colors.
    // Non-snapping will be set with a probability that respects snappingToNonSnappingRatio.
    private func addNewProjectile() {
        guard numOfProjectileLeft > 0 else {
            gamePlayDelegate?.updateNextBubbleLabel(String(noBubbleLeftLabel))
            return
        }
        let colors = targetColors() ?? allColors
        let colorIndex = Int(arc4random_uniform(UInt32(colors.count)))
        let newProjectile = ProjectileBubble(color: colors[colorIndex],
                                             centerX: screenWidth - Config.nextBubbleTrailing,
                                      centerY: screenHeight - Config.waitingBubbleBottomHeight - bubbleRadius,
                                      radius: bubbleRadius, label: numOfProjectileLeft)
        let nonSnappingDraw = Int(arc4random_uniform(UInt32(Config.snappingToNonSnappingRatio + 1)))
        if nonSnappingDraw == nonSnappingLotteryNumber {
            newProjectile.setNonSnapping()
        }
        renderer.addViewToScreen(newProjectile.view)
        nextProjectile = newProjectile
        gamePlayDelegate?.updateNextBubbleLabel(String(newProjectile.label))
        numOfProjectileLeft -= 1
    }

    // Return false if there is no more bubble left to play.
    private func moveUpProjectile() -> Bool {
        guard let next = nextProjectile else {
            gamePlayDelegate?.updateCurrentBubbleLabel(String(noBubbleLeftLabel))
            return false
        }
        let newOrigin = CGPoint(x: screenWidth - Config.currentBubbleTrailing - bubbleRadius,
                                y: screenHeight - Config.waitingBubbleBottomHeight - bubbleDiameter)
        next.setOrigin(newOrigin)
        currentProjectile = next
        nextProjectile = nil

        gamePlayDelegate?.updateCurrentBubbleLabel(String(currentProjectile.label))
        addNewProjectile()
        return true
    }

    // Build up existing bubble graph.
    private func buildGraph(_ bubbles: [GameBubble]) {
        for bubble in bubbles {
            renderer.addViewToScreen(bubble.view)
        }
        physicsEngine.buildGraph(bubbles)
    }

    // Remove `bubbles` with bursted animation.
    private func removeBurstedBubbles(_ bubbles: [GameBubble]) {
        bubbles.forEach { physicsEngine.removeBubbleFromGraph($0) }
        renderer.animateBurstedBubbles(bubbles)
    }

    // Remove `bubbles` with falling animation.
    private func removeFellBubbles(_ bubbles: [GameBubble]) {
        bubbles.forEach { physicsEngine.removeBubbleFromGraph($0) }
        renderer.animateFellBubbles(bubbles)
    }
}
