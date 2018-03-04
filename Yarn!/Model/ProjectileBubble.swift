import UIKit
import PhysicsEngine

/**
 A GameBubble subclass that encapsulates a movable bubble that is ready to be launched.
 */
class ProjectileBubble: GameBubble {
    private(set) var sin: CGFloat = 0
    private(set) var cos: CGFloat = 0
    private(set) var launched = false
    private(set) var vectorX: CGFloat = 0
    private(set) var vectorY: CGFloat = 0
    let label: Int
    private let colorToImage = [
        BubbleColor.blue: #imageLiteral(resourceName: "bubble-blue-pin"),
        BubbleColor.red: #imageLiteral(resourceName: "bubble-red-pin"),
        BubbleColor.orange: #imageLiteral(resourceName: "bubble-orange-pin"),
        BubbleColor.green: #imageLiteral(resourceName: "bubble-green-pin")
    ]

    // Construct a new UIImageView based on the color and dimension given.
    init(color: BubbleColor, centerX: CGFloat, centerY: CGFloat, radius: CGFloat, label: Int) {
        let view = UIImageView(image: colorToImage[color])
        view.frame = CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2)
        view.layer.cornerRadius = radius
        self.label = label
        super.init(color: color, power: .noPower, view: view)
        target = false
    }

    // Launch the bubble in the direction that goes towards the given point, if it has not been launched yet.
    func setLaunchDirection(start: CGPoint, target: CGPoint) {
        view.frame.origin = CGPoint(x: start.x - radius, y: start.y - radius)
        let xDist = target.x - start.x
        let yDist = target.y - start.y
        assert (yDist < 0 )
        let dist = sqrt(pow(xDist, 2) + pow(yDist, 2))
        cos = xDist / dist
        sin = yDist / dist
        vectorX = cos * Config.projectileSpeed
        vectorY = sin * Config.projectileSpeed
        launched = true
    }

    // Set the bubble to be non snapping. Indicated with purple border.
    func setNonSnapping() {
        snapping = false
        view.layer.borderColor = UIColor.purple.cgColor
        view.layer.borderWidth = 2
        view.layer.masksToBounds = true
    }

    // Give projectile acceleration towards the given point.
    // Magnitude of acceleration is inversely proportional to the distance.
    func attractsTowards(_ point: CGPoint) {
        let xDiff = point.x - centerX
        let yDiff = point.y - centerY
        let dist = sqrt(pow(xDiff, 2) + pow(yDiff, 2))
        let unitVectorX = xDiff / dist
        let unitVectorY = yDiff / dist
        guard dist > 0 else {
            return
        }
        vectorX += Config.magneticAttraction * unitVectorX / dist
        vectorY += Config.magneticAttraction * unitVectorY / dist
    }

    // - MARK: Projectile movement methods.
    func moveForTime(_ duration: CGFloat) {
        view.frame.origin = CGPoint(x: leftX + vectorX * duration, y: topY + vectorY * duration)
    }
    func moveForDistance(_ distance: CGFloat) {
        view.frame.origin = CGPoint(x: leftX + distance * cos, y: topY + distance * sin)
    }
    func setOrigin(_ origin: CGPoint) {
        view.frame.origin = origin
    }
    // Move projectile such that x distance moved is specified.
    // Do nothing if it is impossible.
    func moveForX(_ distance: CGFloat) {
        guard cos != 0 else {
            return
        }
        view.frame.origin = CGPoint(x: leftX + distance, y: topY + distance * sin / cos)
    }
    // Move projectile such that y distance moved is specified.
    // Do nothing if it is impossible.
    func moveForY(_ distance: CGFloat) {
        guard sin != 0 else {
            return
        }
        view.frame.origin = CGPoint(x: leftX + distance * cos / sin, y: topY + distance)
    }
    // Stop the bubble.
    func stop() {
        cos = 0
        sin = 0
        vectorX = 0
        vectorY = 0
    }
    // Reverse the direction the bubble is travelling.
    func reverse() {
        cos *= -1
        vectorX *= -1
    }
}
