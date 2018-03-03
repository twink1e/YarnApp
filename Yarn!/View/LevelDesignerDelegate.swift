import UIKit

protocol LevelDesignerDelegate: class {
    func reloadGridCells(_: [IndexPath])
    func reloadGridView()
    func alertStorageError(_: String)
    func showSaveSuccess()
    func setName(_: String)
    func setYarnLimit(_: Int)
}
