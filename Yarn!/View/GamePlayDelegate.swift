import UIKit

protocol GamePlayDelegate: class {
    func addViewToScreen(_: UIView)
    func pauseGameLoop()
    func updateCurrentBubbleLabel(_: String)
    func updateNextBubbleLabel(_: String)
    func updatePoints(_: String)
    func winGame(_: String)
    func loseGame()
    var itemsAnimator: UIDynamicAnimator{ get }
}
