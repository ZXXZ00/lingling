//
//  InstrumentSelectionViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 2/22/22.
//

import UIKit

class InstrumentSelectionViewController: UITableViewController {
    
    let instruments = ["Bass Guiter", "Basson", "Cello", "Clarinet", "Double Bass", "Flute", "Guiter", "Harp", "Horn", "Oboe", "Percussion", "Piano", "Saxophone", "Trombone", "Trumpet", "Tuba", "Viola", "Violin", "Voice", "Other"]
    let headerHeight: CGFloat = 50
    
    var didSelected: (()->Void)?
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "InstrumentCell")
        tableView.allowsMultipleSelection = true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instruments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InstrumentCell", for: indexPath)
        cell.textLabel?.text = instruments[indexPath.row]
        cell.backgroundColor = cell.isSelected ? UIColor(white: 0.9, alpha: 1) : .white
        cell.textLabel?.textColor = .black
        cell.textLabel?.font = UIFont(name: "AmericanTypewriter", size: 17)
        let bgView = UIView()
        bgView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        cell.selectedBackgroundView = bgView
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        //headerView.backgroundColor = .clear
        // frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: headerHeight)
        let title = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: headerHeight))
        title.text = "    What instrument(s) do you play"
        title.backgroundColor = UIColor(white: 0.83, alpha: 1)
        title.textColor = .black
        title.font = UIFont(name: "AmericanTypewriter", size: 17)
        headerView.addSubview(title)
        //title.translatesAutoresizingMaskIntoConstraints = false
        //title.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true
        //title.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true
        print(tableView.frame)
        let submit = UIButton(frame: CGRect(x: tableView.frame.width-100, y: 5, width: 80, height: 40))
        submit.layer.borderWidth = 1
        submit.layer.cornerRadius = 10
        submit.setTitle("confirm", for: .normal)
        submit.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 17)
        submit.setTitleColor(.black, for: .normal)
        submit.addTarget(self, action: #selector(InstrumentSelectionViewController.submitForm), for: .touchUpInside)
        headerView.addSubview(submit)
        return headerView
    }
    
    @objc func submitForm() {
        if let selected = tableView.indexPathsForSelectedRows {
            var lists: [String] = []
            for idx in selected {
                let row = tableView.cellForRow(at: idx)
                if let instrument = row?.textLabel?.text {
                    lists.append(instrument)
                }
            }
            let url = URL(string: "https://j7by90n61a.execute-api.us-east-1.amazonaws.com/instruments")
            if let token = CredentialManager.shared.getToken() {
                postJSON(url: url!, json: [
                    "username": CredentialManager.shared.getUsername(), "instruments": lists
                ], token: token, success: { data, res in
                    // TODO: Error handling
                }, failure: { e in
                    // TODO: Error Handling
                })
            }
        }
        view.removeFromSuperview()
        removeFromParent()
        if let f = didSelected {
            f()
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
}
