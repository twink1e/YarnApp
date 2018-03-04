import UIKit

class GameResultViewController: UIViewController {
    var pointString = ""
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
