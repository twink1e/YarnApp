//  Created by Jun Ke Si on 31/1/18.
//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit
import PhysicsEngine
/**
 View Controller for the level designer scene.
 */
class LevelDesignerViewController: UIViewController {
    @IBOutlet private var gridView: UICollectionView!
    @IBOutlet private var resetButton: UIButton!
    @IBOutlet private var controlArea: UIView!
    @IBOutlet private var saveButton: UIButton!
    @IBOutlet private var bubbleModifierButtons: [UIButton]!
    var viewModel = LevelDesignerViewModel()
    var gameEngine: GameEngine!
    let reuseIdentifier = "hexGridCell"
    var cellWidth: CGFloat = 0
    var levelDesignCellWidth: CGFloat = 0

    let saveLevelAlertTitle = "Save Level"
    let saveLevelAlertMsg = "Enter name (max 15 characters).\nOld level will be overwritten if the name is the same."
    let saveSuccessMsg = "Level saved!"
    let saveButtonText = "Save"
    let cancelButtonText = "Cancel"
    let maxNameLength = 15
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Delegate methods to the view model.
        viewModel.reloadGridCells = { [weak self] (_ paths: [IndexPath]) in
            DispatchQueue.main.async {
                self?.gridView.reloadItems(at: paths)
            }
        }
        viewModel.reloadGridView = { [weak self] () in
            DispatchQueue.main.async {
                self?.gridView.reloadData()
            }
        }
        viewModel.alertStorageError = { [weak self] (_ msg: String) in
            self?.showToast(msg)
        }
        viewModel.showSaveSuccess = { [weak self] in
            self?.showToast(self?.saveSuccessMsg)
        }
        loadStorageWithContext()

        gridView.delegate = self
        gridView.dataSource = self

        // Customise grid according to screensize.
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        gridView.frame = CGRect(x: 0, y: 20, width: screenWidth, height: screenWidth)
        cellWidth = screenWidth / CGFloat(viewModel.gridColEvenRow)
        levelDesignCellWidth = cellWidth - Config.levelDesignCellWidthReduction
        gameEngine = GameEngine(radius: cellWidth / 2.0, width: screenWidth, height: screenHeight)

        // Gesture recognisers.
        let gridViewPanGesture = UIPanGestureRecognizer(target: self, action: #selector(gridViewPanned(_:)))
        gridViewPanGesture.minimumNumberOfTouches = 1
        gridViewPanGesture.maximumNumberOfTouches = 1
        gridView.addGestureRecognizer(gridViewPanGesture)

        let controlAreaTapGesture = UITapGestureRecognizer(target: self, action: #selector(controlAreaTapped(_:)))
        controlArea.addGestureRecognizer(controlAreaTapGesture)

        let gridViewLongPressGesture = UILongPressGestureRecognizer(target: self,
                                                                    action: #selector(gridViewLongPresed(_:)))
        gridView.addGestureRecognizer(gridViewLongPressGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        gridView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let historyLevels = segue.destination as? HistoryLevelsViewController {
            historyLevels.viewModel = viewModel
        } else if let gamePlay = segue.destination as? GamePlayViewController {
            gamePlay.initialBubbles = gameBubbles
            gamePlay.gameEngine = gameEngine
        }
    }

    // All non-empty bubbles in their grid positions with no margin in between.
    private var gameBubbles: [GameBubble] {
        var bubbles: [GameBubble] = []

        for i in 0 ..< viewModel.gridRow {
            for j in 0 ..< (i % 2 == 0 ? viewModel.gridColEvenRow : viewModel.gridColOddRow) {
                let cellModel = viewModel.getCollectionCellViewModel(at: [i, j])
                guard let color = cellModel.color, let cell = gridView.cellForItem(at: [i, j]) else {
                    continue
                }
                let views = cell.contentView.subviews.filter { $0 is UIImageView }
                let (actualX, actualY) = gameEngine.renderer.upperLeftCoord(for: [i, j])
                views[0].frame = CGRect(x: actualX, y: actualY, width: cellWidth, height: cellWidth)
                bubbles.append(GameBubble(color: color, view: views[0] as! UIImageView))
            }
        }
        return bubbles
    }

    func loadStorageWithContext() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        viewModel.setStorage(managedContext)
    }
    /// - return UIImage of the grid view with bubbles.
    var gridScreenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(gridView.bounds.size, gridView.isOpaque, 0.0)
        gridView.drawHierarchy(in: gridView.bounds, afterScreenUpdates: true)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
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

    /// Update bubbles that have been touched while dragging.
    @objc
    func gridViewPanned(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: gridView)
        let indexPath = gridView.indexPathForItem(at: locationInView)
        viewModel.updateBubble(at: indexPath)
    }

    /// Delete the bubble which has been long pressed.
    @objc
    func gridViewLongPresed(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: gridView)
        let indexPath = gridView.indexPathForItem(at: locationInView)
        viewModel.eraseBubble(at: indexPath)
    }

