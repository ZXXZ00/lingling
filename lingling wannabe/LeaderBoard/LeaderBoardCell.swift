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
        rank.font = UIFont(name: "Arial", size: frame.height/3)
        rank.textColor = .black
        addSubview(rank)
        username.textAlignment = .center
        username.font = UIFont(name: "AmericanTypewriter-Condensed", size: frame.height/3)
        username.textColor = .black
        addSubview(username)
        hours.textAlignment = .right
        hours.font = UIFont(name: "Arial", size: frame.height/3)
        hours.textColor = .black
        addSubview(hours)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isSeparatorAdded {
            layer.addLine(start: CGPoint(x: 0, y: frame.height), end: CGPoint(x: frame.width, y: frame.height), width: 1)
            isSeparatorAdded = true
        }
        rank.frame = CGRect(x: frame.height*0.04, y: frame.height*0.05, width: frame.width*0.24, height: frame.height*0.9)
        username.frame = CGRect(x: 0, y: frame.height*0.05, width: frame.width*0.6, height: frame.height*0.9)
        username.center = CGPoint(x: frame.width*0.5, y: frame.height/2)
        hours.frame = CGRect(x: frame.width - frame.width*0.16, y: frame.height*0.05, width: frame.width*0.15, height: frame.height*0.9)
    }
}

protocol LeaderBoardCellDelegate {
    func openUserInfoView(username: String)
}
