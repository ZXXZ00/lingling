//
//  LeaderBoardNavigation.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/31/21.
//

import UIKit

enum Interval : String {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
}

class LeaderBoardNavigation : UINavigationController, LeaderBoardCellDelegate {
    
    let size : CGSize
    let floatViewDelegate : FloatView
    let items = ["day", "week", "month"]
    let control : UISegmentedControl
    let lb: LeaderBoardViewController
    
    init(size: CGSize) {
        self.size = size
        floatViewDelegate = FloatView(size)
        lb = LeaderBoardViewController()
        control = UISegmentedControl(items: items)
        lb.control = control
        super.init(rootViewController: lb)
        lb.delegate = self

        
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate

        delegate = self
    }
    
    override func viewDidLoad() {
        navigationBar.backgroundColor = .gray
        navigationBar.tintColor = .white
        let barHeight = navigationBar.frame.height
        
        control.frame = CGRect(x: 0, y: 0, width: barHeight * 0.8*2 * CGFloat(items.count), height: barHeight * 0.6)
        control.center = CGPoint(x: size.width/2, y: barHeight/2)
        control.selectedSegmentIndex = 0
        control.addTarget(lb, action: #selector(LeaderBoardViewController.updateTable), for: .valueChanged)
        
        navigationBar.addSubview(control)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported!")
    }
    
    func openUserInfoView(username: String) {
        let tmp = CGSize(width: size.width, height: size.height - navigationBar.frame.height)
        let userInfo = UserInfoViewController(tmp, username: username, isPresentedByMainView: false)
        userInfo.additionalSafeAreaInsets.top += navigationBar.frame.height
        userInfo.loadData()
        pushViewController(userInfo, animated: true)
    }
}

extension LeaderBoardNavigation : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewControllers.count == 1 { control.alpha = 1 } else { control.alpha = 0}
    }
}
