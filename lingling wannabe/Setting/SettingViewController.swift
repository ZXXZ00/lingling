//
//  SettingViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/2/22.
//

import UIKit

class SettingViewController: UIViewController {
    
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .none
        
        let tableView = UITableView()
        tableView.backgroundColor = .none
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: -40).isActive = true
        
        let signOut = UIButton()
        signOut.titleLabel?.font = UIFont(name: "AmericanTypewriter", size: 19)
        signOut.setTitleColor(.white, for: .normal)
        signOut.setTitle("Log out", for: .normal)
        signOut.backgroundColor = .gray
        signOut.layer.cornerRadius = 10
        view.addSubview(signOut)
        signOut.translatesAutoresizingMaskIntoConstraints = false
        signOut.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        signOut.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        signOut.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        signOut.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        self.view = view
    }
}
