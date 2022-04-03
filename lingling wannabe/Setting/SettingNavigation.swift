//
//  SettingNavigation.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 4/2/22.
//

import UIKit

class SettingNavigation: UINavigationController {
    
    let size : CGSize
    let floatViewDelegate : FloatView
    let rootView = SettingViewController()
    
    init(size: CGSize) {
        self.size = size
        floatViewDelegate = FloatView(size)
        super.init(rootViewController: rootView)
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported!")
    }
}
