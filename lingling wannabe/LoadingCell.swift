//
//  LoadingCell.swift
//  
//
//  Created by Adam Zhao on 7/3/21.
//

import UIKit

class LoadingCell: UITableViewCell {
    let loading = UIActivityIndicatorView(style: .medium)
    
    override func layoutSubviews() {
        loading.center = CGPoint(x: frame.width/2, y: frame.height/2)
        addSubview(loading)
    }
}
