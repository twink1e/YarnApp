import UIKit
import CoreData
import PhysicsEngine

/**
 View model for the level designer.
 Responsible for the hexgrid data handling and storage.
 */
class LevelDesignerViewModel {
    var grid: HexGrid
    var storage: Storage
    weak var levelDesignerDelegate: LevelDesignerDelegate?

    // Grid data.
    let gridRow = Config.gridRow
    let gridColEvenRow = Config.gridColEvenRow
    var gridColOddRow: Int {
        return gridColEvenRow - 1
    }

    // Bubble selector controls.
    let colors: [BubbleColor] = [.red, .orange, .green, .blue]
    var powers: [BubblePower] = [.indestructible, .magnetic, .bomb, .lightning, .star]
    let tagToColor: [Int: BubbleColor] = [
        0: .red,
        1: .orange,
        2: .green,
        3: .blue
    ]
    let tagToPower: [Int: BubblePower] = [
        4: .indestructible,
        5: .magnetic,
        6: .bomb,
        7: .lightning,
        8: .star
    ]
    var isErasing = false
    var currentColor: BubbleColor?
    var currentPower: BubblePower?

    // Storage constants.
    let storageSetErrorMsg = "Can't access storage."
    let storageSaveErrorMsg = "Can't save level."
    let storageLoadErrorMsg = "Can't load level."

    // Current level information.
    var currentLevel: NSManagedObject?
    var isLevelLocked: Bool {
        guard let level = currentLevel else {
            return false
        }
        return level.value(forKey: Storage.lockedKey) as? Bool ?? false
    }

    /// Init a `LevelDesignerViewModel` with a `LevelDesignerDelegate` responsible for view updating,
    /// `context` for storage, and an optional `levelId` if the grid data should be read from storage.
    init(_ delegate: LevelDesignerDelegate, context: NSManagedObjectContext, levelId: Int?) {
        guard let grid = HexGrid(row: gridRow, col: gridColEvenRow) else {
            fatalError("Invalid grid size.")
        }
        self.grid = grid
        levelDesignerDelegate = delegate
        storage = Storage(context)
        if let id = levelId {
            setLevel(id)
        }
    }

    /// Save the current level, and execute the success and error callbacks accordingly.
    func saveLevel(_ name: String, yarnLimit: Int, screenshot: UIImage?) {
        do {
            if let level = currentLevel {
                try storage.overwriteLevel(level, name: name, yarnLimit: yarnLimit, grid: grid, screenshot: screenshot)
            } else {
                try storage.saveNewLevel(name, yarnLimit: yarnLimit, grid: grid, screenshot: screenshot)
            }
            levelDesignerDelegate?.showSaveSuccess()
        } catch {
            levelDesignerDelegate?.alertStorageError(storageSaveErrorMsg)
        }
    }

    /// Clear grid data.
    func reset() {
        grid.clearBubbles()
        levelDesignerDelegate?.reloadGridView()
    }

    /// Return `HexGridCellViewModel` constructed from the bubble at the given location for UICollectionView.
    func getCollectionCellViewModel(at indexPath: IndexPath) -> HexGridCellViewModel {
        return HexGridCellViewModel(grid.bubbles[indexPath.section][indexPath.row])
    }

    /// Erase or change the bubble color according to the current mode.
    func updateBubble(at indexPath: IndexPath?) {
        if isErasing {
            eraseBubble(at: indexPath)
        } else {
            setBubble(indexPath)
        }
    }

    /// Clear the bubble at the given `indexPath`.
    func eraseBubble(at indexPath: IndexPath?) {
        guard let path = indexPath else {
            return
        }
        let row = path.section
        let col = path.row
        grid.removeBubble(rowIndex: row, colIndex: col)
        levelDesignerDelegate?.reloadGridCells([path])
    }

    /// Calculate the origin point of the bubble view if it is closely packed with no margin.
    func upperLeftCoord(for path: IndexPath, bubbleRadius: CGFloat) -> (CGFloat, CGFloat) {
        let row = path[0]
        let col = path[1]
        let leftOffset = row % 2 == 0 ? 0 : bubbleRadius
        let bubbleDiameter = bubbleRadius * 2
        let rowHeight = sqrt(3) * bubbleRadius
        return (leftOffset + CGFloat(col) * bubbleDiameter, CGFloat(row) * rowHeight)
    }

