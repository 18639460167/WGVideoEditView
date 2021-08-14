//
//  UFEffectTimeClipView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/17.
//  Copyright © 2021 black. All rights reserved.
//

import UIKit

public enum UFEffectTimeClipStatus {
    case normal
    case select
    case recording
}

public protocol WGEffectTimeClipViewDelegate:AnyObject {
    // 点击选中
    func didTapClipViewActin(sender: WGEffectTimeClipView)
    // 左/右滑块开始滑动
    func didEffectTimeClipSliderStartAction(left: Bool, sender:WGEffectTimeClipView)
    // 左/右滑块滑动结束
    func didEffectTimeClipSliderEndAction(left: Bool,sender:WGEffectTimeClipView)
    // 左/右滑块位置变化
    func didEffectTimeClipSliderValueChange(left: Bool, gesture:UIPanGestureRecognizer, sender:WGEffectTimeClipView)
}

public protocol WGEffectTimeClipLongPressDelegate: AnyObject {
    // 长按拖动开始
    func didEffectTimeClipLongPressStartAction(longpressGes: UILongPressGestureRecognizer, sender:WGEffectTimeClipView)
    // 长按拖动结束
    func didEffectTimeClipLongPressEndAction(longpressGes: UILongPressGestureRecognizer, sender:WGEffectTimeClipView)
    // 长按位置变化
    func didEffectTimeClipLongPressChange(longpressGes: UILongPressGestureRecognizer, sender:WGEffectTimeClipView)
}

public final class WGEffectTimeClipView: UIView {

    weak var sliderDelegate: WGEffectTimeClipViewDelegate?               // 左右滑块代理
    weak var longPressDelegate: WGEffectTimeClipLongPressDelegate? // 长按事件代理
    
