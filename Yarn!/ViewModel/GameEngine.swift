import UIKit
import PhysicsEngine
/**
 Handles the game logic, including movement of projectile,
 and removal of bursted and fallen bubbles.
 It relies on a Renderer for display and animation,
 and a PhysicsEngine for path computation and collision detection.
 */
class GameEngine {
    let noBubbleLeftLabel = "0"
    let allColors: [BubbleColor] = [.red, .orange, .green, .blue]
    var currentProjectile: ProjectileBubble!
    var nextProjectile: ProjectileBubble?
    let renderer: Renderer
    let physicsEngine: PhysicsEngine
    var numOfProjectileLeft = 5
    weak var gamePlayDelegate: GamePlayDelegate?

    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let bubbleRadius: CGFloat
    var bubbleDiameter: CGFloat {
        return renderer.bubbleDiameter
    }
    var rowHeight: CGFloat {
        return renderer.rowHeight
    }

    init(radius: CGFloat, width: CGFloat, height: CGFloat, delegate: GamePlayDelegate) {
        bubbleRadius = radius
        screenWidth = width
        screenHeight = height
        gamePlayDelegate = delegate
        renderer = Renderer(bubbleRadius: radius, screenWidth: width, screenHeight: height, delegate: delegate)
        physicsEngine = PhysicsEngine(screenHeight: height, bubbleDiameter: radius * 2)
    }

    // Clear the game state when player exits.
    func clear() {
        currentProjectile = nil
        nextProjectile = nil
        numOfProjectileLeft = 100
    }

    func startGame(_ bubbles: [GameBubble]) {
        buildGraph(bubbles)
        addNewProjectile()
        guard moveUpProjectile() else {
            loseGame()
            return
        }
    }
    
