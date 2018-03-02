import UIKit

protocol GamePlayDelegate: class {
    func addViewToScreen(_: UIView)
    func pauseGameLoop()
    var itemsAnimator: UIDynamicAnimator{ get }
}
