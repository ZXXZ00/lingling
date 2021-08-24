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
    
    override func layoutSubviews() {
        layer.addLine(start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0), width: 1)
        rank.frame = CGRect(x: frame.height*0.04, y: 0, width: frame.width*0.24, height: frame.height)
        rank.textAlignment = .left
        rank.font = UIFont(name: "Arial", size: frame.height/3)
        rank.textColor = .black
        addSubview(rank)
        username.frame = CGRect(x: 0, y: 0, width: frame.width*0.6, height: frame.height)
        username.center = CGPoint(x: frame.width*0.52, y: frame.height/2)
        username.textAlignment = .center
        username.font = UIFont(name: "AmericanTypewriter-Condensed", size: frame.height/3)
        username.textColor = .black
        addSubview(username)
        hours.frame = CGRect(x: frame.width - frame.width*0.16, y: 0, width: frame.width*0.15, height: frame.height)
        hours.textAlignment = .right
        hours.font = UIFont(name: "Arial", size: frame.height/3)
        hours.textColor = .black
        addSubview(hours)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //alpha = 0.8
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touched")
    }
}
