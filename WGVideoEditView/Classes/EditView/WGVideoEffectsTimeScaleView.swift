//
//  UFVideoEditTimeScaleView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/16.
//  Copyright © 2021 black. All rights reserved.
//

import UIKit

class WGVideoEffectsTimeScaleView: UIView {

    // 视频时长
    var videoDuration: CGFloat = 0 {
        didSet {
            self.setUpUI()
        }
    }
    private var timeScale: CGFloat {
        return WGVideoEffectsConfig.shareModel.timeScale*2.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setUpUI() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        let duration: CGFloat = videoDuration
        // 索引
        var scales = Int(floor(duration/timeScale))
        let style = WGVideoEffectsConfig.shareModel.timeScaleStyle
        scales += 1
        for i in 0..<scales {
            let width = style.timeScaleWidth*2.0
            let height = self.frame.height
            let startX = width*CGFloat(i)
            let scaleView = UFVideoEditTimeScaleItemView.init(frame: CGRect.init(x: startX, y: 0, width: width, height: height), style: style)
            scaleView.timeLbl.text = String.init(format: "00:%02d", Int(CGFloat(i)*timeScale))
            if i==scales-1 {
                let durationScale = timeScale/2.0
                let maxDuration = CGFloat(i)*timeScale+durationScale
                if maxDuration > duration {
                    // // 最后一段小于单个刻度 小于0.5
                    scaleView.centerTagView.isHidden = true
                }
            }
            self.addSubview(scaleView)
        }
    }

}

class UFVideoEditTimeScaleItemView: UIView {
    init(frame: CGRect, style: UFTimeScaleToolStyle) {
        super.init(frame: frame)
        self.layer.masksToBounds = false
        self.addSubview(timeLbl)
        self.addSubview(centerTagView)
        self.timeLbl.textColor = style.fontColor
        self.timeLbl.font = style.font
        self.centerTagView.bounds = CGRect.init(x: 0, y: 0, width: style.tagSize.width, height: style.tagSize.height)
        self.centerTagView.layer.cornerRadius = style.tagSize.width/2.0
        self.centerTagView.layer.masksToBounds = true
        self.centerTagView.backgroundColor = style.tagColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var timeLbl: UILabel = {
        let label = UILabel.init(frame: self.bounds)
        label.textColor = UIColor.white.withAlphaComponent(0.3)
        label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        label.textAlignment = .center
        label.text = "00:00"
        return label
    }()
    lazy var centerTagView: UIView = {
        let view = UIView.init(frame: CGRect.zero)
        view.center = CGPoint.init(x: self.frame.width, y: self.frame.height/2.0)
        return view
    }()
}
