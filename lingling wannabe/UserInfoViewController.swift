//
//  UserInfoViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/23/21.
//

import UIKit

class UserInfoViewController : UIViewController {
    
    var calendarData: CalendarData? = nil
    var calendarView: UICollectionView!
    let formatter = DateFormatter()
    let monthLabel = UILabel()
    static var scale: CGFloat = 1
    let username: String
    let baseURL = URL(string: "https://wi6n41chmb.execute-api.us-east-1.amazonaws.com/v1")!
    
    let loading = UIActivityIndicatorView(style: .large)
    
    var size : CGSize
    var floatViewDelegate: FloatView?
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(_ size: CGSize, username: String, isPresentedByMainView: Bool = true) {
        self.size = size
        floatViewDelegate = FloatView(size)
        self.username = username
        super.init(nibName: nil, bundle: nil)
        if isPresentedByMainView {
            modalPresentationStyle = .custom
            transitioningDelegate = floatViewDelegate
        }
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
        //print(itemWidth)
        //print(itemHeight)
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        calendarView = UICollectionView(frame: CGRect(x: 0, y: headerHeight+additionalSafeAreaInsets.top, width: size.width, height: size.height - headerHeight), collectionViewLayout: layout)
        calendarView.showsVerticalScrollIndicator = false
        calendarView.collectionViewLayout = layout
        calendarView.backgroundColor = .gray
        calendarView.register(CalendarCell.self, forCellWithReuseIdentifier: "CalendarCell")
        calendarView.dataSource = nil
        (calendarView as UIScrollView).delegate = self
        view.addSubview(calendarView)
        
        monthLabel.frame = CGRect(x: size.width/1.9, y: 0, width: size.width/2.2, height: headerHeight)
        monthLabel.center.y = headerHeight/2 + additionalSafeAreaInsets.top
        monthLabel.font = UIFont(name: "AmericanTypewriter", size: 16*UserInfoViewController.scale)
        monthLabel.textColor = .black
        monthLabel.textAlignment = .right
        view.addSubview(monthLabel)
        
        let startPoint = CGPoint(x: 0, y: headerHeight+additionalSafeAreaInsets.top)
        let endPoint = CGPoint(x: size.width, y: headerHeight+additionalSafeAreaInsets.top)
        view.layer.addLine(start: startPoint, end: endPoint, width: 1)
        
        loading.center = CGPoint(x: size.width/2, y: size.height/2)
        loading.startAnimating()
        view.addSubview(loading)
        
        self.view = view
        formatter.dateFormat = "YYYY-MM"
    }
    
    func loadData() {
        if CalendarData.cache.keys.contains(username) {
            calendarData = CalendarData(username: username)
            calendarView.dataSource = calendarData
            dataDidLoad()
        } else if username == "guest" {
            dataDidLoad()
        } else {
            var url = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
            url?.query = "username=\(username)"
            guard let u = url?.url else { return }
            getJSON(url: u, success: { json in
                if let assests = json as? [[String:Any]] {
                    let user = self.username
                    let formatter = DateFormatter()
                    formatter.dateFormat = "YYYY-MM-dd"
                    CalendarData.cache[user] = [:]
                    for asset in assests {
                        if let start = asset["start_time"] as? Double,
                            let name = asset["asset"] as? String {
                            let key = formatter.string(from: Date(timeIntervalSince1970: start))
                            if CalendarData.cache[user]!.keys.contains(key) {
                                CalendarData.cache[user]![key]!.append(name)
                            } else {
                                CalendarData.cache[user]![key] = [name]
                            }
                        }
                    }
                    self.dataDidLoad()
                } else {
                    print("user doesn't exist")
                }
            }, failure: {err in print("opps!")})
        }
    }
    
    func dataDidLoad() {
        DispatchQueue.main.async {
            self.calendarData = CalendarData(username: self.username)
            self.calendarView.dataSource = self.calendarData
            self.loading.stopAnimating()
            self.loading.removeFromSuperview()
            let today = Date()
            self.monthLabel.text = self.formatter.string(from: today)
            if let section = self.calendarData?.dateToSections(today) {
                self.calendarView.scrollToItem(at: IndexPath(item: 0, section: section), at: .top, animated: false)
            }
        }
        
    }
}

extension UserInfoViewController : UIScrollViewDelegate {
    // update the label
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visible = calendarView.indexPathsForVisibleItems
        let sum = visible.reduce(0) { $0 + $1.section }
        if visible.count != 0 {
            let section = Int((Double(sum) / Double(visible.count)).rounded())
            if let (date, _) = calendarData?.getDateAndWeekday(monthOffset: section) {
                monthLabel.text = formatter.string(from: date)
            }
        }
    }
}

extension CALayer {
    func addLine(start: CGPoint, end: CGPoint, width: CGFloat) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.lineWidth = width
        line.strokeColor = UIColor.gray.cgColor
        self.addSublayer(line)
    }
}
