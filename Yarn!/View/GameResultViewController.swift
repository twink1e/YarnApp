import UIKit
import AVFoundation

/**
 View controller for the game result (win and lose) scenes.
 */
class GameResultViewController: UIViewController {
    var pointString = ""
    var meowPlayer: AVAudioPlayer?
    let meowSoundFileName = ["meow", "wav"]

    override func viewDidAppear(_ animated: Bool) {
        playMeowSound()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        pointsView?.text = pointString
    }

    private func playMeowSound() {
        guard let url = Bundle.main.url(forResource: meowSoundFileName[0], withExtension: meowSoundFileName[1]) else {
            return
        }
        do {
            meowPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            meowPlayer?.prepareToPlay()
            meowPlayer?.play()
        } catch {
        }
    }

    @IBOutlet private var pointsView: UILabel?

    @IBAction func retry(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        if let presenter = presentingViewController as? GamePlayViewController {
                        presenter.viewDidAppear(false)
        }
    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        if let presenter = presentingViewController as? GamePlayViewController {
            presenter.goBack()
        }
    }
}