    /// Set the current selected bubble type to none.
    @objc
    func controlAreaTapped(_ sender: UITapGestureRecognizer) {
        for button in bubbleModifierButtons {
            button.transform = CGAffineTransform.identity
        }
        viewModel.currentColor = nil
        viewModel.isErasing = false
    }

    /// Enter erase mode.
    @IBAction func eraserPressed(_ sender: UIButton) {
        viewModel.isErasing = true
        viewModel.currentColor = nil
    }

    /// Update the current selected bubble type.
    @IBAction func bubbleSelectorPressed(_ button: UIButton) {
        viewModel.isErasing = false
        viewModel.currentColor = viewModel.colors[button.tag]
    }

    /// Show which bubble type is currently selected with animation.
    @IBAction func bubbleModifierSelected(_ sender: UIButton) {
        for button in bubbleModifierButtons {
            button.transform = CGAffineTransform.identity
            if button.isHighlighted {
                button.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            }
        }
    }

    /// Prompt user to enter a valid name for the level to be saved.
    /// The name cannot be empty, nor more than 15 characters long.
    @IBAction func saveButtonPressed(_ button: UIButton) {
        let alert = UIAlertController(title: saveLevelAlertTitle, message: saveLevelAlertMsg, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: saveButtonText, style: .default) { [unowned self] _ in
            guard let textField = alert.textFields?[0], let name = textField.text else {
                return
            }
            self.viewModel.saveLevel(name, screenshot: self.gridScreenshot)

        }
        let cancelAction = UIAlertAction(title: cancelButtonText, style: .default)

        alert.addTextField { [unowned self] textField in
            if let name = self.viewModel.currentLevelName {
                textField.text = name
            } else {
                saveAction.isEnabled = false
            }
        }
        alert.textFields?[0].delegate = self
        NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange,
                                               object:alert.textFields?[0], queue: OperationQueue.main) { _ -> Void in
            let name = alert.textFields?[0]
            saveAction.isEnabled = !(name?.text?.isEmpty ?? true)
        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }

    /// Clear the grid of bubbles.
    @IBAction func resetButtonPressed(_ button: UIButton) {
        viewModel.reset()
    }
}
extension LevelDesignerViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= maxNameLength
    }
}

extension LevelDesignerViewController: UICollectionViewDelegateFlowLayout,
UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.gridRow
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section % 2 == 0 ? viewModel.gridColEvenRow : viewModel.gridColOddRow
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! HexGridViewCell
        let cellViewModel = viewModel.getCollectionCellViewModel(at: indexPath)
        if let background = cellViewModel.background {
            let bubbleImage = UIImageView()
            bubbleImage.image = background
            bubbleImage.frame = CGRect(x: 0, y: 0, width: levelDesignCellWidth, height: levelDesignCellWidth)
            cell.contentView.addSubview(bubbleImage)
        } else {
            cell.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.updateBubble(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: levelDesignCellWidth, height: levelDesignCellWidth)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        // To make the rows of bubbles closer.
        let verticalOffset = 6.5 * CGFloat(section)
        // Horizontal margin for odd rows (0-indexed).
        return section % 2 == 0 ? UIEdgeInsets(top: -verticalOffset, left: 0, bottom: verticalOffset, right: 0) :
            UIEdgeInsets(top: -verticalOffset, left: levelDesignCellWidth / 2.0,
                         bottom: verticalOffset, right: levelDesignCellWidth / 2.0)
    }
}
