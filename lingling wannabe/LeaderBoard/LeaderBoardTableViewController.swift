//
//  LeaderBoardTableViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 6/4/21.
//

import UIKit

struct player {
    var username: String
    var hours: Float
}

class LeaderBoardTableViewController : UITableViewController {
    
    let interval : interval
    
    var count = 128
    let batchSize = 128
    var rank: [player] = Array(unsafeUninitializedCapacity: 2048, initializingWith: {ptr, size in print(ptr, size) })
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(interval: interval) {
        self.interval = interval
        super.init(style: .plain)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: "LoadingCell")
        tableView.register(LeaderBoardCell.self, forCellReuseIdentifier: "TableCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.bounces = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            cell.loading.startAnimating()
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! LeaderBoardCell
        cell.backgroundColor = .white
        cell.rank.text = String(indexPath.row)
        cell.username.text = "abcdefghijklmnopqrstuvwxyz0123456789"
        cell.hours.text = "40"
        return cell
    }
    
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let visible = tableView.indexPathsForVisibleRows else { return }
        for idx in visible {
            if idx.row == count - 1 { addData(); break }
        }
    }
    
    private func addData() {
        var idxs = [IndexPath]()
        for _ in count..<count+batchSize {
            idxs.append(IndexPath(row: count, section: 0))
            count += 1
        }
        tableView.insertRows(at: idxs, with: .automatic)
    }
    
}
