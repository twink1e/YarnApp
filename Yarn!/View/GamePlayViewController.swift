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
    @IBOutlet var canonView: UIImageView!
    @IBAction func backToDesigner(_ sender: Any) {
        displaylink?.invalidate()
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // If projectile is not launched,
    // rotate the canon to face the point user tapped and launch projectile.
    @objc func tapCanon(_ sender : UITapGestureRecognizer) {
        let position = sender.location(in: view)
        guard !gameEngine.projectile.launched && gameEngine.renderer.rotateCanon(canonView, to: position) else {
            return
        }
        launchProjectile(position)
    }

    // Rotate the canon to face the point user is panning if projectile is not launched.
    // Launch the projectile when pan ends.
    @objc func panCanon(_ sender : UIPanGestureRecognizer) {
        let state = sender.state
        guard state != .cancelled else {
            return
        }
        let targetPoint = sender.location(in: view)
        guard !gameEngine.projectile.launched && gameEngine.renderer.rotateCanon(canonView, to: targetPoint) else {
            return
        }
        if sender.state == .ended {
            launchProjectile(targetPoint)
        }
    }

    private func launchProjectile(_ targetPoint: CGPoint) {
        gameEngine.projectile.setLaunchDirection(start: canonView.center, target: targetPoint)
        gameEngine.renderer.releaseCanon(canonView)
        addDisplaylink()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gameEngine.renderer.addViewToScreen = { [weak self] (_ view: UIView)  in
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
        setCanonControl()
        canonView.layer.zPosition = 1
        view.addSubview(canonView)
        gameEngine.addNewProjectile()
    }

    func setCanonControl() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panCanon(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapCanon(_:)))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
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