    public var clipViewStatus: UFEffectTimeClipStatus = .normal {
        didSet {
            let select = (clipViewStatus == .select)
            self.leftSliderIcon.isHidden = !select
            self.rightSliderIcon.isHidden = !select
            self.processView.backgroundView.layer.borderWidth = select ? 1.0 : 0
            self.processView.backgroundView.layer.cornerRadius = select ? 0 : WGVideoEffectsConfig.shareModel.clipViewRadius
            self.processView.alpha = select ? WGVideoEffectsConfig.shareModel.clipViewSelectAlpha : WGVideoEffectsConfig.shareModel.clipViewNormalAlpha
            self.processView.effectNameLbl.alpha = 1.0
            switch clipViewStatus {
            case .normal:
                break
            case .select:
                break
            case .recording:
                self.processView.alpha = 1.0
                self.processView.effectNameLbl.alpha = 0.7
                break
            }
        }
    }
    private var sliderStyle: UFSliderCommonStyle {
        return WGVideoEffectsConfig.shareModel.sliderCommonStyle
    }
    // 滑杆宽度
    var sliderWidth: CGFloat {
        return sliderStyle.sliderWidth
    }
    // 特效原始时长
    var effectDuration: CGFloat {
        return self.effectClipInfo.clipOriginDuration
    }
    // 最小间距
    var minDistance: CGFloat {
        let width = WGVideoEffectsConfig.shareModel.minDuration/effectDuration*self.bgMaskView.frame.width
        return width
    }
    // 滑块滚动方向
    var sliderScrollDirection: UFVideoEditScrollDirection = .noMove
    public var effectClipInfo: UFEffectClipInfo = UFEffectClipInfo.init()
    init(frame: CGRect, info: UFEffectClipInfo) {
        super.init(frame: frame)
        self.effectClipInfo = info
        self.addSubview(bgMaskView)
        self.addSubview(processView)
        self.addSubview(leftSliderIcon)
        self.addSubview(rightSliderIcon)
        self.processView.alpha = WGVideoEffectsConfig.shareModel.clipViewNormalAlpha
        self.clipViewStatus = .normal
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    // 左滑块
    lazy var leftSliderIcon: UFEffectClipSliderView = {
        let leftView = UFEffectClipSliderView.init(frame: CGRect.init(x: 0, y: 0, width: sliderWidth, height: self.bounds.height), info: self.effectClipInfo, left: true, sliderWidth: sliderWidth)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(leftSliderPanGestureAction(sender:)))
        leftView.addGestureRecognizer(panGesture)
        leftView.isHidden = true
        return leftView
    }()
    // 右滑块
    lazy var rightSliderIcon: UFEffectClipSliderView = {
        let rightView = UFEffectClipSliderView.init(frame: CGRect.init(x: self.bounds.width-sliderWidth, y: 0, width: sliderWidth, height: self.bounds.height), info: self.effectClipInfo, left: false, sliderWidth: sliderWidth)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(rightSliderPanGestureAction(sender:)))
        rightView.addGestureRecognizer(panGesture)
        rightView.isHidden = true
        return rightView
    }()
    // 指示区域
    lazy var processView: WGEffectClipProgressView = {
        let view = WGEffectClipProgressView(frame: CGRect(x: sliderWidth, y: 0, width: bounds.width -  2 * sliderWidth, height: bounds.height), info: self.effectClipInfo)
        view.isUserInteractionEnabled = true
        
        view.addGestureRecognizer(self.longPressGes)
        view.addGestureRecognizer(self.tap)
        self.tap.require(toFail: self.longPressGes)
        return view
    }()
    /**
     背景蒙版
     选中的时候显示出来整个时间区域
     */
    lazy var bgMaskView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: sliderWidth, y: 0, width: self.bounds.width-2.0*sliderWidth, height: self.bounds.height))
        view.isHidden = true
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = effectClipInfo.radius
        view.layer.masksToBounds = true
        view.backgroundColor = self.effectClipInfo.backgroundColor.withAlphaComponent(0.4)
        return view
    }()
    
    //单击手势
    lazy var tap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapAction))
        return tap
    }()
    //长按手势
    lazy var longPressGes: UILongPressGestureRecognizer = {
        let longPressGes = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressImage(longpressGestureRecognizer:)))
        longPressGes.cancelsTouchesInView = false
        longPressGes.delegate = self
        return longPressGes
    }()
    
    // 子试图超出父试图增加响应事件
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        //从后往前遍历子视图数组
        for subView:UIView in self.subviews {
            let hitPoint = self.convert(point, to: subView)
            if subView.isUserInteractionEnabled == true {
                if subView.bounds.contains(hitPoint), subView.isHidden == false {return true}
            }
        }
        return false
    }
    
    /// 更新slider位置
    /// - 针对裁剪覆盖的情况
    public func updateSliderFrame(left: Bool, minX: CGFloat) {
        if left {
            var sliderFrame = self.leftSliderIcon.frame
            sliderFrame.origin.x = minX
            self.leftSliderIcon.frame = sliderFrame
        } else {
            var sliderFrame = self.rightSliderIcon.frame
            sliderFrame.origin.x = minX
            self.rightSliderIcon.frame = sliderFrame
        }
        self.updateBorderFrame(left: left, handle: false)
        self.layoutIfNeeded()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let progressRect = self.processView.converRect(fatherView: self.bgMaskView)
        self.effectClipInfo.startTimeInEffect = (progressRect.minX/self.bgMaskView.frame.width)*effectDuration
        self.effectClipInfo.clipEffectDuration = (progressRect.width/self.bgMaskView.frame.width)*effectDuration
        if let sView = self.superview {
            let startx = self.processView.converRect(fatherView: sView).minX
            self.effectClipInfo.startTimeInVideo = (startx/sView.frame.width)*WGVideoEffectsConfig.shareModel.videoDuration
        }
    }
    
    // 更新信息
    func updateEffectInfo() {
        self.processView.clipInfo = self.effectClipInfo
        self.processView.updateInfo()
        self.bgMaskView.layer.cornerRadius = effectClipInfo.radius
        self.bgMaskView.backgroundColor = self.effectClipInfo.backgroundColor.withAlphaComponent(0.4)
    }
}

