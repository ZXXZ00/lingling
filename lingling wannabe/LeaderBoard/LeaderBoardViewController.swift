//
//  LeaderBoardViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 6/3/21.
//

import UIKit

class LeaderBoardViewController : UIViewController {
    let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    var tables = [UIViewController]()
    weak var control : UISegmentedControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        page.dataSource = self
        page.delegate = self
        addChild(page)
        view.addSubview(page.view)
        
        let lingling = LeaderBoardCell()
        lingling.username.text = "lingling"
        lingling.rank.text = "0"
        lingling.hours.text = "40"
        lingling.frame = CGRect(x: 0, y: 44, width: 310, height: lingling.frame.height)
        lingling.backgroundColor = .white
        view.addSubview(lingling)
        
        populate()
        page.setViewControllers([tables[0]], direction: .forward, animated: true)
        
    }
    
    func populate() {
        for i in 0..<4 {
            let table = LeaderBoardTableViewController(interval: .day)
            table.view.backgroundColor = UIColor(hue: 64*CGFloat(i)/256, saturation: 1, brightness: 0.5, alpha: 1)
            
            tables.append(table)
        }
    }
    
    
    @objc func updateTable() {
        guard let c = control, let vc = page.viewControllers?.first else { return }
        let idx = c.selectedSegmentIndex
        guard let currIdx = tables.firstIndex(of: vc) else { return }
        if idx > currIdx {
            page.setViewControllers([tables[idx]], direction: .forward, animated: true)
        }
        if idx < currIdx {
            page.setViewControllers([tables[idx]], direction: .reverse, animated: true)
        }
    }
}

extension LeaderBoardViewController : UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let idx = tables.firstIndex(of: viewController) {
            if idx > 0 { return tables[idx - 1] }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let idx = tables.firstIndex(of: viewController) {
            if idx < tables.count-1 { return tables[idx + 1] }
        }
        return nil
    }
}

extension LeaderBoardViewController : UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let vc = page.viewControllers?.first {
            if let idx = tables.firstIndex(of: vc) {
                print(idx)
                control?.selectedSegmentIndex = idx
            }
        }
    }
}
