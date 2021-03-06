//
//  IndicatorView.swift
//  Cup
//
//  Created by kingslay on 15/11/9.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit

public class IndicatorView: UIView {
    let ovalLayer = CAShapeLayer()
    var ovalPathSmall: UIBezierPath {
        return UIBezierPath(ovalInRect: CGRect(x: self.ks_centerX, y: self.ks_centerY, width: 0.0, height: 0.0))
    }
    
    var ovalPathLarge: UIBezierPath {
        return UIBezierPath(ovalInRect: CGRect(x: self.ks_centerX-100, y: self.ks_centerY-100, width: 200, height: 200))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = Colors.black
        let label1 = UILabel()
        label1.text = "搜索智能水杯"
        label1.font = UIFont.systemFontOfSize(23)
        label1.sizeToFit()
        label1.textColor = UIColor.whiteColor()
        self.addSubview(label1)
        label1.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(0)
            make.centerY.equalTo(-160)
        }
        let label2 = UILabel()
        label2.text = "请将手机靠近智能水杯"
        label2.font = UIFont.systemFontOfSize(12)
        label2.sizeToFit()
        label2.textColor = UIColor.whiteColor()
        self.addSubview(label2)
        label2.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(0)
            make.top.equalTo(label1.snp_bottom).offset(20)
        }
        let circularView = UIView()
        circularView.backgroundColor = Colors.red
        self.addSubview(circularView)
        circularView.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            make.width.equalTo(2)
            make.height.equalTo(2)
        }
        circularView.layer.cornerRadius = 1
        ovalLayer.fillColor = Colors.pink.CGColor
        ovalLayer.path = ovalPathSmall.CGPath
        ovalLayer.opacity = 0.1
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startAnimating()
    {
        self.hidden = false
        self.layer.addSublayer(ovalLayer)
        let expandAnimation: CABasicAnimation = CABasicAnimation(keyPath: "path")
        expandAnimation.fromValue = ovalPathSmall.CGPath
        expandAnimation.toValue = ovalPathLarge.CGPath
        expandAnimation.duration = 2
        expandAnimation.fillMode = kCAFillModeForwards
        expandAnimation.removedOnCompletion = true
        expandAnimation.repeatCount = 1000
        ovalLayer.addAnimation(expandAnimation, forKey: nil)

    }
    public func stopAnimating()
    {
        self.hidden = true
        ovalLayer.removeAllAnimations()
    }

}
