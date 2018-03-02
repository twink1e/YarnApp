import UIKit

class GameResultViewController: UIViewController {
    var pointString = ""
    @IBOutlet var pointsView: UILabel?
    @IBAction func retry(_ sender: Any) {
        if let presenter = presentingViewController as? GamePlayViewController {
            presenter.restartGame()
        }
        dismiss(animated: true, completion: nil)
    }
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        if let presenter = presentingViewController as? GamePlayViewController {
            presenter.goBack()
        }
    }

    override func viewDidLoad() {
        pointsView?.text = pointString
    }
}
