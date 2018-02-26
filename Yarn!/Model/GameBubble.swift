import PhysicsEngine
import UIKit

extension GameBubble {
    func setNonSnapping() {
        snapping = false
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.masksToBounds = true
    }
}
