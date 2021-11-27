//
//  FourierSeries.swift
//  lingling wannabe
//
//  Created by Adam Zhao on 7/13/21.
//

import Accelerate
import UIKit

public class FourierSeries: NSObject, CAAnimationDelegate {
    var count: Int
    var real: [Float]
    var imag: [Float]
    var realOutP: [Float]
    var imagOutP: [Float]
    var realOutN: [Float]
    var imagOutN: [Float]
    // the origin's x and y are the same as UIKit coordinate where the top left is 0,0
    // and x increases towars the right and y increases towards the bottom
    // HOWEVER, the coordinate the fourier transform uses is cartesian with origin at top left
    // so the display area with (+x, +y) is in the fourth quadrant (+x, -y)
    private var origin: CGPoint
    // the position is UIKit coordinate
    var position: CGPoint
    
    var duration: Double
    
    public let layer = CALayer()
    
    let pathLayer = CAShapeLayer()
    
    var cutoff: CGFloat = 1
    
    var repeatCount: Float
    
    // the real and imag must have the same size
    // the size must be multiple of two
    public init(real: [Float], imag: [Float], position: CGPoint = .zero, duration: Double = 10, origin: CGPoint = .zero, repeatCount: Float = .infinity) {
        assert(real.count > 0 && real.count == imag.count)
        assert((real.count & (real.count-1)) == 0)
        count = real.count
        self.origin = origin
        self.position = position
        self.duration = duration
        self.repeatCount = repeatCount
        // if checkLoop() double the count for backward traverse
        self.real = real
        self.imag = imag
        for i in 0..<count {
            self.real[i] += Float(position.x - origin.x)
            self.imag[i] = Float(origin.y - position.y) - self.imag[i]
        }
        realOutP = Array(repeating: 0, count: count)
        imagOutP = Array(repeating: 0, count: count)
        realOutN = Array(repeating: 0, count: count)
        imagOutN = Array(repeating: 0, count: count)
        super.init()
        fourierTransform()
        addVector()
    }
    
    public convenience init(points: [CGPoint], position: CGPoint = .zero, origin: CGPoint = .zero, repeatCount: Float = .infinity) {
        var tmpR: [Float] = []
        var tmpI: [Float] = []
        for point in points {
            tmpR.append(Float(point.x))
            tmpI.append(Float(point.y))
        }
        self.init(real: tmpR, imag: tmpI, position: position, origin: origin, repeatCount: repeatCount)
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        return sqrt(Double((a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y)))
    }
    
    func l2norm(_ x: Float, _ y: Float) -> CGFloat {
        return CGFloat(sqrtf(x*x+y*y))
    }
    
    func checkLoop() -> Bool {
        //TODO: fussy check if the given path forms a loop
        return true
    }
    
    func fourierTransform() {
        let dft = vDSP.DFT(count: count, direction: .forward, transformType: .complexComplex, ofType: Float.self)
        let idft = vDSP.DFT(count: count, direction: .inverse, transformType: .complexComplex, ofType: Float.self)
        dft?.transform(inputReal: real, inputImaginary: imag, outputReal: &realOutP, outputImaginary: &imagOutP)
        idft?.transform(inputReal: real, inputImaginary: imag, outputReal: &realOutN, outputImaginary: &imagOutN)
    }
    
    // length is the length of the vector
    func createVector(x: Float, y: Float, length: CGFloat, angleOffset: Float, frequency: Int) -> (CAShapeLayer, CGFloat, Float) {
        let ret = CAShapeLayer()
        let norm = l2norm(x, y)
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: 0))
        line.addLine(to: CGPoint(x: norm+0, y: 0))
        line.addArc(withCenter: CGPoint(x: 0, y: 0), radius: norm, startAngle: 0, endAngle: 0.001*CGFloat.pi, clockwise: false)
        ret.path = line.cgPath
        //ret.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: norm, height: 1)).cgPath
        ret.bounds = CGRect(x: 0, y: 0, width: norm, height: 1)
        ret.anchorPoint = CGPoint(x: 0, y: 0.5)
        ret.position = CGPoint(x: length, y: 0.5)
        ret.strokeColor = UIColor.black .cgColor
        ret.lineWidth = 0.3
        ret.fillColor = .none
        let initialAngle = x < 0 ? atanf(y/x)-Float.pi : atanf(y/x)
        let angle = initialAngle-angleOffset
        ret.transform = CATransform3DMakeRotation(CGFloat(angle), 0, 0, -1.0)
        let rotate = CABasicAnimation(keyPath: "transform.rotation")
        rotate.fromValue = -angle
        rotate.toValue = -angle-Float.pi*2*Float(frequency)
        rotate.duration = duration
        rotate.repeatCount = repeatCount
        rotate.delegate = self
        ret.add(rotate, forKey: "rotate\(frequency)")
        ret.shouldRasterize = false
        ret.isOpaque = true
        return (ret, norm, initialAngle)
    }
    // shouldRasterize = false and isOpaque = true for better performance
    func addVector() {
        layer.shouldRasterize = false
        var parent = layer
        parent.isOpaque = true
        parent.shouldRasterize = false
        let size = Float(count)
        realOutP[0] /= size
        imagOutP[0] /= size
        var length: CGFloat = 0
        var angle: Float = 0
        var res = createVector(x: realOutP[0], y: imagOutP[0], length: length, angleOffset: angle, frequency: 0)
        var child = res.0
        length = res.1
        angle += res.2
        child.position = CGPoint(x: origin.x, y: origin.y)
        child.fillColor = UIColor.clear.cgColor
        child.strokeColor = UIColor.clear.cgColor
        parent.addSublayer(child)
        parent = child
        var freq = 0
        var freqOffset = 0
        // TODO: adaptive change number of sublayers, currently it is set to 50
        for i in 1..<50 {
            realOutP[i] /= size
            imagOutP[i] /= size
            if l2norm(realOutP[i], imagOutP[i]) > cutoff {
                freq = i-freqOffset
                freqOffset += freq
                res = createVector(x: realOutP[i], y: imagOutP[i], length: length, angleOffset: angle, frequency: freq)
                child = res.0
                length = res.1
                angle = res.2
                parent.addSublayer(child)
                parent = child
            }
            
            realOutN[i] /= size
            imagOutN[i] /= size
            if l2norm(realOutN[i], imagOutN[i]) > cutoff {
                freq = -i-freqOffset
                freqOffset += freq
                res = createVector(x: realOutN[i], y: imagOutN[i], length: length, angleOffset: angle, frequency: freq)
                child = res.0
                length = res.1
                angle = res.2
                parent.addSublayer(child)
                parent = child
            }
        }
    }
    
    func addTrace() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: CGFloat(real[0]), y: CGFloat(-imag[0])))
        for i in 1..<real.count {
            path.addLine(to: CGPoint(x: CGFloat(real[i]), y: CGFloat(-imag[i])))
        }
        path.addLine(to: CGPoint(x: CGFloat(real[0]), y: CGFloat(-imag[0])))
        pathLayer.path = path.cgPath
        pathLayer.strokeColor = UIColor.black.cgColor
        pathLayer.fillColor = .none
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.repeatCount = repeatCount
        pathLayer.add(animation, forKey: nil)
        layer.addSublayer(pathLayer)
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        layer.removeFromSuperlayer()
    }
}
