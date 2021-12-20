//
//  LeaderBoardTableViewController.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 6/4/21.
//

import UIKit

struct Player {
    var username: String
    var hours: Double
}

class LeaderBoardTableViewController : UITableViewController {
    
    static var cache: [Interval:[Int:Player]] =
        [.day: [Int:Player](), .week: [Int:Player](),.month: [Int:Player](), .year: [Int:Player]()]
    static var cacheTime: [Interval:Double] = [.day: 0, .week: 0, .month: 0, .year: 0]
    static var isLoading: [Interval:Bool] = [.day: false, .week: false, .month: false, .year: false]
    let baseURL = URL(string: "https://j7by90n61a.execute-api.us-east-1.amazonaws.com/leaderboard")!
    
    let interval : Interval
    weak var delegate: LeaderBoardNavigation?
    
    let username = "lingling" // TODO: get current user's username
    var count = 0
    var rank = 0 // the rank of user
    var anchor = 0 // the index path of user
    
    let toUTCDate = DateFormatter()
    let toEpoch = DateFormatter()
    var calendar = Calendar(identifier: .iso8601)
    let countdown = UILabel()
    let loading = UIActivityIndicatorView(style: .large)
    
    var isRefreshing = false
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(interval: Interval, delegate: LeaderBoardNavigation?) {
        self.interval = interval
        self.delegate = delegate
        super.init(style: .plain)
        tableView.register(LeaderBoardCell.self, forCellReuseIdentifier: "TableCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.bounces = true
        tableView.rowHeight = 44
        
        //refreshControl = UIRefreshControl()
        
        toUTCDate.timeZone = TimeZone(identifier: "UTC")
        toEpoch.timeZone = TimeZone(identifier: "UTC")
        toEpoch.dateFormat = "yyyy-MM-dd"
        toUTCDate.dateFormat = "yyyy-MM-dd"
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let context = ["countdown":"\(interval)"]
        print(context)
        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: context, repeats: true)
        timer.tolerance = 0.1
        RunLoop.current.add(timer, forMode: .common)
        
        if let tmp = delegate {
            // 44 is the default row height
            countdown.text = ""
            countdown.textColor = .black
            countdown.textAlignment = .center
            countdown.font = UIFont(name: "Arial", size: 8)
            countdown.frame = CGRect(x: 0, y: -4, width: tmp.size.width, height: 22)
            countdown.backgroundColor = .clear
            view.addSubview(countdown)
            
            loading.color = .gray
            loading.center = CGPoint(x: tmp.size.width/2, y: tmp.size.height/2)
            view.addSubview(loading)
            loading.startAnimating()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //tableView.endUpdates()
    }
    
    func updateTimerHelper(timeDiff: TimeInterval) {
        var diff = timeDiff
        let hour = Int(diff / 3600)
        diff -= Double(hour) * 3600.0
        let minute = Int(diff / 60)
        diff -= Double(minute) * 60.0
        let seconds = Int(diff)
        if minute < 10 {
            if seconds < 10 {
                countdown.text = "\(hour):0\(minute):0\(seconds)"
            } else {
                countdown.text = "\(hour):0\(minute):\(seconds)"
            }
        } else if seconds < 10 {
            countdown.text = "\(hour):\(minute):0\(seconds)"
        } else {
            countdown.text = "\(hour):\(minute):\(seconds)"
        }
            
    }
    
    @objc func updateTimer() {
        let cur = Date()
        if interval == .week {
            let curMonday = calendar.dateComponents([.calendar, .yearForWeekOfYear ,.weekOfYear], from: cur).date
            if var bound = curMonday {
                bound += 7*24*3600 // increment by a week
                updateTimerHelper(timeDiff: cur.distance(to: bound))
            }
        } else if interval == .month {
            let nxtMonth = calendar.date(byAdding: .month, value: 1, to: cur)!
            if let bound = calendar.dateComponents([.calendar, .year, .month], from: nxtMonth).date {
                updateTimerHelper(timeDiff: cur.distance(to: bound))
            }
        } else {
            let tmp = toUTCDate.string(from: cur)
            if var bound = toEpoch.date(from: tmp) {
                bound += 24*3600 // increment by 24 hour
                updateTimerHelper(timeDiff: cur.distance(to: bound))
            }
        }
    }
    
    func loadData() {
        let now = Date().timeIntervalSince1970
        if now > LeaderBoardTableViewController.cacheTime[interval]! + 900 {
            // cache is valid for 15 minutes
            loadDataHelper(lo: 0, hi: 100) { num in
                DispatchQueue.main.async {
                    if !self.isRefreshing {
                        self.insert(num)
                        self.isRefreshing = true
                    } else {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // didLoad has a parameter which is the number of loaded data entries
    func loadDataHelper(atTop: Bool=false, lo: Int?=nil, hi: Int?=nil, didLoad: ((_: Int) -> Void)?=nil) {
        loading.startAnimating()
        LeaderBoardTableViewController.isLoading[interval] = true
        var url = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        if let low = lo, let high = hi {
            url?.query = "type=\(interval)&rank_lo=\(low)&rank_hi=\(high)"
        } else {
            url?.query = "username=\(username)&type=\(interval)"
        }
        guard let u = url?.url  else { return }
        getJSON(url: u, success: { json in
            guard let ranks = json as? [[Any]] else {
                DataManager.shared.insertErrorMessage(isNetwork: true, message: "LeaderBoard JSON could not be parsed into [[Any]]")
                return
            }
            LeaderBoardTableViewController.cacheTime[self.interval] = Date().timeIntervalSince1970
            var tmp = 0
            for rank in ranks {
                if let r = rank[0] as? Int,
                   let user = rank[1] as? String,
                   let hours = rank[2] as? Double {
                    LeaderBoardTableViewController.cache[self.interval]![r] = Player(username: user, hours: hours)
                    
                    //if user == self.username {
                    //    self.rank = r
                    //    self.anchor = tmp
                    //}
                    tmp += 1
                }
            }
            if let closure = didLoad {
                closure(tmp)
            }
            DispatchQueue.main.async {
            //    //self.addData(tmp, atTop: atTop)
            //    if self.count - tmp > 0 {
            //        self.insert(self.count - tmp)
            //    }
                self.loading.stopAnimating()
            //    LeaderBoardTableViewController.isLoading[self.interval] = false
            //    if let closure = didLoad {
            //        closure()
            //    }
            }
            
        }, failure: { err in
            DataManager.shared.insertErrorMessage(isNetwork: false, message: err.localizedDescription)
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return section == 0 ? count : 1
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! LeaderBoardCell
        if let player = LeaderBoardTableViewController.cache[interval]![rank + indexPath.row - anchor] {
            cell.rank.text = String(rank + indexPath.row - anchor)
            cell.username.text = player.username
            cell.hours.text = String(player.hours)
        }
        if let tmp = delegate {
            cell.frame = CGRect(x: 0, y: 0, width: tmp.size.width, height: 44)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? LeaderBoardCell {
            delegate?.openUserInfoView(username: cell.username.text!)
        }
    }
    
    // legacy function, might be useful if decide to show all ranks
    //override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    //    guard let visible = tableView.indexPathsForVisibleRows else { return }
    //    for idx in visible {
    //        if idx.row == count - 1 {
    //            let start = rank + count - anchor
    //            loadDataHelper(atTop: false, lo: start, hi: start + 128)
    //            break
    //        }
    //        if idx.row == 0 {
    //            let start = rank - anchor - 1
    //            if start > 0 {
    //                loadDataHelper(atTop: true, lo: max(0, start-128), hi: start)
    //            }
    //            break
    //        }
    //    }
    //}
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // + 44 to offset inital contentOffset
        // + frame.height/2 becase we are modifying center
        //leaderView.center.y = scrollView.contentOffset.y + 44 + leaderView.frame.height/2
        if let tmp = delegate {
            loading.center.y = scrollView.contentOffset.y + tmp.size.height/2
        }
        
    }
    // legacy function, might be useful if decide to show all ranks
    private func insert(_ batchSize: Int) {
        var idxs = [IndexPath]()
        for _ in count..<count+batchSize {
            idxs.append(IndexPath(row: count, section: 0))
            count += 1
        }
        tableView.insertRows(at: idxs, with: .automatic)
    }
    // legacy function
    private func addData(_ batchSize: Int, atTop: Bool) {
        var idxs = [IndexPath]()
        if atTop {
            for _ in 0..<batchSize {
                count += 1
                anchor += 1
                tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
            tableView.scrollToRow(at: IndexPath(row: batchSize, section: 0), at: .middle, animated: true)
        } else {
            for _ in count..<count+batchSize {
                idxs.append(IndexPath(row: count, section: 0))
                count += 1
            }
            tableView.insertRows(at: idxs, with: .automatic)
        }
    }
    
}
