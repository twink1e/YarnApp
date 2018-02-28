import UIKit
import PhysicsEngine
/**
 Handles the game logic, including movement of projectile,
 and removal of bursted and fallen bubbles.
 It relies on a Renderer for display and animation,
 and a PhysicsEngine for path computation and collision detection.
 */
class GameEngine {
    let colors: [BubbleColor] = [.red, .orange, .green, .blue]
    var projectile: ProjectileBubble!
    let renderer: Renderer
    let physicsEngine: PhysicsEngine
    var snapping = true
    var pauseGameLoop: (() -> Void)?

    var screenWidth: CGFloat {
        return renderer.screenWidth
    }
    var screenHeight: CGFloat {
        return renderer.screenHeight
    }
    var bubbleRadius: CGFloat {
        return renderer.bubbleRadius
    }
    var bubbleDiameter: CGFloat {
        return renderer.bubbleDiameter
    }
    var rowHeight: CGFloat {
        return renderer.rowHeight
    }

    init(radius: CGFloat, width: CGFloat, height: CGFloat) {
        renderer = Renderer(bubbleRadius: radius, screenWidth: width, screenHeight: height)
        physicsEngine = PhysicsEngine(screenHeight: height, bubbleDiameter: radius * 2)
    }

    // Clear the game state when player exits.
    func clear() {
        physicsEngine.clear()
        projectile = nil
    }

    // Backtrack the projectile if it has moved excessively,
    // e.g. overlapping with another bubble, out of screen.
    // Then stop or move the projectile accordingly.
    func moveProjectile(_ duration: CGFloat) {
        backtrackProjectileToInScreen()
       // Collided.
        if let collidedBubbleAndDistance = physicsEngine.closestCollidedBubbleAndDistance(projectile) {
            handleCollision(collidedBubbleAndDistance)
            return
        }

        // Hitting ceiling.
        if abs(projectile.topY) <= Config.calculationErrorMargin {
            stopProjectileAndRemoveBubbles()
            return
        }
        // Hitting side wall.
       if abs(projectile.leftX) <= Config.calculationErrorMargin || abs(projectile.rightX - screenWidth) <= Config.calculationErrorMargin {
            projectile.reverse()
        }
        checkMagnets(attract: true)
        projectile.moveForTime(duration)
        // renderer.rotateBubble(projectile)
    }

    // Attract projectile to magnets that are not obstructed.
    func checkMagnets(attract: Bool) {
        let magnets = physicsEngine.adjList.keys.filter { $0.power == .magnetic }
        magnets.forEach { renderer.showInactiveMagnet($0) }
        magnets
            .filter { physicsEngine.clearPath(projectile, to: $0) }
            .forEach {
                renderer.showActiveMagnet($0)
                if attract {
                    projectile.attractsTowards(x: $0.centerX, y: $0.centerY)
                }
            }
    }

    private func backtrackProjectileToInScreen() {
        if projectile.topY < 0 {
            projectile.moveForY(-projectile.topY)
        }
        if projectile.leftX < 0 {
            projectile.moveForX(-projectile.leftX)
        }
        if projectile.rightX > screenWidth {
            projectile.moveForX(screenWidth - projectile.rightX)
        }
    }
    private func handleCollision(_ collided: (GameBubble, CGFloat)) {
        var collidedBubbleAndDistance: (GameBubble, CGFloat)? = collided
        while let collidedBubble = collidedBubbleAndDistance?.0, let distance = collidedBubbleAndDistance?.1, distance < -Config.calculationErrorMargin {
            physicsEngine.backtrackToTouching(projectile, with: collidedBubble)
            if !collidedBubble.snapping {
                projectile.setNonSnapping()
            }
            collidedBubbleAndDistance = physicsEngine.closestCollidedBubbleAndDistance(projectile)
        }
        stopProjectileAndRemoveBubbles()
    }

    private func stopProjectileAndRemoveBubbles() {
        projectile.stop()
        pauseGameLoop?()
        maybeSnapProjectile()
        // Ensure no overlap with other bubbles
        //print ("after snap", physicsEngine.closestCollidedBubbleAndDistance(projectile))
        //print ("dist", physicsEngine.closestDistanceFromExistingBubble(projectile))

        assert(physicsEngine.closestDistanceFromExistingBubble(projectile) >= -Config.calculationErrorMargin)
        physicsEngine.addToGraph(projectile)
        //print ("before removal", physicsEngine.adjList)
        clearRemovedBubbles()
        checkMagnets(attract: false)
        //print ("after removal", physicsEngine.adjList)
        addNewProjectile()
    }

    private func maybeSnapProjectile() {
        if !projectile.snapping {
            return
        }
        let originalPos = CGPoint(x: projectile.leftX, y: projectile.topY)
        let gridPos = renderer.snappedPos(projectile.leftX, projectile.topY)
        renderer.snapBubble(projectile, to: gridPos)
        if let collidedBubble = physicsEngine.closestCollidedBubbleAndDistance(projectile)?.0, !collidedBubble.snapping {
            projectile.setNonSnapping()
            renderer.snapBubble(projectile, to: originalPos)
        }
    }

    // Clear bursted and fallen bubbles.
    private func clearRemovedBubbles() {
        let powerBursted = physicsEngine.bubblesBurstedByPower(projectile)
        let colorBursted = physicsEngine.getBurstedBubbles(projectile)
        let bursted = powerBursted.union(colorBursted)
        let fell = physicsEngine.getFellBubbles(bursted)
        removeBurstedBubbles(Array(bursted))
        removeFellBubbles(Array(fell))
    }

    // Add a new projectile waiting to be launched with a random color.
    func addNewProjectile() {
        let colorIndex = Int(arc4random_uniform(UInt32(colors.count)))
        projectile = ProjectileBubble(color: colors[colorIndex], startCenterX: screenWidth / 2,
                                      startCenterY: screenHeight - bubbleRadius - renderer.canonHeight,
                                      radius: bubbleRadius)
        if snapping {
            snapping = false
        } else {
            projectile.setNonSnapping()
            snapping = true
        }
        renderer.addViewToScreen?(projectile.view)
    }

    // Build up existing bubble graph.
    func buildGraph(_ bubbles: [GameBubble]) {
        for bubble in bubbles {
            renderer.addViewToScreen?(bubble.view)
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
