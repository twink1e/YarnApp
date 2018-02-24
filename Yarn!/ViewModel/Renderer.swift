import UIKit

/**
 A renderer class that deals with presenting graphics and animation in the game.
 */
class Renderer: NSObject {
    let bubbleRadius: CGFloat
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    var itemsAnimator: UIDynamicAnimator?
    var removeViewFromScreen: ((UIView) -> Void)?
    var addViewToScreen: ((UIView) -> Void)?

    var bubbleDiameter: CGFloat {
        return 2 * bubbleRadius
    }
    var rowHeight: CGFloat {
        return sqrt(3) * bubbleRadius
    }
    var canonHeight: CGFloat {
        return bubbleRadius * 4
    }
    var canonWidth: CGFloat {
        return bubbleRadius * 3
    }
    init(bubbleRadius: CGFloat, screenWidth: CGFloat, screenHeight: CGFloat) {
        self.bubbleRadius = bubbleRadius
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
    }

    // Calculate the origin point of the bubble view given its grid position in designer.
    func upperLeftCoord(for path: IndexPath) -> (CGFloat, CGFloat) {
        let row = path[0]
        let col = path[1]
        let leftOffset = row % 2 == 0 ? 0 : bubbleRadius
        return (leftOffset + CGFloat(col) * bubbleDiameter, CGFloat(row) * rowHeight)
    }

    // Snap the bubble to grid position.
    func snapBubble(_ projectile: ProjectileBubble) {
        let pos = snappedPos(projectile.leftX, projectile.topY)
        UIView.animate(withDuration: 0.2) { projectile.setOrigin(pos) }
    }
    private func snappedPos(_ originalX: CGFloat, _ originalY: CGFloat) -> CGPoint {
        var row = floor(originalY / rowHeight)
        var remain = originalY - row * rowHeight
        row += remain > rowHeight / 2 ? 1 : 0
        let finalY = row * rowHeight

        let isEvenRow = (Int(row) % 2 == 0)
        let x = isEvenRow ? originalX : originalX - bubbleRadius
        var col = floor(x / bubbleDiameter)
        remain = x - col * bubbleDiameter
        col += remain > bubbleRadius ? 1 : 0
        let finalX = CGFloat(col) * bubbleDiameter + (isEvenRow ? 0 : bubbleRadius)
        return CGPoint(x: finalX, y: finalY)
    }

    // Present a canon to elevate the projectile bubble.
    func showCanon() {
        let canon = UIView(frame: CGRect(x: (screenWidth - canonWidth) / 2,
                                         y: screenHeight - canonHeight, width: canonWidth, height: canonHeight))
        canon.backgroundColor = UIColor.black
        canon.layer.zPosition = 1
        addViewToScreen?(canon)
    }

    // Show falling effects with gravity and bouncing.
    func animateFellBubbles(_ bubbles: [GameBubble]) {
        let bubbleViews = bubbles.map { $0.view }
        bubbleViews.forEach { $0.alpha = 0.5 }
        let gravityBehavior = UIGravityBehavior(items: bubbleViews)
        gravityBehavior.magnitude = 3
        let boundaryCollisionBehavior = UICollisionBehavior(items: bubbleViews)
        boundaryCollisionBehavior.translatesReferenceBoundsIntoBoundary = true
        let elasticityBehavior = UIDynamicItemBehavior(items: bubbleViews)
        elasticityBehavior.elasticity = 0.5
        itemsAnimator?.addBehavior(gravityBehavior)
        itemsAnimator?.addBehavior(boundaryCollisionBehavior)
        itemsAnimator?.addBehavior(elasticityBehavior)
    }

    // Show bursting effects before removing the bubble views.
    func animateBurstedBubbles(_ bubbles: [GameBubble]) {
        for bubble in bubbles {
            UIView.animate(withDuration: 0.5, animations: {
                bubble.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                bubble.view.alpha = 0
            }, completion: { _ in self.removeViewFromScreen?(bubble.view) })
        }
    }
}

// - MARK: UIDynamicAnimatorDelegate
extension Renderer: UIDynamicAnimatorDelegate {
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        // Remove all animated bubbles.
        let bubbleViews = animator.items(in: CGRect(origin: CGPoint(x: 0, y: 0),
                                                    size: CGSize(width: screenWidth, height: screenHeight)))
        bubbleViews.forEach { removeViewFromScreen?($0 as! UIView) }
    }
}
