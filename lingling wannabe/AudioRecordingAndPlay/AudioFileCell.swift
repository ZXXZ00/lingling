//
//  AudioFileCell.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/3/22.
//

import UIKit

class AudioFileCell: UITableViewCell {
    
    let fileName = UILabel()
    let labelName = UILabel()
    var isSeparatorAdded = false
    
    let filenameLabelLength: CGFloat = 115
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding Not Supported!")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let font = UIFont(name: "AmericanTypewriter", size: 16)
        
        fileName.font = font
        fileName.textColor = .black
        fileName.textAlignment = .left
        addSubview(fileName)
        fileName.translatesAutoresizingMaskIntoConstraints = false
        fileName.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
        fileName.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        fileName.widthAnchor.constraint(equalToConstant: filenameLabelLength).isActive = true
        fileName.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        labelName.font = font
        labelName.textColor = .black
        labelName.textAlignment = .right
        addSubview(labelName)
        labelName.translatesAutoresizingMaskIntoConstraints = false
        labelName.rightAnchor.constraint(equalTo: rightAnchor, constant: -4).isActive = true
        labelName.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelName.widthAnchor.constraint(equalTo: widthAnchor, constant: -filenameLabelLength-10).isActive = true
        labelName.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isSeparatorAdded {
            layer.addLine(start: CGPoint(x: 0, y: frame.height), end: CGPoint(x: frame.width, y: frame.height), width: 1)
            isSeparatorAdded = true
        }
    }
}
