// Copyright © 2018 nus.cs3217. All rights reserved.
import UIKit
import CoreData
import PhysicsEngine

/**
 View model for the level designer.
 It knows model, and transforms model data to be presented by view controller.
 It does not own controller, but update controller by callbacks.
 */
class LevelDesignerViewModel {
    let gridRow = 9
    let gridColEvenRow = 12
    var gridColOddRow: Int {
        return gridColEvenRow - 1
    }
    private(set) var grid: HexGrid
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
    var storage: Storage?
    var storedLevels: [NSManagedObject]? {
        return storage?.storedLevels
    }
    var currentLevelName: String?
    let storageLoadErrorMsg = "Can't load saved levels."
    let storageSaveErrorMsg = "Can't save level."

    var isErasing = false
    var currentColor: BubbleColor?
    var currentPower: BubblePower?
    var reloadGridView: (() -> Void)?
    var reloadGridCells: (([IndexPath]) -> Void)?
    var alertStorageError: ((String) -> Void)?
    var showSaveSuccess: (() -> Void)?

    init() {
        guard let grid = HexGrid(row: gridRow, col: gridColEvenRow) else {
            fatalError("Invalid grid size.")
        }
        self.grid = grid
    }

    // Init core data storage with the given context.
    func setStorage(_ managedContext: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Level", in: managedContext) else {
            alertStorageError?(storageLoadErrorMsg)
            return
        }
        do {
            try self.storage = Storage(managedContext, entity: entity)
        } catch {
            alertStorageError?(storageLoadErrorMsg)
        }
    }

    /// Save the current level, and execute the success and error callbacks accordingly.
    func saveLevel(_ name: String, screenshot: UIImage?) {
        do {
            try storage?.saveLevel(name, grid: grid, screenshot: screenshot)
            currentLevelName = name
            showSaveSuccess?()
        } catch {
            alertStorageError?(storageSaveErrorMsg)
        }
    }

    /// Load the selected stored level into the current grid, and execute the error callback if any error.
    /// Reload grid view if success.
    func setLevel(_ index: Int) {
        guard let gridString = storedLevels?[index].value(forKeyPath: "grid") as? String,
            let gridName = storedLevels?[index].value(forKeyPath: "name") as? String else {
            alertStorageError?("Level not found!")
            return
        }
        guard let gridData = gridString.data(using: .utf8) else {
            alertStorageError?("Fail to load level!")
            return
        }
        let jsonDecoder = JSONDecoder()
        do {
            let grid = try jsonDecoder.decode(HexGrid.self, from: gridData)
            self.grid = grid
            currentLevelName = gridName
            reloadGridView?()
        } catch {
            alertStorageError?("Level data is corrupted!")
        }
    }

    func deleteLevel(_ index: Int) {
        do {
            try storage?.deleteLevel(index)
        } catch {
            alertStorageError?("Can't delete level!")
        }
    }

    /// Erase or change the bubble color according to the current mode.
    func updateBubble(at indexPath: IndexPath?) {
        if isErasing {
            eraseBubble(at: indexPath)
        } else {
            setBubble(indexPath)
        }
    }

    func eraseBubble(at indexPath: IndexPath?) {
        guard let path = indexPath else {
            return
        }
        let row = path.section
        let col = path.row
        grid.removeBubble(rowIndex: row, colIndex: col)
        reloadGridCells?([path])
    }

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
        reloadGridCells?([path])
    }

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

    func reset() {
        grid.clearBubbles()
        reloadGridView?()
    }

    /// - return `HexGridCellViewModel` constructed from the bubble at the given location for UICollectionView.
    func getCollectionCellViewModel(at indexPath: IndexPath) -> HexGridCellViewModel {
        return HexGridCellViewModel(grid.bubbles[indexPath.section][indexPath.row])
    }

    /// - return `HistoryLevelsTableCellViewModel` constructed from the level at the given location for UITableView.
    func getTableCellViewModel(at indexPath: IndexPath) -> HistoryLevelsTableCellViewModel {
        return HistoryLevelsTableCellViewModel(storedLevels?[indexPath.row])
    }

    // Calculate the origin point of the bubble view if it is closely packed with no margin.
    func upperLeftCoord(for path: IndexPath, bubbleRadius: CGFloat) -> (CGFloat, CGFloat) {
        let row = path[0]
        let col = path[1]
        let leftOffset = row % 2 == 0 ? 0 : bubbleRadius
        let bubbleDiameter = bubbleRadius * 2
        let rowHeight = sqrt(3) * bubbleRadius
        return (leftOffset + CGFloat(col) * bubbleDiameter, CGFloat(row) * rowHeight)
    }
}
