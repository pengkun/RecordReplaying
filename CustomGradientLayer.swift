//
//  CustomGradientLayer.swift
//
//  Created by pk on 2017/7/20.
//  Copyright © 2017年 pengkk. All rights reserved.
//

import UIKit

class CustomGradientLayer: CALayer {

    var _points: [CGPoint] = []
    var _colors: [UIColor] = []

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func add(points: [CGPoint], colors: [UIColor]) {
        self._points = points
        self._colors = colors
    }

    override func draw(in ctx: CGContext) {
        var pcolor: UIColor?
        var ccolor: UIColor?
        for i in 0..<self._points.count {
            let point: CGPoint = self._points[i]
            let path: CGMutablePath = CGMutablePath()
            ccolor = self._colors[i]
            if i == 0 {
                path.move(to: CGPoint(x: point.x, y: point.y), transform: .identity)
            }
            else {
                let prevPoint: CGPoint = self._points[i - 1]
                path.move(to: CGPoint(x: prevPoint.x, y: prevPoint.y), transform: .identity)
                path.addLine(to: CGPoint(x: point.x, y: point.y), transform: .identity)
                var pc_r: CGFloat = 0
                var pc_g: CGFloat = 0
                var pc_b: CGFloat = 0
                var pc_a: CGFloat = 0

                var cc_r: CGFloat = 0
                var cc_g: CGFloat = 0
                var cc_b: CGFloat = 0
                var cc_a: CGFloat = 0

                pcolor?.getRed(&pc_r, green: &pc_g, blue: &pc_b, alpha: &pc_a)
                ccolor?.getRed(&cc_r, green: &cc_g, blue: &cc_b, alpha: &cc_a)

                let gradientColors: [CGFloat] = [pc_r, pc_g, pc_b, pc_a, cc_r, cc_g, cc_b, cc_a]
                let gradientLocation: [CGFloat] = [0, 1]
                ctx.saveGState()
                let lineWidth: CGFloat = ctx.convertToUserSpace(CGSize(width: 5, height: 5)).width
                let pathToFill: CGPath = path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10, transform: .identity)
                ctx.addPath(pathToFill)
                ctx.clip()
                let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
                if let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColors, locations: gradientLocation, count: 2) {
                    let gradientStart: CGPoint = prevPoint
                    let gradientEnd: CGPoint = point
                    ctx.drawLinearGradient(gradient, start: gradientStart, end: gradientEnd, options: .drawsAfterEndLocation)
                }
                ctx.restoreGState()
            }
            pcolor = ccolor
        }
    }
}
