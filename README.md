# RecordReplaying
高德地图跑步轨迹展示的代码在高德官方的3D地图示例中RunningLineViewController类中已经有很好的示例代码，就不再赘述了 [下载AMap_iOS_Demo](http://a.amap.com/lbs/static/zip/AMap_iOS_Demo.zip)。今天主要讲一下实现轨迹回放。当然这个方法对于所有地图的轨迹回放都是可用的。

实现回放功能的准备工作：
- [新建一个处理回放的class](###新建一个处理回放的class)
- [坐标数组、坐标对应的颜色数组](###坐标数组、坐标对应的颜色数组)
- [渐变线](###渐变线)
- [动画](###动画)

### 1.  新建一个处理回放的class
新建一个class，我这里命名未Replaying
### 2.  坐标数组、坐标对应的颜色数组
额，坐标数组自己整理吧。颜色我这里的处理方式采用的是高德demo里面的算法，只是修改了一下偏冷色和偏暖色的值。
var coordinateArray: [CLLocationCoordinate2D] = []
var colorArray: [UIColor] = []
coordinateArray 转换坐标

      fileprivate func pointsForCoordinates() ->[CGPoint] {
        var points: [CGPoint] = []
        for coordinate in self.coordinateArray {
            guard let map_view = self.mapView else { return [] }
            let point = map_view.convert(coordinate, toPointTo: map_view)
            points.append(point)
        }
        return points
    }
### 3. 渐变线
自定义CALayer，重写`draw(in ctx: CGContext)`方法。这里要用到Quartz2D的知识点，我在简书里找到了关于[Quartz2D讲解](http://www.jianshu.com/p/eb6bd4b0f9a5)可以学习一下。这里用到了路径、颜色与颜色空间、渐变相关技术。
(***Swift中苹果对CGMutablePath进行了重构，CGMutablePath被定义为了类, 内存这一块就不用我们手动管理了，👍👍👍***)
这个类关键代码：

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
            } else {
                let prevPoint: CGPoint = self._points[i - 1]
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

在gradientLayer调用func add(points: [CGPoint], colors: [UIColor]) 函数后调用自身的setNeedsDisplay()方法重绘。我们还需要在Replaying中给layer添加一个蒙板mask(这个属性本身就是个CALayer类型，有和其他图层一样的绘制和布局属性。mask图层定义了父图层的部分可见区域)

    fileprivate func initShapeLayer() {
        self.shapeLayer.lineWidth = 5
        self.shapeLayer.strokeColor = UIColor.clear.cgColor
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.lineJoin = kCALineCapRound
    }

    fileprivate func pathForPoints(points: [CGPoint]) -> CGMutablePath {
        let path = CGMutablePath()
        path.addLines(between: points)
        return path
    }
    self.shapeLayer.path = path
    self.gradientLayer.mask = self.shapeLayer
ok，渐变线出来了
### 4. 动画
动画

    let shapeLayerAnimation = self.constructShapeLayerAnimation()
    self.shapeLayer.add(shapeLayerAnimation, forKey: "shape")

    fileprivate func constructShapeLayerAnimation() -> CAAnimation {
        let annimation = CABasicAnimation(keyPath: "strokeEnd")
        annimation.duration = self.duration
        annimation.fromValue = 0.0
        annimation.toValue = 1.0
        return annimation
    }

