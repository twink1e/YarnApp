import UIKit

class LevelSelectorViewController: UIViewController {
    let reuseIdentifier = "level"
    let storyBoardName = "Main"
    let designerIdentifier = "designer"
    var viewModel: LevelSelectorViewModel!
    @IBOutlet var levelsView: UICollectionView!
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        viewModel = LevelSelectorViewModel(self, context: managedContext)
        levelsView.delegate = self
        levelsView.dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        levelsView.reloadData()
    }

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: false, completion: nil)
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

extension LevelSelectorViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {

    

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.levels.count
    }

    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! LevelSelectorViewCell
        let index = indexPath.row
        guard index < viewModel.levels.count else {
            return cell
        }
        cell.setContent(viewModel.levels[index], tag: index, delegate: self)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let designerController = UIStoryboard(name: storyBoardName, bundle: nil).instantiateViewController(withIdentifier: designerIdentifier) as! LevelDesignerViewController
        designerController.currentLevelId = viewModel.levelIdAtIndex(indexPath.row)
        present(designerController, animated: false, completion: nil)
    }
}
extension LevelSelectorViewController: LevelSelectorDelegate {
    func reloadGridView() {
        DispatchQueue.main.async {
            self.levelsView.reloadData()
        }
    }

    func alertStorageError(_ msg: String) {
        self.showToast(msg)
    }

    func deleteLevel(_ index: Int) {
        viewModel.deleteLevel(index)
        levelsView.reloadData()
    }
}
