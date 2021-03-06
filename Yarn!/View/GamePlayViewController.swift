import UIKit
import AVFoundation
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

    var hitPlayer: AVAudioPlayer?
    let hitSoundFileName = ["hit", "wav"]

    @IBOutlet private var pointsView: UILabel!
    @IBOutlet private var canonView: UIImageView!
    @IBOutlet private var currentBubbleLabel: UILabel!
    @IBOutlet private var nextBubbleLabel: UILabel!
    @IBAction func backToDesigner(_ sender: Any) {
        displaylink?.invalidate()
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        gameEngine = GameEngine(radius: bubbleRadius, width: screenWidth, height: screenHeight, delegate: self)
        setCanonControl()
        canonView.layer.zPosition = 1
        setSoundPlayer()
        hitPlayer?.prepareToPlay()
    }

    /// Start game.
    override func viewDidAppear(_: Bool) {
        gameEngine.renderer.resetCanon(canonView)
        gameEngine.clear()
        gameEngine.startGame(initialBubbles, yarnLimit: yarnLimit)
    }

    func goBack() {
        gameEngine.clear()
        dismiss(animated: false, completion: nil)
    }

    /// If projectile is not launched,
    /// rotate the canon to face the point user tapped and launch projectile.
    @objc
    func tapCanon(_ sender: UITapGestureRecognizer) {
        let position = sender.location(in: view)
        guard !gameEngine.currentProjectile.launched && gameEngine.renderer.rotateCanon(canonView, to: position) else {
            return
        }
        launchProjectile(position)
    }

    /// Rotate the canon to face the point user is panning if projectile is not launched.
    /// Launch the projectile when pan ends.
    @objc
    func panCanon(_ sender: UIPanGestureRecognizer) {
        let state = sender.state
        guard state != .cancelled else {
            return
        }
        let targetPoint = sender.location(in: view)
        guard !gameEngine.currentProjectile.launched
            && gameEngine.renderer.rotateCanon(canonView, to: targetPoint) else {
            return
        }
        if sender.state == .ended {
            launchProjectile(targetPoint)
        }
    }

    func launchProjectile(_ targetPoint: CGPoint) {
        gameEngine.currentProjectile.setLaunchDirection(start: canonView.center, target: targetPoint)
        gameEngine.renderer.releaseCanon(canonView)
        addDisplaylink()
        playHitSound()
    }

    func setSoundPlayer() {
        guard let url = Bundle.main.url(forResource: hitSoundFileName[0], withExtension: hitSoundFileName[1]) else {
            return
        }
        do {
            hitPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
        } catch {
        }
    }

    func playHitSound() {
        DispatchQueue.global(qos: .background).async {
            if self.hitPlayer?.isPlaying ?? false {
                self.hitPlayer?.stop()
                self.hitPlayer?.currentTime = 0
            }
            self.hitPlayer?.play()
        }
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

    /// Set display link and update the previous frame time.
    func addDisplaylink() {
        displaylink = CADisplayLink(target: self, selector: #selector(step))
        displaylink.preferredFramesPerSecond = Config.framePerSecond
        displaylink.add(to: .current,
                        forMode: .defaultRunLoopMode)
        prevFrameTime = CACurrentMediaTime()
    }

    /// In each frame, update the projectile for the correspongding frame duration.
    @objc
    func step(displaylink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        gameEngine.moveProjectile(CGFloat(currentTime - prevFrameTime))
        prevFrameTime = currentTime
    }
}

// MARK: - GamePlayDelegate
extension GamePlayViewController: GamePlayDelegate {
    func updatePoints(_ points: String) {
        pointsView.text = points
    }

    /// Present the winning scene.
    func winGame(_ points: String) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: winIdentifier)
            as! GameResultViewController
        controller.pointString = points
        self.present(controller, animated: true, completion: nil)
    }

    /// Present the losing scene.
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
