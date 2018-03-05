//  Created by Jun Ke Si on 31/1/18.
//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit
import AVFoundation
import PhysicsEngine
/**
 View Controller for the level designer scene.
 */
class LevelDesignerViewController: UIViewController {
    @IBOutlet private var gridView: UICollectionView!
    @IBOutlet private var resetButton: UIButton!
    @IBOutlet private var controlArea: UIView!
    @IBOutlet private var saveButton: UIButton!
    @IBOutlet private var nameTextField: UITextField!
    @IBOutlet private var startButton: UIButton!
    @IBOutlet private var yarnTextField: UITextField!
    @IBOutlet private var bubbleModifierButtons: [UIButton]!

    var viewModel: LevelDesignerViewModel!
    let reuseIdentifier = "hexGridCell"

    var cellWidth: CGFloat = 0
    var levelDesignCellWidth: CGFloat = 0
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    let collectionViewVerticalOffset: CGFloat = 6.5
    let emptyCellAlpha: CGFloat = 0.3

    var currentLevelId: Int?
    let saveSuccessMsg = "Level saved!"
    let saveFailMsg = "Fail to save level."
    let takeScreenshotSuccessMsg = "Screenshot saved!"
    let takeScreenshotFailMsg = "Fail to save screenshot."
    let createLabel = "Create"
    let updateLabel = "Update"
    let nameTextFieldTag = 0
    let yarnTextFieldTag = 1

    var popPlayer: AVAudioPlayer?
    let popSoundFileName = ["pop", "wav"]

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setViewModel()
        gridView.delegate = self
        gridView.dataSource = self
        setSaveAndStartControl()
        setLevelLockedControl()
        adjustGridSize()
        if !viewModel.isLevelLocked {
            addGestures()
        }
        setSoundPlayer()
        popPlayer?.prepareToPlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        gridView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let gamePlay = segue.destination as? GamePlayViewController {
            gamePlay.initialBubbles = gameBubbles
            gamePlay.bubbleRadius = cellWidth / 2.0
            gamePlay.screenWidth = screenWidth
            gamePlay.screenHeight = screenHeight
            gamePlay.yarnLimit = Int(yarnTextField.text!)!
        }
    }

    private func setSoundPlayer() {
        guard let url = Bundle.main.url(forResource: popSoundFileName[0], withExtension: popSoundFileName[1]) else {
            return
        }
        do {
            popPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
        } catch {
        }
    }

    private func setSaveAndStartControl() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateSaveAndStartEnabled(_:)),
                                               name: .UITextFieldTextDidChange, object: nameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSaveAndStartEnabled(_:)),
                                               name: .UITextFieldTextDidChange, object: yarnTextField)

        if currentLevelId != nil {
            saveButton.isEnabled = true
            startButton.isEnabled = true
            saveButton.setTitle(updateLabel, for: .normal)
            saveButton.setTitle(updateLabel, for: .disabled)
        } else {
            saveButton.isEnabled = false
            startButton.isEnabled = false
            saveButton.setTitle(createLabel, for: .normal)
            saveButton.setTitle(createLabel, for: .disabled)        }
    }

    private func setLevelLockedControl() {
        if !viewModel.isLevelLocked {
            return
        }
        controlArea.isHidden = true
        saveButton.isHidden = true
        resetButton.isHidden = true
        nameTextField.isEnabled = false
        yarnTextField.isEnabled = false
    }

    private func adjustGridSize() {
        screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        gridView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth)
        cellWidth = screenWidth / CGFloat(viewModel.gridColEvenRow)
        levelDesignCellWidth = cellWidth - Config.levelDesignCellWidthReduction
    }

    private func addGestures() {
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

    @IBAction func takeScreenshot(_ sender: Any) {
        guard let screenshot = gridScreenshot else {
            showToast(takeScreenshotFailMsg)
            return
        }
        UIImageWriteToSavedPhotosAlbum(screenshot, self, #selector(takeScreenshotResult(_:error:contextInfo:)), nil)
    }

    @objc
    func takeScreenshotResult(_ image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            showToast(takeScreenshotFailMsg)
        } else {
            showToast(takeScreenshotSuccessMsg)
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
                bubbles.append(GameBubble(color: cellModel.color, power: cellModel.power,
                                          view: views.first as! UIImageView))
            }
        }
        return bubbles
    }

    @objc
    func updateSaveAndStartEnabled(_: NSNotification) {
        guard let nameText = nameTextField.text, let yarnText = yarnTextField.text, !yarnText.isEmpty else {
            saveButton.isEnabled = false
            startButton.isEnabled = false
            return
        }
        startButton.isEnabled = true
        let trimmedText = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
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
        playPopSound()
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
        playPopSound()
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

    private func playPopSound() {
        DispatchQueue.global(qos: .background).async {
            if self.popPlayer?.isPlaying ?? false {
                self.popPlayer?.stop()
                self.popPlayer?.currentTime = 0
            }
            self.popPlayer?.play()
        }
    }
}

// MARK: - UITextFieldDelegate
extension LevelDesignerViewController: UITextFieldDelegate {

    /// Check if text length is too long or the yarn number is too large.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newText = (text as NSString).replacingCharacters(in: range, with: string)
        return textField.tag == nameTextFieldTag ? shouldNameChange(newText) : shouldYarnChange(newText)
    }

    private func shouldNameChange(_ newText: String) -> Bool {
        return newText.count <= Config.maxNameLength
    }

    private func shouldYarnChange(_ newText: String) -> Bool {
        if newText.isEmpty {
            return true
        }
        guard newText.count <= Config.maxYarnLength, let intVal = Int(newText) else {
            return false
        }
        return intVal <= Config.maxYarnLimit && intVal >= Config.minYarnLimit
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LevelDesignerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: levelDesignCellWidth, height: levelDesignCellWidth)
    }

    // Offset to make the grid looks nice.
    // No need to make sure there's no margin since it does not affect game play.
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        // To make the rows of bubbles closer.
        let verticalOffset = collectionViewVerticalOffset * CGFloat(section)
        // Horizontal margin for odd rows (0-indexed).
        return section % 2 == 0 ? UIEdgeInsets(top: -verticalOffset, left: 0, bottom: verticalOffset, right: 0) :
            UIEdgeInsets(top: -verticalOffset, left: levelDesignCellWidth / 2.0,
                         bottom: verticalOffset, right: levelDesignCellWidth / 2.0)
    }
}

// MARK: - UICollectionViewDataSource
extension LevelDesignerViewController: UICollectionViewDataSource {
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
            cell.backgroundColor = UIColor.white.withAlphaComponent(emptyCellAlpha)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension LevelDesignerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !viewModel.isLevelLocked else {
            return
        }
        viewModel.updateBubble(at: indexPath)
    }
}

// MARK: - LevelDesignerDelegate
extension LevelDesignerViewController: LevelDesignerDelegate {
    func setName(_ name: String) {
        nameTextField.text = name
    }

    func setYarnLimit(_ limit: Int) {
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
