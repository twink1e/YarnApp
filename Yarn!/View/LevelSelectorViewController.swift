import UIKit

class LevelSelectorViewController: UICollectionViewController {
    let reuseIdentifier = "level"
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        
    }

    /// Present a toast with the given msg for 1 second.
    func showToast(_ msg: String?) {
        guard let msgToShow = msg else {
            return
        }
        let alert = UIAlertController(title: nil, message: msgToShow, preferredStyle: .alert)
        present(alert, animated: true)
        let duration: Double = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            alert.dismiss(animated: true)
        }
    }
}

extension LevelSelectorViewController: LevelSelectorDelegate {
    func reloadGridView() {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

    func alertStorageError(_ msg: String) {
        self.showToast(msg)
    }
}
