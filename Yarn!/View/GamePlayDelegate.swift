import UIKit

protocol GamePlayDelegate: class {
    func addViewToScreen(_: UIView)
    func pauseGameLoop()
    func updateCurrentBubbleLabel(_: String)
    func updateNextBubbleLabel(_: String)
    var itemsAnimator: UIDynamicAnimator{ get }
}
