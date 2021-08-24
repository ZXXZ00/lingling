//
//  LeaderBoardNavigation.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/31/21.
//

import UIKit

enum interval : String {
    case day
    case week
    case month
    case year
}

class LeaderBoardNavigation : UINavigationController {
    
    let size : CGSize
    let floatViewDelegate : FloatView
    let items = ["day", "settimana", "month", "year"]
    let control : UISegmentedControl
    let lb: LeaderBoardViewController
    
    init(size: CGSize) {
        self.size = size
        floatViewDelegate = FloatView(size)
        lb = LeaderBoardViewController()
        control = UISegmentedControl(items: items)
        lb.control = control
        super.init(rootViewController: lb)
        //let root = UserInfoViewController()
        //super.init(rootViewController: root)
        // change of size and additionalSafeAreaInsets is based on the assumption
        // that loadView will be called after the this initilization finishs
        //root.size = CGSize(width: size.width, height: size.height - navigationBar.frame.height)
        //root.additionalSafeAreaInsets.top = navigationBar.frame.height
        
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate

        delegate = self
    }
    
    override func viewDidLoad() {
        navigationBar.tintColor = .black
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
    
    @objc func showDetail(sender: LeaderBoardCell) {
        print(sender.username)
    }
}

extension LeaderBoardNavigation : UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewControllers.count == 1 { control.alpha = 1 } else { control.alpha = 0}
    }
}
