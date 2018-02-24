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

    var storage: Storage?
    var storedLevels: [NSManagedObject]? {
        return storage?.storedLevels
    }
    var currentLevelName: String?
    let storageLoadErrorMsg = "Can't load saved levels."
    let storageSaveErrorMsg = "Can't save level."

    var isErasing = false
    var currentColor: BubbleColor?
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
            colorBubble(indexPath)
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

    private func colorBubble(_ indexPath: IndexPath?) {
        guard let path = indexPath else {
            return
        }
        let row = path.section
        let col = path.row
        guard let color = currentColor ?? getNextColor(row, col) else {
            return
        }
        grid.setColoredBubble(rowIndex: row, colIndex: col, color: color)
        reloadGridCells?([path])
    }

    private func getNextColor(_ row: Int, _ col: Int) -> BubbleColor? {
        guard let currentColor = getBubbleColor(row, col) else {
            return nil
        }
        guard let currentColorIndex = colors.index(of: currentColor) else {
            return nil
        }
        return colors[(currentColorIndex + 1) % colors.count]
    }

    private func getBubbleColor(_ row: Int, _ col: Int) -> BubbleColor? {
        let bubble = grid.getBubble(rowIndex: row, colIndex: col) as? ColoredBubble
        return bubble?.color
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
}
