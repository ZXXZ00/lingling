//
//  SheetView.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/8/21.
//

import UIKit
import SQLite3

class SheetView : UIView {
    
    public convenience init(frame: CGRect, data: String) {
        self.init(frame: frame)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}
