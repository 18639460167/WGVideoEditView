//
//  UFVideoEditTimeThumbsView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/16.
//  Copyright © 2021 black. All rights reserved.
//

import UIKit

class WGVideoEffectsThumbsView: UIView {

    var tapActionHandle:(() -> Void)?
    var timeThumbs: [UIImage] = [] {
        didSet {
            self.setUpUI()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setUpUI() {
        let style = WGVideoEffectsConfig.shareModel.thumbsToolStyle
        self.isUserInteractionEnabled = style.tapHighlight
        self.alpha = style.alpha
        self.layer.cornerRadius = style.radius
        self.layer.masksToBounds = true
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(tapAction)))
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for (i, thumb) in self.timeThumbs.enumerated() {
            let width = WGVideoEffectsConfig.shareModel.timeScaleStyle.timeScaleWidth
            let height = self.frame.height
            let startX = width*CGFloat(i)
            let thumbImgView = UIImageView.init(frame: CGRect.init(x: startX, y: 0, width: width, height: height))
            thumbImgView.image = thumb
            thumbImgView.contentMode = .scaleAspectFill
            thumbImgView.layer.masksToBounds = true
            self.addSubview(thumbImgView)
        }
    }
    
    @objc func tapAction() {
        self.tapActionHandle?()
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0.5
        } completion: { (_) in
            UIView.animate(withDuration: 0.3) {
                self.alpha = 0.8
            }
        }
    }
}
