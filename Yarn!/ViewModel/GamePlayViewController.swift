import UIKit
import PhysicsEngine

/**
 View Controller for the game play scene.
 */
class GamePlayViewController: UIViewController {
    var initialBubbles: [GameBubble] = []
    var gameEngine: GameEngine!
    var prevFrameTime: CFTimeInterval = 0
    var displaylink: CADisplayLink!

    @IBAction func backToDesigner(_ sender: Any) {
        displaylink?.invalidate()
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // Get the position of player's touch,
    // set launuch direction and resume game loop if projectile is not launched yet.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            if !gameEngine.projectile.launched {
                gameEngine.projectile.setLaunchDirection(position)
                addDisplaylink()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gameEngine.renderer.addViewToScreen = { [weak self] (_ view: UIView) in
            self?.view.addSubview(view)
        }
        gameEngine.renderer.removeViewFromScreen = { (_ view: UIView) in
            view.removeFromSuperview()
        }
        gameEngine.pauseGameLoop = { [weak self] in
            self?.displaylink.invalidate()
        }
        gameEngine.renderer.itemsAnimator = UIDynamicAnimator(referenceView: view)
        gameEngine.renderer.itemsAnimator?.delegate = gameEngine.renderer

        // Set game initial view
        gameEngine.buildGraph(initialBubbles)
        gameEngine.renderer.showCanon()
        gameEngine.addNewProjectile()
    }

    // Set display link and update the previous frame time.
    func addDisplaylink() {
        displaylink = CADisplayLink(target: self, selector: #selector(step))
        displaylink.preferredFramesPerSecond = Config.framePerSecond
        displaylink.add(to: .current,
                        forMode: .defaultRunLoopMode)
        prevFrameTime = CACurrentMediaTime()
    }

    @objc
    // In each frame, update the projectile for the correspongding frame duration.
    func step(displaylink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        gameEngine.moveProjectile(CGFloat(currentTime - prevFrameTime))
        prevFrameTime = currentTime
    }
}
