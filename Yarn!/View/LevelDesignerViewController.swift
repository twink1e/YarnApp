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
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var yarnTextField: UITextField!
    @IBOutlet private var bubbleModifierButtons: [UIButton]!
    var viewModel: LevelDesignerViewModel!
    let reuseIdentifier = "hexGridCell"
    var cellWidth: CGFloat = 0
    var levelDesignCellWidth: CGFloat = 0
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    var currentLevelId: Int?
    let saveSuccessMsg = "Level saved!"
    let saveFailMsg = "Fail to save level..."
    let maxNameLength = 20
    let maxYarnLength = 3
    let nameTextFieldTag = 0
    let yarnTextFieldTag = 1
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        setViewModel()

        gridView.delegate = self
        gridView.dataSource = self

        saveButton.isEnabled = false
        NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange,
                                               object:nameTextField, queue: OperationQueue.main) { _ in self.updateSaveAndStartEnabled() }
        NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange,
                                               object:yarnTextField, queue: OperationQueue.main) { _ in self.updateSaveAndStartEnabled() }

        // Customise grid according to screensize.
        screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        gridView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth)
        cellWidth = screenWidth / CGFloat(viewModel.gridColEvenRow)
        levelDesignCellWidth = cellWidth - Config.levelDesignCellWidthReduction

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

    @IBAction func goBack(_ sender: Any) {
        dismiss(animated: false, completion: nil)
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
            gamePlay.bubbleRadius = cellWidth / 2.0
            gamePlay.screenWidth = screenWidth
            gamePlay.screenHeight = screenHeight
        }
    }

    // All non-empty bubbles in their grid positions with no margin in between.
    private var gameBubbles: [GameBubble] {
        var bubbles: [GameBubble] = []

        for i in 0 ..< viewModel.gridRow {
            for j in 0 ..< (i % 2 == 0 ? viewModel.gridColEvenRow : viewModel.gridColOddRow) {
                let cellModel = viewModel.getCollectionCellViewModel(at: [i, j])
                guard cellModel.type != nil, let cell = gridView.cellForItem(at: [i, j]) else {
                    continue
                }
                let views = cell.contentView.subviews.filter { $0 is UIImageView }
                let (actualX, actualY) = viewModel.upperLeftCoord(for: [i, j], bubbleRadius: cellWidth / 2.0)
                views.first?.frame = CGRect(x: actualX, y: actualY, width: cellWidth, height: cellWidth)
                bubbles.append(GameBubble(color: cellModel.color, power: cellModel.power, view: views.first as! UIImageView))
            }
        }
        return bubbles
    }

    func updateSaveAndStartEnabled() {
        guard let nameText = nameTextField.text, let yarnText = yarnTextField.text, !yarnText.isEmpty else {
            saveButton.isEnabled = false
            startButton.isEnabled = false
            return
        }
        startButton.isEnabled = true
        let trimmedText = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        nameTextField.text = trimmedText
        if !trimmedText.isEmpty {
            saveButton.isEnabled = true
        }
    }

    func setViewModel() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        viewModel = LevelDesignerViewModel(self, context: managedContext, levelId: currentLevelId)
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

    /// Update bubbles that have been touched while dragging if a color or power is selected.
    @objc
    func gridViewPanned(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: gridView)
        let indexPath = gridView.indexPathForItem(at: locationInView)
        guard viewModel.currentColor != nil || viewModel.currentPower != nil || viewModel.isErasing else {
            return
        }
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
        viewModel.currentPower = nil
        viewModel.isErasing = false
    }

    /// Enter erase mode.
    @IBAction func eraserPressed(_ sender: UIButton) {
        viewModel.isErasing = true
        viewModel.currentColor = nil
        viewModel.currentPower = nil
    }

    /// Update the current selected bubble type.
    @IBAction func bubbleSelectorPressed(_ button: UIButton) {
        viewModel.isErasing = false
        if let color = viewModel.tagToColor[button.tag] {
            viewModel.currentColor = color
            viewModel.currentPower = nil
        } else if let power = viewModel.tagToPower[button.tag] {
            viewModel.currentColor = nil
            viewModel.currentPower = power
        }
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
        guard let name = nameTextField.text, let yarn = yarnTextField.text, let yarnLimit = Int(yarn) else {
            showToast(saveFailMsg)
            return
        }
        self.viewModel.saveLevel(name, yarnLimit: yarnLimit, screenshot: self.gridScreenshot)
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
        let newText = (text as NSString).replacingCharacters(in: range, with: string)
        return textField.tag == nameTextFieldTag ? shouldNameChange(newText) : shouldYarnChange(newText)
    }

    private func shouldNameChange(_ newText: String) -> Bool {
        return newText.count <= maxNameLength
    }

    private func shouldYarnChange(_ newText: String) -> Bool {
        guard newText.count <= maxNameLength, let intVal = Int(newText) else {
            return false
        }
        return intVal <= 999 && intVal >= 1
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

extension LevelDesignerViewController: LevelDesignerDelegate {
    func setName(_ name: String) {
        nameTextField.text = name
    }

    func setYarnLimit(_ limit : Int) {
        yarnTextField.text = String(limit)
    }

    func reloadGridCells(_ paths: [IndexPath]) {
        DispatchQueue.main.async {
            self.gridView.reloadItems(at: paths)
        }
    }

    func reloadGridView() {
        DispatchQueue.main.async {
            self.gridView.reloadData()
        }
    }

    func alertStorageError(_ msg: String) {
        self.showToast(msg)
    }

    func showSaveSuccess() {
        self.showToast(self.saveSuccessMsg)
    }
}
