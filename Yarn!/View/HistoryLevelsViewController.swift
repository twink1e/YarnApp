//  Created by Jun Ke Si on 9/2/18.
//  Copyright © 2018 nus.cs3217. All rights reserved.

import UIKit

/**
 View controller for UITableView that displays stored levels.
 */
class HistoryLevelsViewController: UITableViewController {
    var viewModel: LevelDesignerViewModel!
    let reuseIdentifier = "level"

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.storedLevels?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {
            let cell =
                tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                              for: indexPath) as! HistoryLevelsTableViewCell
            let levelViewModel = viewModel.getTableCellViewModel(at: indexPath)
            cell.name.text = levelViewModel.name
            cell.overviewImage.image = levelViewModel.image
            cell.createdAt.text = levelViewModel.createdAt
            cell.updatedAt.text = levelViewModel.updatedAt
            cell.deleteButton.tag = indexPath.row
            cell.deleteButton.addTarget(self, action: #selector(deleteLevel(_:)), for: .touchUpInside)
            return cell
    }

    @objc
    func deleteLevel(_ sender: UIButton) {
        viewModel.deleteLevel(sender.tag)
        tableView.reloadData()
    }

    /// Close the pop-over view after a level is selected, and tell view model to update level.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.presentingViewController!.dismiss(animated: true)
        viewModel.setLevel(indexPath.row)
    }
}
