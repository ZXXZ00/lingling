//
//  Helper.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 5/25/21.
//

import UIKit
import PocketSVG

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

func svg(at: URL, scale: CGFloat) -> CALayer {
    let ret = svg(at: at)
    ret.transform = CATransform3DMakeScale(scale, scale, 1)
    return ret
}
