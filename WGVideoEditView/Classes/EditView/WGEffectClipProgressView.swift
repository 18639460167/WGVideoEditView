//
//  UFEffectClipProgressView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/19.
//  Copyright © 2021 black. All rights reserved.
//

import UIKit

class WGEffectClipProgressView: UIView {

    var clipInfo: UFEffectClipInfo = UFEffectClipInfo.init()
    init(frame: CGRect, info: UFEffectClipInfo) {
        super.init(frame: frame)
        self.layer.masksToBounds = true
        self.clipInfo = info
        let disatnce = self.clipInfo.betweenDistance/2.0
        self.backgroundView.frame = CGRect.init(x: disatnce, y: 0, width: self.frame.width-info.betweenDistance, height: self.bounds.height)
        effectNameLbl.frame = CGRect.init(x: self.clipInfo.nameLeftMargin+disatnce, y: 0, width: self.frame.width-info.nameLeftMargin-2.0-2.0*disatnce, height: self.frame.height)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let disatnce = self.clipInfo.betweenDistance/2.0
        self.backgroundView.frame = CGRect.init(x: disatnce, y: 0, width: self.frame.width-disatnce*2.0, height: self.bounds.height)
        effectNameLbl.frame = CGRect.init(x: self.clipInfo.nameLeftMargin+disatnce, y: 0, width: self.frame.width-self.clipInfo.nameLeftMargin-2.0-2.0*disatnce, height: self.frame.height)
    }
    
    lazy var backgroundView: UIView = {
        let view = UIView.init(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = self.clipInfo.backgroundColor
        view.layer.borderWidth = 0
        view.layer.cornerRadius = self.clipInfo.radius
        view.layer.masksToBounds = true
        view.layer.borderColor = self.clipInfo.borderColor.cgColor
        self.addSubview(view)
        return view
    }()
    
    lazy var effectNameLbl: UILabel = {
        let label = UILabel.init(frame: .zero)
        label.textAlignment = .left
        label.text = self.clipInfo.effectName
        label.font = self.clipInfo.font
        label.textColor = self.clipInfo.fontColor
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byClipping
        self.addSubview(label)
        return label
    }()
    
    func updateInfo() {
        self.effectNameLbl.text = self.clipInfo.effectName
        self.effectNameLbl.font = self.clipInfo.font
        self.effectNameLbl.textColor = self.clipInfo.fontColor
        self.backgroundView.backgroundColor = self.clipInfo.backgroundColor
        self.backgroundView.layer.borderColor = self.clipInfo.borderColor.cgColor
    }

}

class UFEffectClipSliderView: UIView {
    private var left: Bool = true
    private var clipInfo: UFEffectClipInfo = UFEffectClipInfo.init()
    init(frame: CGRect, info: UFEffectClipInfo, left: Bool, sliderWidth: CGFloat) {
        super.init(frame: frame)
        self.clipInfo = info
        self.left = left
        self.layer.masksToBounds = false
        if left {
            self.sliderImageView.frame = CGRect.init(x: self.clipInfo.betweenDistance/2.0, y: 0, width: sliderWidth, height: self.bounds.height)
        } else {
            self.sliderImageView.frame = CGRect.init(x: -self.clipInfo.betweenDistance/2.0, y: 0, width: sliderWidth, height: self.bounds.height)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var frame = self.sliderImageView.frame
        if left {
            frame.origin.x = self.clipInfo.betweenDistance/2.0
        } else {
            frame.origin.x = -self.clipInfo.betweenDistance/2.0
        }
        self.sliderImageView.frame = frame
        
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    lazy var sliderImageView: UIImageView = {
        let imageView = UIImageView.init(frame: .zero)
        if left {
            imageView.image = WGVideoEffectsConfig.shareModel.sliderCommonStyle.leftSliderImage ?? UIImage.uf_image(imageName: "video_edit_left_slider",
                                                                                                                 bundle: (anyClass: WGEffectClipProgressView.self,
                                                                                                                         bundleName: "UFViewComponent"))
        } else {
            imageView.image = WGVideoEffectsConfig.shareModel.sliderCommonStyle.rightSliderImage ?? UIImage.uf_image(imageName: "video_edit_right_slider",
                                                                                                                  bundle: (anyClass: WGEffectClipProgressView.self,
                                                                                                                          bundleName: "UFViewComponent"))
        }
        self.addSubview(imageView)
        return imageView
    }()
}

class UFLongPressMoveView: UIView {
    var isHighlight: Bool = false {
        didSet {
            self.normalView?.isHidden = isHighlight
            self.hightView?.isHidden = !isHighlight
        }
    }
    var normalView: UIView? = nil {
        didSet {
            if let norView = normalView {
                norView.frame = self.bounds
                self.addSubview(norView)
            }
        }
    }
    var hightView: UIView? = nil {
        didSet {
            if let higView = hightView {
                higView.frame = self.bounds
                self.addSubview(higView)
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
