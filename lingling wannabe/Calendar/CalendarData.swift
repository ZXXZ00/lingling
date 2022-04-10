//
//  CalendarData.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/27/21.
//

import UIKit

class CalendarData : NSObject, UICollectionViewDataSource {
    
    static var cacheTime = [String:Int]()
    static var cache = [String:[String:[String]]]()
    static var cacheReady = false
    let formatter = DateFormatter()
    let startYear = 2021
    let startMonth = 2 // startMonth is 0 based. 0 is Jan
    let startDay = 1 // start is always the first of the month
    let start : Date
    let calendar = Calendar.current
    let user: String
    
    init(username: String) {
        formatter.dateFormat = "yyyy-MM-dd"
        start = formatter.date(from: "\(startYear)-\(startMonth+1)-\(startDay)")!
        user = username
        super.init()
    }

    // return the first day of the month given month offset from start
    // and the weekday of the first day (0: Monday, 1: Tuesday ...)
    func getDateAndWeekday(monthOffset: Int) -> (Date, Int)? {
        // start is always the first day of the month
        guard let firstDayOfMonth = calendar.date(byAdding: .month, value: monthOffset, to: start) else {
            print("failed to do date arthimatic")
            return nil
        }
        // since sunday is 1, monday is 2 and this calendar monday is first day of week
        // we need to translate that to 0: firstdayofweek, 1: firstdayofweek+1 and so on
        let weekday1based = calendar.component(.weekday, from: firstDayOfMonth)
        let weekday0based = (weekday1based + 7 - calendar.firstWeekday) % 7
        // +7 to avoid negative number such as 1 - 6
        return (firstDayOfMonth, weekday0based)
    }
    
    func numOfItems(section: Int) -> Int {
        if let (date, weekday) = getDateAndWeekday(monthOffset: section) {
            var ret = date.numberOfDays() + weekday
            ret += 7 - (ret % 7)
            return ret
        }
        return 0
    }
    
    func indexPathToDate(_ idx: IndexPath) -> Date? {
        // return nil if the cell at idx should be blank
        let month = idx.section
        if let (date, offset) = getDateAndWeekday(monthOffset: month) {
            if idx.item < offset || idx.item > date.numberOfDays() + offset {
                return nil
            }
            return formatter.date(from:"\(startYear+(startMonth+month)/12)-\((startMonth+month)%12+1)-\(idx.item-offset+1)")
        }
        return nil
    }
    
    func dateToSections(_ date: Date) -> Int? { // convert date to section
        let months = calendar.dateComponents([.month], from: start, to: date)
        return months.month
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1024 // 2^10 months for no reason 85 years should be ok for now
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numOfItems(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        if let date = indexPathToDate(indexPath) {
            cell.dayLabel.text = String(calendar.component(.day, from: date))
            if let assets = CalendarData.cache[user]?[formatter.string(from: date)] {
                cell.addAsset(filenames: assets)
            }
        } else {
            cell.dayLabel.text = ""
        }
        return cell
    }
}

extension Date {
    func numberOfDays() -> Int { // return the number of days in a month
        if let range = Calendar.current.range(of: .day, in: .month, for: self) {
            return range.count
        }
        print("failed to get number of days in a month for \(description)")
        return 0
    }
}
