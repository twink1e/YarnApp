import UIKit
import AVFoundation

class GameResultViewController: UIViewController {
    var pointString = ""
    var meowPlayer: AVAudioPlayer?

    override func viewDidAppear(_ animated: Bool) {
        playMeowSound()
    }

    private func playMeowSound() {
        guard let url = Bundle.main.url(forResource: "meow", withExtension: "wav") else {
            return
        }
        do {
//            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
//            try AVAudioSession.sharedInstance().setActive(true)
            meowPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            meowPlayer?.prepareToPlay()
            meowPlayer?.play()
        } catch {
        }
    }
    @IBOutlet var pointsView: UILabel?
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
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        pointsView?.text = pointString
    }
}
