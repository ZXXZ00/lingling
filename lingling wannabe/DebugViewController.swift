//
//  DebugViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 12/31/21.
//

import UIKit

class DebugViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let output = UITextView(frame: view.frame)
        output.textColor = .black
        output.backgroundColor = .white
        let username = CredentialManager.shared.getUsername()
        for record in DataManager.shared.getRecord(username: username) {
            output.text += "\(record.username), \(record.time), \(record.duration), \(record.attributes) | \(record.synced)\n"
        }
        output.text += DataManager.shared.getErrors()
        view.addSubview(output)
    }
}
