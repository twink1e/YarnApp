import UIKit
import PhysicsEngine

/**
 View Controller for the game play scene.
 */
class GamePlayViewController: UIViewController {
    let storyboardName = "Main"
    let winIdentifier = "win"
    let loseIdentifier = "lose"
    var initialBubbles: [GameBubble] = []
    var bubbleRadius: CGFloat = 0
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    var gameEngine: GameEngine!
    var prevFrameTime: CFTimeInterval = 0
    var displaylink: CADisplayLink!
    var yarnLimit: Int = 0

    @IBOutlet var pointsView: UILabel!
    @IBOutlet var canonView: UIImageView!
    @IBOutlet var currentBubbleLabel: UILabel!
    @IBOutlet var nextBubbleLabel: UILabel!
    @IBAction func backToDesigner(_ sender: Any) {
        displaylink?.invalidate()
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    func goBack() {
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }
    // If projectile is not launched,
    // rotate the canon to face the point user tapped and launch projectile.
    @objc func tapCanon(_ sender : UITapGestureRecognizer) {
        let position = sender.location(in: view)
        guard !gameEngine.currentProjectile.launched && gameEngine.renderer.rotateCanon(canonView, to: position) else {
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
        guard !gameEngine.currentProjectile.launched && gameEngine.renderer.rotateCanon(canonView, to: targetPoint) else {
            return
        }
        if sender.state == .ended {
            launchProjectile(targetPoint)
        }
    }

    private func launchProjectile(_ targetPoint: CGPoint) {
        gameEngine.currentProjectile.setLaunchDirection(start: canonView.center, target: targetPoint)
        gameEngine.renderer.releaseCanon(canonView)
        addDisplaylink()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        gameEngine = GameEngine(radius: bubbleRadius, width: screenWidth, height: screenHeight, delegate: self)
        setCanonControl()
        canonView.layer.zPosition = 1
    }

    override func viewDidAppear(_: Bool) {
        gameEngine.renderer.resetCanon(canonView)
        gameEngine.clear()
        gameEngine.startGame(initialBubbles, yarnLimit: yarnLimit)
    }

    func restartGame() {

        //gameEngine.startGame(initialBubbles, yarnLimit: yarnLimit)
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

extension GamePlayViewController: GamePlayDelegate {
    func updatePoints(_ points: String) {
        pointsView.text = points
    }
    
    func winGame(_ points: String) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: winIdentifier) as! GameResultViewController
        controller.pointString = points
        self.present(controller, animated: true, completion: nil)
    }

    func loseGame() {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: loseIdentifier)
        self.present(controller, animated: true, completion: nil)
    }

    func updateCurrentBubbleLabel(_ label: String) {
        currentBubbleLabel.text = label
    }

    func updateNextBubbleLabel(_ label: String) {
        nextBubbleLabel.text = label
    }

    func addViewToScreen (_ view: UIView) {
        self.view.addSubview(view)
    }

    func pauseGameLoop() {
        displaylink.invalidate()
    }

    var itemsAnimator: UIDynamicAnimator {
        return UIDynamicAnimator(referenceView: view)
    }

}
