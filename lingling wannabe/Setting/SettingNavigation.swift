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
    
    init(size: CGSize, settingDelegate: SettingDelegate?) {
        self.size = size
        floatViewDelegate = FloatView(size)
        
        if let settingDelegate = settingDelegate {
            rootView.delegate = settingDelegate
        }
        super.init(rootViewController: rootView)
        
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
        
        navigationBar.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported!")
    }
}
