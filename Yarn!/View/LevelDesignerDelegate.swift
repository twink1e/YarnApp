import UIKit

protocol LevelDesignerDelegate: class {
    func reloadGridCells(_: [IndexPath])
    func reloadGridView()
    func alertStorageError(_: String)
    func showSaveSuccess()
}
