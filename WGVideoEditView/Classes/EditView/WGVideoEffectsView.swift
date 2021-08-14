//
//  UFVideoEditView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/19.
//  Copyright © 2021 black. All rights reserved.
//  视频编辑view

import UIKit

public protocol WGVideoEffectsDelegate: AnyObject {
    /// 开始编辑
    /// tag：1：scrollview 2：长按拖动 3：slider
    func didVideoEffectStartAction(sender: WGVideoEffectsView, tag: NSInteger)
    func didVideoEffectEndAction(sender: WGVideoEffectsView, tag: NSInteger)
    func didVideoEffectProgressChange(duration: CGFloat, sender: WGVideoEffectsView)
    
    /// 编辑片段完成(增、删、改)
    /// effectInfos：所有片段信息(已按照在视频的时间排序)
    func videoEffectEditFinish(effectInfos: [UFEffectClipInfo], type: UFVideoEffectUpdateType, sender: WGVideoEffectsView)
    /// 选中某个片段
    /// clipView:- 片段信息
    func selectVideoEffectClip(clipView: WGEffectTimeClipView, sender: WGVideoEffectsView)
    /// 取消选中片段
    /// clipView: - 片段信息
    func cancelSelectVideoEffectClip(clipView: WGEffectTimeClipView, sender: WGVideoEffectsView)
    /// 点击空白区域回调
    func clickBlankAreaHandle()
}

public final class WGVideoEffectsView: UIView {
    
    // 获取当前播放进度(百分比)
    public var currentProgress: CGFloat {
        let centerRect = self.centerLineView.converRect(fatherView: self.trackView)
        var progress = centerRect.midX/self.trackView.frame.width
        progress = progress < 0 ? 0 : progress
        progress = progress > 1.0 ? 1.0 : progress
        return progress
    }
    // 视频总时长
    public var videoDration: CGFloat {
        return WGVideoEffectsConfig.shareModel.videoDuration
    }
    // 时间轴总宽度
    private var scaleWidth: CGFloat {
        let timeScale = WGVideoEffectsConfig.shareModel.timeScale
        let width = (timeScaleWidth/timeScale)*videoDration
        return width+timeScaleWidth
    }
    public weak var delegate: WGVideoEffectsDelegate?
    // 特效片段集合
    public var clipViewList: [WGEffectTimeClipView] {
        return self.trackView.clipViewList
    }
    
    // scroll容量宽度
    private var scrollContentWidth: CGFloat {
        return (scaleWidth+self.bounds.width-timeScaleWidth)
    }
    // 时间刻度宽度
    private var timeScaleWidth: CGFloat {
        return WGVideoEffectsConfig.shareModel.timeScaleStyle.timeScaleWidth
    }
    
    public var selectClipView: WGEffectTimeClipView?
    // 长按移动的view
    var longPressView: UFLongPressMoveView?
    var longPressStartPoint: CGPoint = .zero
    var longPressStartX: CGFloat = 0    // 长按拖动起始位置

    var clipRects: [CGRect] = []         // 判断各个特效片段之间是否有重叠问题
    var clipProgressRects: [WGEffectTimeClipView: CGRect] = [:] // 左右滑块移动限制
    var recordingClipView: WGEffectTimeClipView?
    
    var isLongPressBegin = false {
        didSet {
            self.scrollView.isScrollEnabled = !isLongPressBegin
        }
    }
    var scrollDirection: UFVideoEditScrollDirection = .noMove
    var lastMovePoint: CGPoint = .zero
    var sliderWidth: CGFloat {
        return WGVideoEffectsConfig.shareModel.sliderCommonStyle.sliderWidth
    }
    var autoScroll: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setUpUI() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

        self.addSubview(scrollView)
        self.scrollView.contentSize = CGSize.init(width: scrollContentWidth, height: 0)
        self.scrollView.addSubview(videoTimeScaleView)
        self.scrollView.addSubview(thumbsView)
        self.scrollView.addSubview(self.trackView)
        self.scrollView.addSubview(self.recordingTrackView)
        
