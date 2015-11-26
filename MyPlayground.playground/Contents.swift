//: Playground - noun: a place where people can play

import UIKit
import XCPlayground


var str = "Hello, playground"
let startPoint = CGPointMake(50, 300)
let endPoint = CGPointMake(300, 300)
let controlPoint = CGPointMake(170, 200)
let layer = CAShapeLayer()
let path = UIBezierPath()
path.moveToPoint(startPoint)
path.addQuadCurveToPoint(endPoint, controlPoint: controlPoint)
layer.path = path.CGPath
layer.fillColor = UIColor.clearColor().CGColor
layer.strokeColor = UIColor.redColor().CGColor
let animation = CABasicAnimation(keyPath: "strokeStart")
animation.fromValue = 0.5
animation.toValue = 0
animation.duration = 2

let animation2 = CABasicAnimation(keyPath: "strokeEnd")
animation2.fromValue = 0.5
animation2.toValue = 1
animation2.duration = 2
//animation.autoreverses = true

layer.addAnimation(animation, forKey: "")
layer.addAnimation(animation2, forKey: "")


let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
container.layer.addSublayer(layer)
XCPlaygroundPage.currentPage.liveView = container