    // Backtrack the projectile if it has moved excessively,
    // e.g. overlapping with another bubble, out of screen.
    // Then stop or move the projectile accordingly.
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
       if abs(currentProjectile.leftX) <= Config.calculationErrorMargin || abs(currentProjectile.rightX - screenWidth) <= Config.calculationErrorMargin {
            currentProjectile.reverse()
        }
        checkMagnets(attract: true)
        currentProjectile.moveForTime(duration)
    }

    func winGame() {
        print ("win")
    }
    func loseGame() {
        print ("lose")
    }
    // Attract projectile to magnets that are not obstructed.
    func checkMagnets(attract: Bool) {
        let magnets = physicsEngine.adjList.keys.filter { $0.power == .magnetic }
        magnets.forEach { renderer.showInactiveMagnet($0) }
        magnets
            .filter { physicsEngine.clearPath(currentProjectile, to: $0) }
            .forEach {
                renderer.showActiveMagnet($0)
                if attract {
                    currentProjectile.attractsTowards(x: $0.centerX, y: $0.centerY)
                }
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
        var collidedBubbleAndDistance: (GameBubble, CGFloat)? = collided
        while let collidedBubble = collidedBubbleAndDistance?.0, let distance = collidedBubbleAndDistance?.1, distance < -Config.calculationErrorMargin {
            physicsEngine.backtrackToTouching(currentProjectile, with: collidedBubble)
            if !collidedBubble.snapping {
                currentProjectile.setNonSnapping()
            }
            collidedBubbleAndDistance = physicsEngine.closestCollidedBubbleAndDistance(currentProjectile)
        }
        stopProjectileAndRemoveBubbles()
    }

    private func stopProjectileAndRemoveBubbles() {
        currentProjectile.stop()
        gamePlayDelegate?.pauseGameLoop()
        maybeSnapProjectile()
        // Ensure no overlap with other bubbles
        //print ("after snap", physicsEngine.closestCollidedBubbleAndDistance(projectile))
        //print ("dist", physicsEngine.closestDistanceFromExistingBubble(projectile))

        assert(physicsEngine.closestDistanceFromExistingBubble(currentProjectile) >= -Config.calculationErrorMargin)
        physicsEngine.addToGraph(currentProjectile)
        //print ("before removal", physicsEngine.adjList)
        clearRemovedBubbles()
        guard targetBubbleExists() else {
            winGame()
            return
        }
        //print ("after removal", physicsEngine.adjList)
        guard moveUpProjectile() else {
            loseGame()
            return
        }
        checkMagnets(attract: false)
    }

    private func targetBubbleExists() -> Bool {
        let targets = physicsEngine.adjList.keys.filter { $0.target }
        return !targets.isEmpty
    }
    private func targetColors() -> [BubbleColor]? {
        var colors: Set<BubbleColor> = []
        physicsEngine.adjList.keys
            .filter { $0.target && $0.color != .noColor }
            .forEach { colors.insert($0.color) }
        return colors.isEmpty ? nil : Array(colors)
    }
    private func maybeSnapProjectile() {
        if !currentProjectile.snapping {
            return
        }
        let originalPos = CGPoint(x: currentProjectile.leftX, y: currentProjectile.topY)
        let gridPos = renderer.snappedPos(currentProjectile.leftX, currentProjectile.topY)
        renderer.snapBubble(currentProjectile, to: gridPos)
        if let collidedBubble = physicsEngine.closestCollidedBubbleAndDistance(currentProjectile)?.0, !collidedBubble.snapping {
            currentProjectile.setNonSnapping()
            renderer.snapBubble(currentProjectile, to: originalPos)
        }
    }

    // Clear bursted and fallen bubbles.
    private func clearRemovedBubbles() {
        let powerBursted = physicsEngine.bubblesBurstedByPower(currentProjectile)
        let colorBursted = physicsEngine.getBurstedBubbles(currentProjectile)
        let bursted = powerBursted.union(colorBursted)
        let fell = physicsEngine.getFellBubbles(bursted)
        removeBurstedBubbles(Array(bursted))
        removeFellBubbles(Array(fell))
    }

    // Add a new projectile waiting to be launched.
    // Color is a random color of the target bubbles.
    // If all target bubbles have no color, randomly choose from all colors.
    // Non-snapping will be set with a probability that respects snappingToNonSnappingRatio.
    func addNewProjectile() {
        guard numOfProjectileLeft > 0 else {
            nextProjectile = nil
            gamePlayDelegate?.updateNextBubbleLabel(noBubbleLeftLabel)
            return
        }
        let colors = targetColors() ?? allColors
        let colorIndex = Int(arc4random_uniform(UInt32(colors.count)))
        let newProjectile = ProjectileBubble(color: colors[colorIndex], centerX: screenWidth - Config.nextBubbleTrailing,
                                      centerY: screenHeight - Config.waitingBubbleBottomHeight - bubbleRadius,
                                      radius: bubbleRadius, label: String(numOfProjectileLeft))
        let nonSnappingDraw = Int(arc4random_uniform(UInt32(Config.snappingToNonSnappingRatio + 1)))
        let lotteryNumber = 0
        if nonSnappingDraw == lotteryNumber {
            newProjectile.setNonSnapping()
        }
        renderer.addViewToScreen(newProjectile.view)
        nextProjectile = newProjectile
        gamePlayDelegate?.updateNextBubbleLabel(newProjectile.label)
        numOfProjectileLeft -= 1
    }

    // Return false if there is no more bubble left to play.
    func moveUpProjectile() -> Bool {
        guard let next = nextProjectile else {
            gamePlayDelegate?.updateCurrentBubbleLabel(noBubbleLeftLabel)
            return false
        }
        let newOrigin = CGPoint(x: screenWidth - Config.currentBubbleTrailing - bubbleRadius, y: screenHeight - Config.waitingBubbleBottomHeight - bubbleDiameter)
        next.setOrigin(newOrigin)
        currentProjectile = next
        gamePlayDelegate?.updateCurrentBubbleLabel(currentProjectile.label)
        addNewProjectile()
        return true
    }

    // Build up existing bubble graph.
    func buildGraph(_ bubbles: [GameBubble]) {
        for bubble in bubbles {
            renderer.addViewToScreen(bubble.view)
        }
        physicsEngine.buildGraph(bubbles)
    }

    // Remove `bubbles` with bursted animation.
    func removeBurstedBubbles(_ bubbles: [GameBubble]) {
        bubbles.forEach { physicsEngine.removeBubbleFromGraph($0) }
        renderer.animateBurstedBubbles(bubbles)
    }

    // Remove `bubbles` with falling animation.
    func removeFellBubbles(_ bubbles: [GameBubble]) {
        bubbles.forEach { physicsEngine.removeBubbleFromGraph($0) }
        renderer.animateFellBubbles(bubbles)
    }
}
