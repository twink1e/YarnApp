import UIKit

class MenuViewController: UIViewController {
    @IBOutlet var musicToggleButton: UIButton!
    var appDelegate: AppDelegate?
    let onMusicLabel = "Music On"
    let offMusicLabel = "Music Off"

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        appDelegate = UIApplication.shared.delegate as? AppDelegate
    }
    @IBAction func toggleMusic(_ sender: Any) {
        guard let musicPlayer = appDelegate?.backgroundMusicPlayer else {
            return
        }
        if musicPlayer.isPlaying {
            musicPlayer.stop()
            musicToggleButton.setTitle(onMusicLabel, for: .normal)
        } else {
            appDelegate?.playMusic()
            musicToggleButton.setTitle(offMusicLabel, for: .normal)
        }
    }
}