    // Load the selected stored level into the current grid, and execute the error callback if any error.
    // Reload grid view if success.
    private func setLevel(_ levelId: Int) {
        do {
            try currentLevel = storage.levelWithId(levelId)
        } catch {
            levelDesignerDelegate?.alertStorageError(storageSaveErrorMsg)
        }
        guard let gridString = currentLevel?.value(forKeyPath: Storage.gridKey) as? String,
            let name = currentLevel?.value(forKeyPath: Storage.nameKey) as? String,
            let yarnLimit = currentLevel?.value(forKeyPath: Storage.yarnKey) as? Int else {
                levelDesignerDelegate?.alertStorageError(storageLoadErrorMsg)
                return
        }
        levelDesignerDelegate?.setName(name)
        levelDesignerDelegate?.setYarnLimit(yarnLimit)
        setGridWithString(gridString)
    }

    private func setGridWithString(_ gridString: String) {
        guard let gridData = gridString.data(using: .utf8) else {
            levelDesignerDelegate?.alertStorageError(storageLoadErrorMsg)
            return
        }
        let jsonDecoder = JSONDecoder()
        do {
            let grid = try jsonDecoder.decode(HexGrid.self, from: gridData)
            self.grid = grid
            levelDesignerDelegate?.reloadGridView()
        } catch {
            levelDesignerDelegate?.alertStorageError(storageLoadErrorMsg)
        }
    }

    // Update bubble according to the current bubble modifier mode.
    private func setBubble(_ indexPath: IndexPath?) {
        guard let path = indexPath else {
            return
        }
        let row = path.section
        let col = path.row
        if let color = currentColor {
            grid.setColoredBubble(rowIndex: row, colIndex: col, color: color)
        } else if let power = currentPower {
            grid.setSpecialBubble(rowIndex: row, colIndex: col, power: power)
        } else {
            setToNextBubble(row, col)
        }
        levelDesignerDelegate?.reloadGridCells([path])
    }

    // Set the bubble at the given row and col position to the next bubble in the all-bubble loop.
    private func setToNextBubble(_ row: Int, _ col: Int) {
        if let currentColor = getBubbleColor(row, col) {
            guard let currentColorIndex = colors.index(of: currentColor) else {
                return
            }
            setToNextBubbleFromIndex(row, col, currentIndex: currentColorIndex, currentType: .colored)
        } else if let currentPower = getBubblePower(row, col) {
            guard let currentPowerIndex = powers.index(of: currentPower) else {
                return
            }
            setToNextBubbleFromIndex(row, col, currentIndex: currentPowerIndex, currentType: .special)
        }
    }

    // Set the bubble at the given row and col position to the next bubble in the all-bubble loop,
    // given its current bubble type type, and its index in the color or type array.
    private func setToNextBubbleFromIndex(_ row: Int, _ col: Int, currentIndex: Int, currentType: BubbleType) {
        var nextIndex = currentIndex + 1
        var nextType = currentType
        if currentType == .colored && nextIndex >= colors.count {
            nextType = .special
            nextIndex = 0
        } else if currentType == .special && nextIndex >= powers.count {
            nextType = .colored
            nextIndex = 0
        }
        if nextType == .colored {
            grid.setColoredBubble(rowIndex: row, colIndex: col, color: colors[nextIndex])
        } else if nextType == .special {
            grid.setSpecialBubble(rowIndex: row, colIndex: col, power: powers[nextIndex])
        }
    }

    private func getBubbleColor(_ row: Int, _ col: Int) -> BubbleColor? {
        let bubble = grid.getBubble(rowIndex: row, colIndex: col) as? ColoredBubble
        return bubble?.color
    }

    private func getBubblePower(_ row: Int, _ col: Int) -> BubblePower? {
        let bubble = grid.getBubble(rowIndex: row, colIndex: col) as? SpecialBubble
        return bubble?.power
    }
}