// MARK: - 左右滑杆滑动
extension WGEffectTimeClipView {
    @objc func leftSliderPanGestureAction(sender:UIPanGestureRecognizer){
        let centerOffset: CGPoint = sender.translation(in: self)
        
        switch sender.state {
        case .began:
            self.moveStartOrEnd(start: true, left: true)
        case .changed:
            var leftFrame = self.leftSliderIcon.frame
            leftFrame.origin.x += centerOffset.x
            if centerOffset.x < 0 {
                self.sliderScrollDirection = .left
            } else if centerOffset.x > 0 {
                self.sliderScrollDirection = .right
            } else {
                self.sliderScrollDirection = .noMove
            }
            self.sliderDelegate?.didEffectTimeClipSliderValueChange(left: true, gesture: sender, sender: self)
            break
        case .ended:
            self.moveStartOrEnd(start: false, left: true)
        default:
            break
        }
        sender.setTranslation(CGPoint.zero, in: self.superview)
    }
    @objc func rightSliderPanGestureAction(sender:UIPanGestureRecognizer){
        let centerOffset: CGPoint = sender.translation(in: self)
        switch sender.state {
        case .began:
            self.moveStartOrEnd(start: true, left: false)
        case .changed:
            var rightFrame = self.rightSliderIcon.frame
            rightFrame.origin.x += centerOffset.x
            if centerOffset.x < 0 {
                self.sliderScrollDirection = .left
            } else if centerOffset.x > 0 {
                self.sliderScrollDirection = .right
            } else {
                self.sliderScrollDirection = .noMove
            }
            self.sliderDelegate?.didEffectTimeClipSliderValueChange(left: false, gesture: sender, sender: self)
            break
        case .ended:
            self.moveStartOrEnd(start: false, left: false)
        default:
            break
        }
        sender.setTranslation(CGPoint.zero, in: self.superview)
    }
    
    private func moveStartOrEnd(start: Bool, left: Bool) {
        self.sliderScrollDirection = .noMove
        if start {
            self.bgMaskView.isHidden = false
            self.processView.isUserInteractionEnabled = false
            self.sliderDelegate?.didEffectTimeClipSliderStartAction(left: left, sender: self)
        } else {
            self.bgMaskView.isHidden = true
            self.processView.isUserInteractionEnabled = true
            self.sliderDelegate?.didEffectTimeClipSliderEndAction(left: left, sender: self)
        }
    }
    
    // 更新border的位置
    func updateBorderFrame(left: Bool, handle: Bool = true) {
        let borderFrame = CGRect.init(x: self.leftSliderIcon.frame.maxX, y: 0, width: self.rightSliderIcon.frame.minX-self.leftSliderIcon.frame.maxX, height: self.bounds.height)
        self.processView.frame = borderFrame
    }
    
    /// 录制过程中更新frame
    func updateRecordFrame() {
        var sliderFrame = self.rightSliderIcon.frame
        sliderFrame.origin.x = self.frame.width-sliderWidth
        self.rightSliderIcon.frame = sliderFrame
        self.bgMaskView.frame = CGRect.init(x: sliderWidth, y: 0, width: self.bounds.width-2.0*sliderWidth, height: self.bounds.height)
        self.updateBorderFrame(left: false)
    }
}

// MARK: - 点击/长按
extension WGEffectTimeClipView {
    // 单击
    @objc func tapAction(gesture:UIGestureRecognizer) {
        self.sliderDelegate?.didTapClipViewActin(sender: self)
    }
    // 长按
    @objc func longPressImage(longpressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longpressGestureRecognizer.state {
        case .began:
            self.longPressDelegate?.didEffectTimeClipLongPressStartAction(longpressGes: longpressGestureRecognizer, sender: self)
            break
        case .changed:
            self.longPressDelegate?.didEffectTimeClipLongPressChange(longpressGes: longpressGestureRecognizer, sender: self)
            break
        case .ended:
            self.longPressDelegate?.didEffectTimeClipLongPressEndAction(longpressGes: longpressGestureRecognizer, sender: self)
            break
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension WGEffectTimeClipView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
