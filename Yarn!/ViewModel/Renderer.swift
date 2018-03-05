import UIKit
import PhysicsEngine

/**
 A renderer class that deals with presenting graphics and animation in the game.
 */
class Renderer: NSObject {
    weak var gamePlayDelegate: GamePlayDelegate?

    // Size specs.
    let bubbleRadius: CGFloat
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    var bubbleDiameter: CGFloat {
        return 2 * bubbleRadius
    }
    var rowHeight: CGFloat {
        return sqrt(3) * bubbleRadius
    }

    // Animation images
    var canonAnimationImages: [UIImage] = []
    var bubbleBurstAnimationImages: [UIImage] = []

    // Animator.
    var itemsAnimator: UIDynamicAnimator?
    var gravityBehavior: UIGravityBehavior?
    var boundaryCollisionBehavior: UICollisionBehavior?
    var elasticityBehavior: UIDynamicItemBehavior?
    let gravityMagnitude: CGFloat = 3
    let elasticity: CGFloat = 0.5
    let inactiveMagnetAlpha: CGFloat = 0.5
    let activeMagnetAlpha: CGFloat = 1

    /// Init a `Renderer` with the size specs and a delegate that presents the UI.
    init(bubbleRadius: CGFloat, screenWidth: CGFloat, screenHeight: CGFloat, delegate: GamePlayDelegate) {
        self.bubbleRadius = bubbleRadius
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        gamePlayDelegate = delegate
        super.init()
        itemsAnimator = gamePlayDelegate?.itemsAnimator
        setUpDynamicAnimator()
        canonAnimationImages = cropSpriteSheet(#imageLiteral(resourceName: "canon-animation"),
                                               row: Config.canonAnimationSpriteRow, col: Config.canonAnimationSpriteCol)
        bubbleBurstAnimationImages = cropSpriteSheet(#imageLiteral(resourceName: "bubble-burst"), row: 1, col: 4)
    }

    func removeViewFromScreen(_ view: UIView) {
        view.removeFromSuperview()
    }

    func addViewToScreen(_ view: UIView) {
        gamePlayDelegate?.addViewToScreen(view)
    }

    func clearBubbleViews(_ bubbles: [GameBubble]) {
        bubbles.forEach { removeViewFromScreen($0.view) }
    }

    /// Snap the bubble so the origin become `newPos`.
    func snapBubble(_ projectile: ProjectileBubble, to newPos: CGPoint) {
        UIView.animate(withDuration: 0.2) { projectile.setOrigin(newPos) }
    }

    /// Return the nearest grid position given the original postion.
    func snappedPos(_ originalX: CGFloat, _ originalY: CGFloat) -> CGPoint {
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

    /// Rotate the canon so the center of the canon faces the target point.
    /// No rotation if rotation angle is greater than the angle to reach the cutting line of the game.
    /// Return true if the canon has been rotated.
    func rotateCanon(_ canonView: UIView, to targetPoint: CGPoint) -> Bool {
        let maxAngle = rotationAngle(from: canonView.center, toPoint: CGPoint(x: 0, y: screenWidth))
        let angle = rotationAngle(from: canonView.center, toPoint: targetPoint)
        guard abs(angle) <= abs(maxAngle) else {
            canonView.transform = CGAffineTransform.identity
            return false
        }
        canonView.transform = CGAffineTransform.identity
        canonView.transform = CGAffineTransform(rotationAngle: angle)
        return true
    }

    /// Reset the canon to be vertical.
    func resetCanon(_ canonView: UIView) {
        canonView.transform = CGAffineTransform.identity
    }

    /// Start canon fire animation.
    func releaseCanon(_ canonView: UIImageView) {
        canonView.animationImages = canonAnimationImages
        canonView.animationRepeatCount = 1
        canonView.startAnimating()
    }

    func showInactiveMagnet(_ magnet: GameBubble) {
        magnet.view.alpha = inactiveMagnetAlpha
    }

    func showActiveMagnet(_ magnet: GameBubble) {
        magnet.view.alpha = activeMagnetAlpha
    }

    /// Show falling effects with gravity and bouncing.
    func animateFellBubbles(_ bubbles: [GameBubble]) {
        bubbles
            .map { $0.view }
            .forEach {
                $0.alpha = 0.5; $0.layer.borderWidth = 0
                gravityBehavior?.addItem($0)
                boundaryCollisionBehavior?.addItem($0)
                elasticityBehavior?.addItem($0)
            }
    }

    /// Show bursting effects before removing the bubble views.
    func animateBurstedBubbles(_ bubbles: [GameBubble]) {
        bubbles
            .map { $0.view }
            .forEach {
                $0.layer.borderWidth = 0
                $0.animationImages = bubbleBurstAnimationImages
                $0.animationRepeatCount = 1
                $0.animationDuration = Config.bubbleBurstAnimationDuration
                $0.startAnimating()
                Timer.scheduledTimer(timeInterval: Config.bubbleBurstAnimationDuration,
                                     target: self, selector: #selector(removeBubble(_:)), userInfo: $0, repeats: false)
            }
    }

    @objc
    private func removeBubble(_ timer: Timer) {
        self.removeViewFromScreen(timer.userInfo as! UIView)
    }

    private func setUpDynamicAnimator() {
        itemsAnimator?.delegate = self
        gravityBehavior = UIGravityBehavior(items: [])
        gravityBehavior?.magnitude = gravityMagnitude
        boundaryCollisionBehavior = UICollisionBehavior(items: [])
        boundaryCollisionBehavior?.translatesReferenceBoundsIntoBoundary = true
        elasticityBehavior = UIDynamicItemBehavior(items: [])
        elasticityBehavior?.elasticity = elasticity
        itemsAnimator?.addBehavior(gravityBehavior!)
        itemsAnimator?.addBehavior(boundaryCollisionBehavior!)
        itemsAnimator?.addBehavior(elasticityBehavior!)
    }

    private func cropSpriteSheet(_ sheet: UIImage, row: Int, col: Int) -> [UIImage] {
        var images: [UIImage] = []
        let width = sheet.size.width * UIScreen.main.scale / CGFloat(col)
        let height = sheet.size.height * UIScreen.main.scale / CGFloat(row)
        for i in 0 ..< row {
            for j in 0 ..< col {
                let frame = CGRect(x: CGFloat(j) * width, y: CGFloat(i) * height, width: width, height: height)
                guard let cgImage = sheet.cgImage?.cropping(to: frame) else {
                    continue
                }
                images.append(UIImage(cgImage: cgImage))
            }
        }
        return images
    }

    private func rotationAngle(from: CGPoint, toPoint: CGPoint) -> CGFloat {
        let xDiff = from.x - toPoint.x
        let yDiff = from.y - toPoint.y
        return atan(xDiff / -yDiff)
    }
}

// - MARK: UIDynamicAnimatorDelegate
extension Renderer: UIDynamicAnimatorDelegate {
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        // Remove all animated bubbles.
        let bubbleViews = animator.items(in: CGRect(origin: CGPoint(x: 0, y: 0),
                                                    size: CGSize(width: screenWidth, height: screenHeight)))
        bubbleViews.forEach {
            gravityBehavior?.removeItem($0)
            elasticityBehavior?.removeItem($0)
            boundaryCollisionBehavior?.removeItem($0)
            removeViewFromScreen($0 as! UIView)
        }
    }
}
