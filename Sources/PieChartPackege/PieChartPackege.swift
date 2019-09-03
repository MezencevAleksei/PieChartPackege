//
//  PieChartView.swift
//  Otus_HW_3
//
//  Created by alex on 24/06/2019.
//  Copyright © 2019 Mezencev Aleksei. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public struct Slice {
    public init(color: UIColor, value: CGFloat, title: String){
        self.color = color
        self.value = value
        self.title = title
    }
    public let color: UIColor
    public let value: CGFloat
    public let title: String
}

@IBDesignable
public class PieChart: UIView {
    private var viewCenter:CGPoint?
    private var radius: CGFloat?
    private var shapeLayer: CAShapeLayer!
    private var timer:Timer?
    private let animationTime:CFTimeInterval = 1.5
    private var animationLayers = [CAShapeLayer]()
    private var isAnimationRuning = false
    public var slices: [Slice] = [] {
        didSet {
            if slices.count > 0 {
                animate()
            }
        }
    }
    
    public override var bounds: CGRect{
        didSet{
            setup()
            if !isAnimationRuning {
                setNeedsDisplay()
            }else {
                if slices.count > 0 {
                    animate()
                }
            }
        }
    }
    
    public var drawTitel: Bool = true
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override func prepareForInterfaceBuilder() {
        setNeedsDisplay()
    }
    
    private func setup() {
        viewCenter = CGPoint(x: bounds.maxX/2, y: bounds.maxY/2)
        radius = min(frame.width, frame.height) / 2 * 0.8
        isOpaque = false
    }
    
    private lazy var textAttributes: [NSAttributedString.Key: Any] = [
        .font               : UIFont.systemFont(ofSize: 14),
        .foregroundColor    : UIColor.black
    ]
    
    override public func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if isAnimationRuning {
            context.clear(self.bounds)
            return
        }
        
        let totalSegmentsValue = slices.reduce(0, { $0 + $1.value })
        if slices.count == 0 || totalSegmentsValue == 0 {
            context.clear(self.bounds)
            return
        }
        
        var startAngle = -CGFloat.pi / 2
        
        for slice in slices {
            let endAngle = drawSegmentFrom(startAngle: startAngle, slice: slice, context: context,  totalSegmentsValue: totalSegmentsValue)
            if drawTitel {
                drawLabelOfSlice(slice: slice, context: context, startAngle: startAngle, endAngle: endAngle)
            }
            startAngle = endAngle
        }
        
    }
    
    private func drawSegmentFrom(startAngle: CGFloat, slice: Slice, context: CGContext, totalSegmentsValue: CGFloat)-> CGFloat{
        
        context.setFillColor(slice.color.cgColor)
        
        // Draw a slice
        let endAngle = startAngle + 2 * .pi * (slice.value / totalSegmentsValue)
        context.move(to: viewCenter!)
        context.addArc(center: viewCenter!, radius: radius!, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.fillPath()
        
        // Draw a delimiter
        context.move(to: viewCenter!)
        context.addLine(to: CGPoint(center: viewCenter!, radius: radius!, degrees: endAngle))
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(1)
        context.strokePath()
        
        return endAngle
    }
    
    private func drawLabelOfSlice(slice: Slice, context: CGContext, startAngle: CGFloat, endAngle: CGFloat){
        // Draw a label
        let halfAngle = startAngle + (endAngle - startAngle) * 0.5
        let segmentCenter = viewCenter!.projected(by: radius!*0.7, angle: halfAngle)
        let textToRender = slice.title as NSString
        let renderRect =  CGRect(centeredOn: segmentCenter, size: textToRender.size(withAttributes: textAttributes))
        textToRender.draw(in: renderRect, withAttributes: textAttributes)
    }
    
    //MARK: Animate
    private func animate() {
        if isAnimationRuning {
            timer?.invalidate()
            stopAnimation()
        }
        
        let totalSegmentsValue = slices.reduce(0, { $0 + $1.value })
        
        let centr = viewCenter!
        let startAngle = -CGFloat.pi / 2
        var endAngle: CGFloat = 0.0
        var endAngleForRotate: CGFloat = 0.0
        
        for slice in slices {
            
            if slice.value == 0 {
                continue
            }
            
            //create segment layer
            let _shapeLayer = CAShapeLayer()
            _shapeLayer.bounds = bounds
            _shapeLayer.strokeColor = slice.color.cgColor
            _shapeLayer.fillColor = UIColor.clear.cgColor
            _shapeLayer.lineWidth = radius!
            _shapeLayer.lineCap = .butt
            _shapeLayer.position = centr
            
            //darw segment
            endAngle = 2 * .pi * (slice.value / totalSegmentsValue)
            let path = UIBezierPath()
            path.addArc(withCenter: centr, radius: radius!/2, startAngle: startAngle, endAngle: endAngle - CGFloat.pi / 2, clockwise: true)
            _shapeLayer.path = path.cgPath
            
            //stroke end animation
            let drawingAnimation = CABasicAnimation(keyPath: "strokeEnd")
            drawingAnimation.fromValue    = 0
            drawingAnimation.toValue      = 1
            drawingAnimation.duration     = animationTime
            drawingAnimation.autoreverses = false
            drawingAnimation.repeatCount  = .init(1)
            _shapeLayer.add(drawingAnimation, forKey: "drawingAnimation")
            
            //rotate animation
            if endAngleForRotate != 0 {
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
                rotationAnimation.fromValue = 0
                rotationAnimation.toValue = endAngleForRotate
                rotationAnimation.duration = animationTime
                rotationAnimation.repeatCount = .init(1)
                _shapeLayer.add(rotationAnimation, forKey: "rotationAnimation")
            }
            
            animationLayers.append(_shapeLayer)
            endAngleForRotate = endAngle
        }
        
        for _layer in animationLayers {
            layer.addSublayer(_layer)
        }
        if animationLayers.count > 0 {
            if #available(iOS 10.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: animationTime, repeats: false, block:  {_ in self.stopAnimation()})
            } else {
                // Fallback on earlier versions
            }
            isAnimationRuning = true
            setNeedsDisplay()
        }
    }
    
    private func stopAnimation() {
        for _layer in animationLayers {
            _layer.removeAnimation(forKey: "drawingAnimation")
            _layer.removeAnimation(forKey: "rotationAnimation")
            _layer.removeFromSuperlayer()
        }
        animationLayers.removeAll()
        isAnimationRuning = false
        setNeedsDisplay()
    }
    
}






//MARK: Extension
extension CGFloat {
    public var radiansToDegrees: CGFloat {
        return self * 180 / .pi
    }
}

extension CGPoint {
    public init(center: CGPoint, radius: CGFloat, degrees: CGFloat) {
        self.init(x: cos(degrees) * radius + center.x,
                  y: sin(degrees) * radius + center.y)
    }
    
    func projected(by value: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: x + value * cos(angle), y: y + value * sin(angle)
        )
    }
}

extension CGRect {
    public init(centeredOn center: CGPoint, size: CGSize) {
        self.init(
            origin: CGPoint(
                x: center.x - size.width * 0.5, y: center.y - size.height * 0.5
            ),
            size: size
        )
    }
    public var center: CGPoint {
        return CGPoint(x: width / 2 + origin.x,
                       y: height / 2 + origin.y)
    }
}
#endif
