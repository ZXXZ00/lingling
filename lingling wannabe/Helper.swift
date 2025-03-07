//
//  Helper.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/25/21.
//

import UIKit
import PocketSVG
import Photos
import Toast_Swift

func getDocumentDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func svg(at: URL) -> CALayer {
    let paths = SVGBezierPath.pathsFromSVG(at: at)
    let ret = CALayer()
    for (index, path) in paths.enumerated() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.shouldRasterize = false
        ret.addSublayer(shapeLayer)
    }
    ret.shouldRasterize = false
    return ret
}

func svg(filename: String) -> CALayer? {
    if let url = Bundle.main.url(forResource: filename, withExtension: "svg") {
        return svg(at: url)
    } else {
        return nil
    }
}

func svg(at: URL, scale: CGFloat) -> CALayer {
    let ret = svg(at: at)
    ret.transform = CATransform3DMakeScale(scale, scale, 1)
    return ret
}

func svg(filename: String, scale: CGFloat) -> CALayer? {
    let ret = svg(filename: filename)
    ret?.transform = CATransform3DMakeScale(scale, scale, 1)
    return ret
}

func pdf(filename: String, scale: CGFloat) -> UIImageView {
    // 300 is the size of the canvas
    let frame = CGRect(x: 0, y: 0, width: 300 * scale, height: 300 * scale)
    let ret = UIImageView(frame: frame)
    ret.contentMode = .scaleAspectFit
    ret.image = UIImage(named: filename)
    return ret
}

func postJSON(url: URL, json: [String: Any], token: String?=nil,
              success: @escaping (_: Data, _: HTTPURLResponse) -> Void, failure: @escaping (_: Error) -> Void) {
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let tk = token {
        request.setValue(tk, forHTTPHeaderField: "Authorization")
    }
    request.httpMethod = "POST"
    request.allowsCellularAccess = true
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
    } catch {
        print("failed to parse json")
    }
    let task = URLSession.shared.dataTask(with: request) {
        data, response, err in
        if let err = err {
            failure(err)
            return
        }
        if let res = response as? HTTPURLResponse, let d = data {
            success(d, res)
        } else {
            print("failed to cast response and data")
            // TODO: failed to cast
            DataManager.shared.insertErrorMessage(isNetwork: true, message: "failed to case response from post")
        }
        print("\nresponse")
        if let res = response as? HTTPURLResponse {
            print(res.statusCode)
            print(res.allHeaderFields)
            print(res)
        }
        print("data")
        if let d = data {
            print(String(data: d, encoding: .utf8))
        } else {
            print(data)
        }
        print()
        print("error")
        print(err)
        print()
    }
    task.resume()
}

// TODO: Implement getJSON with response 
func getJSON(url: URL, success: @escaping (_: Any) -> Void, failure: @escaping (_: Error) -> Void) {
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "GET"
    request.allowsCellularAccess = true
    let task = URLSession.shared.dataTask(with: request) {
        data, response, err in
        if let err = err {
            failure(err)
            return
        }
        print("\ndata")
        do {
            if let d = data {
                let json = try JSONSerialization.jsonObject(with: d)
                //print(json)
                success(json)
                //print(d)
            } else {
                print("no data")
                // TODO: no data
            }
        } catch {
            print(error.localizedDescription)
            failure(error)
        }
        print("\nresponse")
        if let res = response as? HTTPURLResponse {
            print(res.statusCode)
            print(res.allHeaderFields)
            print(res)
        }
        print("\nerror")
        print(err)
    }
    task.resume()
}

func addCache(username: String, date: Date, asset: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    addCache(username: username, key: formatter.string(from: date), asset: asset)
}

func addCache(username: String, key: String, asset: String) {
    if CalendarData.cache.keys.contains(username) {
        if CalendarData.cache[username]!.keys.contains(key) {
            CalendarData.cache[username]![key]!.append(asset)
        } else {
            CalendarData.cache[username]![key] = [asset]
        }
    } else {
        CalendarData.cache[username] = [key:[asset]]
    }
}

func parsePoints(json: Data) -> [[String:[Float]]] {
    do {
        return try JSONDecoder().decode([[String:[Float]]].self, from: json)
    } catch {
        return []
    }
}

func loadPoints(filename: String) -> [[String:[Float]]] {
    do {
        if let path = Bundle.main.path(forResource: filename, ofType: "json"),
           let json = try String(contentsOfFile: path).data(using: .utf8) {
            return parsePoints(json: json)
        }
    } catch {
        return []
    }
    return []
}

// create fourier drawing animation, the path will be drawn out
func drawAnimate(name: String, position: CGPoint = .zero, duration: Double = 10) -> CALayer {
    let paths = loadPoints(filename: name)
    let ret = CALayer()
    for path in paths {
        let f = FourierSeries(real: path["x"]!, imag: path["y"]!, position: position, duration: duration, repeatCount: 1)
        f.addTrace(drawn: true, tracked: false)
        ret.addSublayer(f.layer)
        
    }
    return ret
}

// create fourier drawing animation with highligh on path
func highlightAnimate(name: String, position: CGPoint = .zero, duration: Double = 10) -> CALayer {
    let paths = loadPoints(filename: name)
    let ret = CALayer()
    for path in paths {
        let f = FourierSeries(real: path["x"]!, imag: path["y"]!, position: position, duration: duration, repeatCount: .infinity)
        f.addTrace(drawn: false, tracked: false)
        ret.addSublayer(f.layer)
    }
    return ret
}

func getAvailableSpace(at: URL) -> Int64? {
    do {
        let values = try at.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values.volumeAvailableCapacityForImportantUsage
    } catch {
        print("failed to get available space at \(at), error message: \(error)")
        DataManager.shared.insertErrorMessage(isNetwork: false, message: "failed to get available space at \(at), error message: \(error)")
    }
    return nil
}

func saveToPhoto(source: URL, view: UIView) {
    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: source) }) {
        success, error in
        DispatchQueue.main.async {
            if success {
                view.makeToast("Saved to Photos")
            } else {
                view.makeToast("Failed to save: \(error?.localizedDescription ?? "")")
                DataManager.shared.insertErrorMessage(isNetwork: false, message: "Failed to save: \(error?.localizedDescription ?? "")")
            }
        }
    }
}
