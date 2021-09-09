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
    weak var delegate: LeaderBoardNavigation?
    let lingling = LeaderBoardCell()
    let first = LeaderBoardCell()
    let second = LeaderBoardCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        page.dataSource = self
        page.delegate = self
        addChild(page)
        view.addSubview(page.view)
        
        populate()
        page.setViewControllers([tables[0]], direction: .forward, animated: true)
        print(tables.first!.view.frame)
        
    }
    
    func populate() {
        let intervals: [Interval] = [.day, .week, .month, .year]
        for i in 0..<4 {
            let table = LeaderBoardTableViewController(interval: intervals[i], delegate: delegate)
            table.view.backgroundColor = .white
            tables.append(table)
        }
    }
    
    // After swipe change table
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