        self.videoTimeScaleView.videoDuration = self.videoDration
        self.thumbsView.timeThumbs = WGVideoEffectsConfig.shareModel.timeThumbs
        self.addSubview(self.centerLineView)
    }
    
    // 整体滑板
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.init(frame: self.bounds)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.tag = 1
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(clickCancelSelect))
        scrollView.addGestureRecognizer(tapGes)
        return scrollView
    }()
    // 时间刻度
    lazy var videoTimeScaleView: WGVideoEffectsTimeScaleView = {
        let style = WGVideoEffectsConfig.shareModel.timeScaleStyle
        let videoTimeView =  WGVideoEffectsTimeScaleView.init(frame: CGRect.init(x: self.bounds.width/2.0-timeScaleWidth, y: style.timeScaleTop, width: scaleWidth, height: style.timeScaleHeight))
        videoTimeView.isUserInteractionEnabled = false
        return videoTimeView
    }()
    
    // 关键帧view
    lazy var thumbsView: WGVideoEffectsThumbsView = {
        let style = WGVideoEffectsConfig.shareModel.thumbsToolStyle
        let thumbSView = WGVideoEffectsThumbsView.init(frame: CGRect.init(x: videoTimeScaleView.frame.minX+timeScaleWidth, y: videoTimeScaleView.frame.maxY+style.thumbAndTimeDistance, width: videoTimeScaleView.frame.width-timeScaleWidth, height: style.thumbsHeight))
        thumbSView.tapActionHandle = {[weak self] in
            self?.clickCancelSelect()
        }
        return thumbSView
    }()
    // 轨道view
    lazy var trackView: WGVideoEffectsTrackView = {
        let style = WGVideoEffectsConfig.shareModel.sliderCommonStyle
        let view = WGVideoEffectsTrackView.init(frame: CGRect.init(x: thumbsView.frame.minX, y: thumbsView.frame.maxY+style.trackDistance, width: thumbsView.frame.width, height:style.trackHeight))
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(clickCancelSelect))
        view.addGestureRecognizer(tapGes)
        return view
    }()
    lazy var recordingTrackView: UIView = {
        let view = UIView.init(frame: self.trackView.frame)
        view.isHidden = true
        return view
    }()
    // 中心轴
    lazy var centerLineView: UIView = {
        let style = WGVideoEffectsConfig.shareModel.centerLineStyle
        let width = style.centerLineWidth
        let startX = (self.bounds.width-width)/2.0
        let height = self.bounds.height-style.centerLineTop-style.centerLineBottom
        let view = UIView.init(frame: CGRect.init(x: startX, y: style.centerLineTop, width: width, height: height))
        view.layer.cornerRadius = width/2.0
        view.layer.masksToBounds = true
        view.backgroundColor = style.centerLineColor
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.4).cgColor
        view.layer.shadowOffset = CGSize.init(width: 0, height: 1)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 2
        return view
    }()
    // 匀速滑动
    lazy var displayLink: CADisplayLink = {
        let display = CADisplayLink(target: self , selector: #selector(doDisplayLink(sender:)))
        display.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return display
    }()
    
    // 播放进度变化
    func doDelegateValueChange() {
        let centerRect = self.centerLineView.converRect(fatherView: self.trackView)
        var progress = centerRect.midX/self.trackView.frame.width
        progress = progress < 0 ? 0 : progress
        progress = progress > 1.0 ? 1.0 : progress
        self.delegate?.didVideoEffectProgressChange(duration: progress*videoDration, sender: self)
    }
    func doDelegateEffectInfoChange(type: UFVideoEffectUpdateType) {
        var clipList = self.clipViewList
        for view in clipList {
            let rect = view.bgMaskView.converRect(fatherView: self.trackView)
            let proRect = view.processView.converRect(fatherView: self.trackView)
            view.effectClipInfo.startTimeOriginEffectInViddeo = (rect.minX/self.trackView.frame.width)*self.videoDration
            view.effectClipInfo.endTimeOriginEffectInViddeo = (rect.maxX/self.trackView.frame.width)*self.videoDration
            view.effectClipInfo.startTimeInVideo = (proRect.minX/self.trackView.frame.width)*self.videoDration
            view.effectClipInfo.clipEffectDuration = (proRect.width/self.trackView.frame.width)*self.videoDration
        }
        // 从右向左排序
        clipList.sort(by: { (view1, view2) -> Bool in
            let rect1 = view1.processView.converRect(fatherView: self.trackView)
            let rect2 = view2.processView.converRect(fatherView: self.trackView)
            return (rect1.minX < rect2.minX ? true : false)
        })
        var infos: [UFEffectClipInfo] = []
        for view in clipList {
            infos.append(view.effectClipInfo)
        }
        self.delegate?.videoEffectEditFinish(effectInfos: infos, type: type, sender: self)
    }
    
    // 点击取消选中片段
    @objc func clickCancelSelect() {
        self.delegate?.clickBlankAreaHandle()
    }
    // 更新录制状态
    func updateRecordMaskStatus(start: Bool) {
        self.recordingTrackView.isHidden = !start
        let alpha = start ? WGVideoEffectsConfig.shareModel.recodingAlpha : 1.0
        self.videoTimeScaleView.alpha = alpha
        self.thumbsView.alpha = alpha
        self.trackView.alpha = alpha
    }
    /// 进入后台，取消一切编辑操作
    @objc private func appWillResignActive() {
        if let clipView = self.selectClipView {
            /// 取消长按拖动编辑
            if self.longPressView != nil {
                self.didEffectTimeClipLongPressEndAction(longpressGes: UILongPressGestureRecognizer.init(), sender: clipView)
            }
            /// 取消滑块slider编辑
            if clipView.clipViewStatus == .select {
                clipView.bgMaskView.isHidden = true
                clipView.processView.isUserInteractionEnabled = true
                clipView.sliderScrollDirection = .noMove
            }
        }
    }

}

extension WGVideoEffectsView: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegate?.didVideoEffectStartAction(sender: self, tag: 1)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            doDelegateValueChange()
            self.scrollEnd()
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        doDelegateValueChange()
        self.scrollEnd()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !autoScroll {
            doDelegateValueChange()
        }
    }
    
    private func scrollEnd() {
        if let clipView = self.selectClipView, WGVideoEffectsConfig.shareModel.scrollEndCancelSelectClip {
            let clipRect = clipView.processView.converRect(fatherView: self.trackView)
            let lineRect = self.centerLineView.converRect(fatherView: self.trackView)
            if !clipRect.intersects(lineRect) {
                self.cancelSelectClipView()
            }
        }
        self.delegate?.didVideoEffectEndAction(sender: self, tag: 1)
    }
}
