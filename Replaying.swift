//
//  Replaying.swift
//
//  Created by pk on 2017/3/28.
//  Copyright © 2017年 pengkk All rights reserved.
//

import Foundation

protocol TrackingDelegate: class {
    func willBeginTracking(_ tracking: Tracking)
    func didEndTracking(_ tracking: Tracking)
}
class Tracking: NSObject {
    var mapView: MAMapView?
    var duration: TimeInterval = kReplayTrackDuration
    var edgeInsets: UIEdgeInsets = UIEdgeInsetsMake(30, 30, 30, 30)
    weak var delegate: TrackingDelegate?

    // line
    fileprivate var coordinateArray: [CLLocationCoordinate2D] = []
    fileprivate var colorArray: [UIColor] = []
    fileprivate var shapeLayer: CAShapeLayer = CAShapeLayer()
    fileprivate var gradientLayer: CustomGradientLayer = CustomGradientLayer()

    fileprivate var imageLayer: CALayer = CALayer()

    deinit {
        debugPrint("\(type(of:self)) deinit")
    }

    init?(coordinates: [CLLocationCoordinate2D], colors: [UIColor]) {
        if coordinates.count <= 1 {
            return nil
        }
        super.init()
        self.coordinateArray = coordinates
        self.colorArray = colors
        self.initShapeLayer()
        self.initImageLayer()
    }

    fileprivate func initShapeLayer() {
        self.shapeLayer.lineWidth = 5
        let curSpeedColor = UIColor.ext_rgba(Int(9), Int(201), Int(228))
        self.shapeLayer.strokeColor = curSpeedColor.cgColor
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.lineJoin = kCALineCapRound
    }

    fileprivate func initImageLayer() {
        let image = UIImage(named: "record_run_icon")
        self.imageLayer.contents = image?.cgImage
        self.imageLayer.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
    }

    func execute() {

        let points = self.pointsForCoordinates()
        let path = self.pathForPoints(points: points)

        self.shapeLayer.path = path

        self.gradientLayer.frame = (self.mapView?.bounds)!
        self.gradientLayer.add(points: points, colors: self.colorArray)
        self.gradientLayer.setNeedsDisplay()
        self.mapView?.layer.insertSublayer(self.gradientLayer, at: 1)

        self.mapView?.layer.insertSublayer(self.imageLayer, above: self.gradientLayer)

        self.gradientLayer.mask = self.shapeLayer

        let shapeLayerAnimation = self.constructShapeLayerAnimation()
        shapeLayerAnimation.delegate = self
        self.shapeLayer.add(shapeLayerAnimation, forKey: "shape")

        let keyAnimation = self.constructKeyAnimation(path)
        self.imageLayer.add(keyAnimation, forKey: "keyframe")
    }

    fileprivate func pointsForCoordinates() ->[CGPoint] {
        var points: [CGPoint] = []
        for coordinate in self.coordinateArray {
            guard let map_view = self.mapView else { return [] }
            let point = map_view.convert(coordinate, toPointTo: map_view)
            points.append(point)
        }
        return points
    }

    fileprivate func pathForPoints(points: [CGPoint]) -> CGMutablePath {
        let path = CGMutablePath()
        path.addLines(between: points)
        return path
    }

    fileprivate func constructShapeLayerAnimation() -> CAAnimation {
        let annimation = CABasicAnimation(keyPath: "strokeEnd")
        annimation.duration = self.duration
        annimation.fromValue = 0.0
        annimation.toValue = 1.0
        annimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return annimation
    }

    fileprivate func constructKeyAnimation(_ path: CGPath) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.duration = self.duration
        animation.path = path
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.calculationMode = kCAAnimationPaced;
        return animation
    }

    fileprivate func makeMapViewEnable(enabled: Bool) {
        self.mapView?.isScrollEnabled = enabled
//        self.mapView?.isZoomEnabled = enabled
//        self.mapView?.isRotateCameraEnabled = enabled
    }
}

extension Tracking: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
        self.makeMapViewEnable(enabled: false)
        self.delegate?.willBeginTracking(self)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            self.delegate?.didEndTracking(self)
            self.imageLayer.removeFromSuperlayer()
            Async.after(1.0, closure: {
                self.gradientLayer.removeFromSuperlayer()
                self.makeMapViewEnable(enabled: true)
            })
        }
    }
}

