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
        let closetDistance = physicsEngine.closestDistanceFromExistingBubble(projectile)
        // Collided.
        if closetDistance <= 0 {
            projectile.moveForDistance(closetDistance)
            stopProjectileAndRemoveBubbles()
            return
        }
        // Hitting ceiling.
        if projectile.topY <= 0 {
            projectile.translateY(-projectile.topY)
            stopProjectileAndRemoveBubbles()
            return
        }
        // Hitting left wall.
       if projectile.leftX <= 0 {
            projectile.translateX(-projectile.leftX)
            projectile.reverse()
        }
        // Hitting right wall.
        if projectile.rightX >= screenWidth {
            projectile.translateX(screenWidth - projectile.rightX)
            projectile.reverse()
        }
        projectile.moveForTime(duration)
    }

    private func stopProjectileAndRemoveBubbles() {
        projectile.stop()
        pauseGameLoop?()
        renderer.snapBubble(projectile)
        physicsEngine.addToGraph(projectile)
        clearRemovedBubbles()
        addNewProjectile()
    }

    // Clear bursted and fallen bubbles.
    private func clearRemovedBubbles() {
        let bursted = physicsEngine.getBurstedBubbles(projectile)
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
