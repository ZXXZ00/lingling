//
//  UserInfoViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/23/21.
//

import UIKit

class UserInfoViewController : UIViewController {
    
    let calendarData = CalendarData()
    var calendarView: UICollectionView!
    let formatter = DateFormatter()
    let monthLabel = UILabel()
    static var scale: CGFloat = 1
    
    let size : CGSize
    let floatViewDelegate: FloatView
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    public init(_ size: CGSize) {
        self.size = size
        floatViewDelegate = FloatView(size)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = floatViewDelegate
    }
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        UserInfoViewController.scale = size.width / 300
        let headerHeight = 40 * UserInfoViewController.scale
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        let itemWidth = (size.width-6) / 7
        let itemHeight = (itemWidth * 1.618).rounded() // 1.618 golden ratio
        print(itemWidth)
        print(itemHeight)
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        calendarView = UICollectionView(frame: CGRect(x: 0, y: headerHeight, width: size.width, height: size.height - headerHeight), collectionViewLayout: layout)
        calendarView.showsVerticalScrollIndicator = false
        calendarView.collectionViewLayout = layout
        calendarView.backgroundColor = .gray
        calendarView.register(CalendarCell.self, forCellWithReuseIdentifier: "CalendarCell")
        calendarView.dataSource = calendarData
        (calendarView as UIScrollView).delegate = self
        view.addSubview(calendarView)
        
        monthLabel.frame = CGRect(x: size.width/1.9, y: 0, width: size.width/2.2, height: headerHeight)
        monthLabel.center.y = headerHeight/2
        monthLabel.font = UIFont(name: "AmericanTypewriter", size: 16*UserInfoViewController.scale)
        monthLabel.textColor = .black
        monthLabel.textAlignment = .right
        view.addSubview(monthLabel)
        
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: headerHeight))
        linePath.addLine(to: CGPoint(x: size.width, y: headerHeight))
        line.path = linePath.cgPath
        line.lineWidth = 1
        line.strokeColor = UIColor.gray.cgColor
        view.layer.addSublayer(line)
        
        self.view = view
        formatter.dateFormat = "YYYY-MM"
    }
    
    override func viewDidLoad() {
        let today = Date()
        monthLabel.text = formatter.string(from: today)
        if let section = calendarData.dateToSections(today) {
            calendarView.scrollToItem(at: IndexPath(item: 0, section: section), at: .top, animated: false)
        }
    }
}

extension UserInfoViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visible = calendarView.indexPathsForVisibleItems
        let sum = visible.reduce(0) { $0 + $1.section }
        if visible.count != 0 {
            let section = Int((Double(sum) / Double(visible.count)).rounded())
            if let (date, _) = calendarData.getDateAndWeekday(monthOffset: section) {
                monthLabel.text = formatter.string(from: date)
            }
        }
    }
}
