//
//  LeaderBoardCell.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 6/5/21.
//

import UIKit

class LeaderBoardCell : UITableViewCell {
    let rank = UILabel()
    let username = UILabel()
    let hours = UILabel()
    var isSeparatorAdded = false
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding Not Supported!")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        rank.textAlignment = .left
        rank.font = UIFont(name: "AmericanTypewriter-Condensed", size: 16)
        rank.textColor = .black
        addSubview(rank)
        rank.translatesAutoresizingMaskIntoConstraints = false
        rank.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
        rank.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        rank.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.15).isActive = true
        rank.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        username.textAlignment = .center
        username.font = UIFont(name: "AmericanTypewriter-Condensed", size: 16)
        username.textColor = .black
        addSubview(username)
        username.translatesAutoresizingMaskIntoConstraints = false
        username.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        username.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        username.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6).isActive = true
        username.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        hours.textAlignment = .right
        hours.font = UIFont(name: "AmericanTypewriter-Condensed", size: 16)
        hours.textColor = .black
        addSubview(hours)
        hours.translatesAutoresizingMaskIntoConstraints = false
        hours.rightAnchor.constraint(equalTo: rightAnchor, constant: -4).isActive = true
        hours.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        hours.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.18).isActive = true
        hours.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isSeparatorAdded {
            layer.addLine(start: CGPoint(x: 0, y: frame.height), end: CGPoint(x: frame.width, y: frame.height), width: 1)
            isSeparatorAdded = true
        }
    }
}

protocol LeaderBoardCellDelegate {
    func openUserInfoView(username: String)
}
