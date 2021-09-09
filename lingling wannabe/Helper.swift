//
//  Helper.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/25/21.
//

import UIKit
import PocketSVG

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

func postJSON(url: URL, json: [String: Any],
              success: @escaping (_: Data, _: HTTPURLResponse) -> Void, failure: @escaping (_: Error) -> Void) {
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        }
        print("data")
        if let d = data {
            print(String(data: d, encoding: .utf8))
        } else {
            print(data)
        }
        print()
        print("response")
        if let res = response {
            if let httpres = res as? HTTPURLResponse {
                print(httpres.statusCode)
                print(httpres.allHeaderFields)
                print(httpres)
            }
            print(res)
        } else {
            print(response)
        }
        print()
        print("error")
        print(err)
        print()
    }
    task.resume()
}

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
                let json = try JSONSerialization.jsonObject(with: data!)
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

