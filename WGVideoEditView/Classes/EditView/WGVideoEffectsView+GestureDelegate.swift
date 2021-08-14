//
//  UFVideoEditView+GestureDelegate.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/19.
//  Copyright © 2021 black. All rights reserved.
//

import Foundation
import UIKit

// MARK: - 滑块调整时长
extension WGVideoEffectsView: WGEffectTimeClipViewDelegate {
    /// 特效点击
    public func didTapClipViewActin(sender: WGEffectTimeClipView) {
        sender.superview?.bringSubview(toFront: sender)
        if sender.clipViewStatus == .normal {
            sender.clipViewStatus = .select
        } else {
            sender.clipViewStatus = .normal
        }
        if self.selectClipView != sender {
            self.selectClipView?.clipViewStatus = .normal
        }
        if sender.clipViewStatus == .select  {
            self.selectClipView = sender
            self.delegate?.selectVideoEffectClip(clipView: sender, sender: self)
            let rect = sender.processView.converRect(fatherView: self.trackView)
            let offset = CGPoint.init(x: rect.minX, y: 0)
            self.scrollView.setContentOffset(offset, animated: true)
        } else if sender.clipViewStatus == .normal {
            if let clipView = self.selectClipView {
                self.delegate?.cancelSelectVideoEffectClip(clipView: clipView, sender: self)
            }
        }
        self.selectClipView = nil
        if sender.clipViewStatus == .select {
            self.selectClipView = sender
        }
    }
    
    /// 左右滑块开始拖动
    public func didEffectTimeClipSliderStartAction(left: Bool, sender: WGEffectTimeClipView) {
        sender.superview?.bringSubview(toFront: sender)
        self.delegate?.didVideoEffectStartAction(sender: self, tag: 3)
        let currentProgressRect = sender.processView.converRect(fatherView: self.trackView)
        self.clipProgressRects.removeAll()
        for view in self.clipViewList {
            let rect = view.processView.converRect(fatherView: self.trackView)
            if left {
                if rect.maxX <= currentProgressRect.minX  {
                    self.clipProgressRects[view] = rect
                }
            } else {
                if rect.minX >= currentProgressRect.maxX {
                    self.clipProgressRects[view] = rect
                }
            }
        }
    }
    
    /// 左右滑块结束滑动
    public func didEffectTimeClipSliderEndAction(left: Bool, sender: WGEffectTimeClipView) {
        self.doDelegateEffectInfoChange(type: .update)
        // 滑动结束，自动seek
        self.delegate?.didVideoEffectEndAction(sender: self, tag: 3)
        let rect = sender.processView.converRect(fatherView: self.trackView)
        let offset = CGPoint.init(x: left ? rect.minX : rect.maxX, y: 0)
        self.scrollView.setContentOffset(offset, animated: true)
    }
    
    public func didEffectTimeClipSliderValueChange(left: Bool, gesture:UIPanGestureRecognizer, sender: WGEffectTimeClipView) {
        let centerOffset: CGPoint = gesture.translation(in: sender)
        // 更新位置
        let updateRightSliderFrame: ((CGRect, Bool) -> Void) = {[weak self] (frame, updateFrame) in
            if updateFrame {
                var boundFrame = frame
                if left {
                    boundFrame.origin.x = boundFrame.minX < 0 ? 0 : boundFrame.minX
                } else {
                    if boundFrame.minX > sender.frame.width-(self?.sliderWidth ?? 0) {
                        boundFrame.origin.x = sender.frame.width-(self?.sliderWidth ?? 0)
                    }
                }
                if left {sender.leftSliderIcon.frame = boundFrame}
                else {sender.rightSliderIcon.frame = boundFrame}
            }
            sender.updateBorderFrame(left: left, handle: false)
            // 调整滑块更新seek时间
            if let trackView = self?.trackView {
                if left {
                    let frame = sender.leftSliderIcon.converRect(fatherView: trackView)
                    var progress = frame.maxX/trackView.frame.width
                    progress = progress < 0 ? 0 : progress
                    progress = progress > 1.0 ? 1.0 : progress
                    self?.delegate?.didVideoEffectProgressChange(duration: progress*self!.videoDration, sender: self!)
                } else {
                    let frame = sender.rightSliderIcon.converRect(fatherView: trackView)
                    var progress = frame.minX/trackView.frame.width
                    progress = progress < 0 ? 0 : progress
                    progress = progress > 1.0 ? 1.0 : progress
                    self?.delegate?.didVideoEffectProgressChange(duration: progress*self!.videoDration, sender: self!)
                }
            }
            
        }
        if left {
            var leftFrame = sender.leftSliderIcon.frame
            leftFrame.origin.x += centerOffset.x
            if leftFrame.minX <= 0 {
                leftFrame.origin.x = 0
//                sender.leftSliderIcon.frame = leftFrame
                self.displayLink.isPaused = true
            } else if leftFrame.maxX >= (sender.rightSliderIcon.frame.minX-sender.minDistance){
                leftFrame.origin.x = (sender.rightSliderIcon.frame.minX-sender.minDistance-sender.sliderWidth)
//                sender.leftSliderIcon.frame = leftFrame
                self.displayLink.isPaused = true
            } else {
//                let originFrame = sender.leftSliderIcon.frame
//                sender.leftSliderIcon.frame = leftFrame
//                let leftRect = sender.leftSliderIcon.converRect(fatherView: self)
//                sender.leftSliderIcon.frame = originFrame
                // 判断是否在左右边界
//                if leftRect.minX <= 8.0, sender.sliderScrollDirection == .left {
//                    print("scrollview需要自动滚动了")
////                    self.displayLink.isPaused = false
//                } else if leftRect.maxX >= self.scrollView.frame.width-8.0, sender.sliderScrollDirection == .right {
//                    print("scrollview需要自动滚动了")
////                    self.displayLink.isPaused = false
//                } else {
//                    self.displayLink.isPaused = true
//                    // 正常滚动赋值
////                    sender.leftSliderIcon.frame = leftFrame
//                }
            }
            updateRightSliderFrame(leftFrame, true)
            
            if sender.sliderScrollDirection == .left {
                let leftRect = sender.leftSliderIcon.converRect(fatherView: self.trackView)
                let clipRect = sender.converRect(fatherView: self.trackView)
                for (clipView, rect) in self.clipProgressRects {
                    // 到达左边滑块边界，禁止滑动
                    if rect.maxX >= leftRect.minX {
                        let sliderRect = clipView.processView.converRect(fatherView: sender)
                        var frame = sender.leftSliderIcon.frame
                        let minX = CGFloat(abs(sliderRect.minX))
                        let scrollDistance = minX > self.sliderWidth ? self.sliderWidth : minX
                        frame.origin.x = sliderRect.maxX-scrollDistance
                        updateRightSliderFrame(frame, true)
                        break
                    }
                }
                // 是否超出父试图左边界, 增加贴边吸附效果
                var minX = (clipRect.minX < self.sliderWidth) ? (self.sliderWidth-clipRect.minX) : 0
                if clipRect.minX <= 0 {
                    minX = 0
                }
                if leftRect.minX <= minX {
                    let sliderRect = sender.processView.converRect(fatherView: sender)
                    let minX = CGFloat(abs(sliderRect.minX))
                    let scrollDistance = minX > self.sliderWidth ? self.sliderWidth : minX
                    let startX = abs(clipRect.minX)-scrollDistance
                    var frame = sender.leftSliderIcon.frame
                    frame.origin.x = startX
                    updateRightSliderFrame(frame, true)
                }
            }
        } else {
            var rightFrame = sender.rightSliderIcon.frame
            rightFrame.origin.x += centerOffset.x
            if rightFrame.minX < 0 {
                rightFrame.origin.x = 0
            } else if rightFrame.minX < (sender.leftSliderIcon.frame.maxX+sender.minDistance) {
                rightFrame.origin.x = sender.leftSliderIcon.frame.maxX+sender.minDistance
            }
            if rightFrame.maxX >= sender.bounds.width {
                rightFrame.origin.x = sender.bounds.width-sender.sliderWidth
            }
            updateRightSliderFrame(rightFrame, true)
            
            let rightRect = sender.rightSliderIcon.converRect(fatherView: self.trackView)
            // 向右滑动自动吸附
            if sender.sliderScrollDirection == .right {
                for (clipView, rect) in self.clipProgressRects {
                    // 与右边滑块位置重叠了
                    if rightRect.maxX >= rect.minX {
                        let sliderRect = clipView.processView.converRect(fatherView: sender)
                        var frame = sender.rightSliderIcon.frame
                        frame.origin.x = sliderRect.minX
                        updateRightSliderFrame(frame, true)
                        break
                    }
                }
                // 到达右边界增加吸附效果
                if rightRect.maxX > self.trackView.frame.width {
                    let clipRect = sender.converRect(fatherView: self.trackView)
                    let rightWidth = clipRect.maxX-self.trackView.frame.width
                    let startX = sender.frame.width-rightWidth
                    var frame = sender.rightSliderIcon.frame
                    frame.origin.x = startX
                    updateRightSliderFrame(frame, true)
                }
            }
        }
    }
}

// MARK: - 滑块调整位置
extension WGVideoEffectsView: WGEffectTimeClipLongPressDelegate {
    
    /// 长按开始拖动
    public func didEffectTimeClipLongPressStartAction(longpressGes: UILongPressGestureRecognizer,
                                                      sender: WGEffectTimeClipView) {
        self.delegate?.didVideoEffectStartAction(sender: self, tag: 2)
        sender.superview?.bringSubview(toFront: sender)
        let viewPoint = longpressGes.location(in: sender)
        self.lastMovePoint = viewPoint
        // 长按响应之后所有特效取消选中状态
        self.cancelSelectClipView()
        sender.clipViewStatus = .normal
        self.selectClipView = sender
        
        var clipList = self.clipViewList.filter { (view) -> Bool in
            return (view != sender)
        }
        // 从右向左排序
        clipList.sort(by: { (view1, view2) -> Bool in
            let rect1 = view1.processView.converRect(fatherView: self.trackView)
            let rect2 = view2.processView.converRect(fatherView: self.trackView)
            return (rect1.minX < rect2.minX ? true : false)
        })
        self.clipProgressRects.removeAll()
        var lastTrackMaxX: CGFloat = 0
        for index in 0..<clipList.count {
            let view = clipList[index]
            let rect = view.processView.converRect(fatherView: self.trackView)
            view.effectClipInfo.leftDistance = CGFloat(abs(rect.minX-lastTrackMaxX))
            lastTrackMaxX = rect.maxX
            if (index + 1) < clipList.count {
                let lastViewRect = clipList[index+1].processView.converRect(fatherView: self.trackView)
                view.effectClipInfo.rightDistance = CGFloat(abs(lastViewRect.minX-rect.maxX))
            } else {
                view.effectClipInfo.rightDistance = CGFloat(abs(self.trackView.frame.width-rect.maxX))
            }
            self.clipProgressRects[view] = rect
        }
        
        self.isLongPressBegin = true
        PlaySystemSound()
        
        let gesView = sender.processView
        let moveAlpha = WGVideoEffectsConfig.shareModel.clipViewMoveAlpha
        
        let normalView = gesView.snapshotView(afterScreenUpdates: true)
        normalView?.alpha = moveAlpha
        let bgColor = gesView.backgroundView.backgroundColor
        gesView.backgroundView.backgroundColor = UIColor.white.withAlphaComponent(moveAlpha)
        sender.processView.effectNameLbl.alpha = moveAlpha
        let hightView = gesView.snapshotView(afterScreenUpdates: true)
        sender.processView.effectNameLbl.alpha = 1.0
        hightView?.isHidden = true
        gesView.backgroundView.backgroundColor = bgColor
        
        let rect = gesView.convert(gesView.bounds, to:  self)
        self.longPressView = UFLongPressMoveView.init(frame: rect)
        self.longPressView?.normalView = normalView
        self.longPressView?.hightView = hightView
        self.longPressStartPoint = viewPoint
        self.longPressStartX = rect.minX
        self.clipRects.removeAll()
        for clipView in self.clipViewList {
            if clipView != sender {
                let rect = clipView.processView.convert(clipView.processView.bounds, to: self.trackView)
                self.clipRects.append(rect)
            }
        }
        sender.isHidden = true
        if !self.subviews.contains(self.longPressView!) {
            self.insertSubview(self.longPressView!, belowSubview: self.centerLineView)
        }
    }
    
    /// 长按滑动结束
    public func didEffectTimeClipLongPressEndAction(longpressGes: UILongPressGestureRecognizer, sender: WGEffectTimeClipView) {
        self.delegate?.didVideoEffectEndAction(sender: self, tag: 2)
        self.isLongPressBegin = false
        self.displayLink.isPaused = true
        // 这里需要判断是否有2个特效位置重叠的情况
        if let clipView = self.selectClipView, let longPressView = self.longPressView {
            let rect = longPressView.convert(longPressView.bounds, to: self.trackView)
            var canMove = false
            if let _ = self.clipRects.first(where: { (clipRect) -> Bool in
                return clipRect.intersects(rect)
            }) {
                canMove = true
            }
            // 判断是否与其他滑块有重叠的情况
            if !canMove {
                let startX = rect.minX - clipView.processView.frame.minX
                var clipFrame = clipView.frame
                clipFrame.origin.x = startX
                clipView.frame = clipFrame
            } else {
                PlaySystemSound()
            }
            self.longPressView?.removeFromSuperview()
            self.longPressView = nil
            clipView.isHidden = false
        }
        self.selectClipView = nil
        self.doDelegateEffectInfoChange(type: .update)
    }
    
    /// 长按拖动重
    public func didEffectTimeClipLongPressChange(longpressGes: UILongPressGestureRecognizer, sender: WGEffectTimeClipView) {
        let viewPoint = longpressGes.location(in: sender)
        let effectRect = self.longPressView?.converRect(fatherView: self) ?? .zero
        if self.isUserInteractionEnabled == false {
            self.scrollDirection = .noMove
            self.longPressStartPoint = viewPoint
            self.lastMovePoint = viewPoint
            self.longPressStartX = effectRect.minX
            return
        }
        self.scrollDirection = .noMove
        if viewPoint.x > lastMovePoint.x {
            scrollDirection = .right
        } else if viewPoint.x < lastMovePoint.x {
            scrollDirection = .left
        }
        self.lastMovePoint = viewPoint
        
        if effectRect.minX <= 0, scrollDirection == .left{
            // 到达屏幕最左边，需要自动滚动scrollview
            self.displayLink.isPaused = false
            self.longPressStartPoint = viewPoint
            self.longPressStartX = effectRect.minX
        } else if effectRect.maxX >= self.scrollView.frame.width, scrollDirection == .right{
            // 到达屏幕最右边，需要自动滚动scrollview
            self.displayLink.isPaused = false
            self.longPressStartPoint = viewPoint
            self.longPressStartX = effectRect.minX
        } else {
            // 正常调整clip的位置
            self.displayLink.isPaused = true
            let scrollDistance = viewPoint.x - self.longPressStartPoint.x
            var startX = scrollDistance
            startX = self.longPressStartX + startX
            var frame = self.longPressView?.frame ?? .zero
            frame.origin.x = startX
            self.longPressView?.frame = frame
            let newRect = self.longPressView?.converRect(fatherView: self.trackView) ?? .zero
            
            let moveFrame = self.longPressView?.converRect(fatherView: self.trackView) ?? .zero
            var overlapping = true
            if self.clipRects.first(where: { (clipRect) -> Bool in
                return clipRect.intersects(moveFrame)
            }) != nil {
                overlapping = true
            } else {
                overlapping = false
            }
            // 增加吸附效果, 如果和其他view有重叠不加吸附效果
            var leftMinDistance: CGFloat = 0
            var rightMinDistance: CGFloat = 0
            if self.scrollDirection == .left, !overlapping {
                leftMinDistance = WGVideoEffectsConfig.shareModel.adsorptionDistance
            }
            if self.scrollDirection == .right, !overlapping {
                rightMinDistance = WGVideoEffectsConfig.shareModel.adsorptionDistance
            }
            // 轨道最左边吸附效果
            if newRect.minX <= leftMinDistance {
                if self.scrollDirection == .left, leftMinDistance == newRect.minX, !overlapping  {
                    PlaySystemSound()
                }
                startX = 0
                let trackRect = self.trackView.converRect(fatherView: self)
                frame.origin.x = trackRect.minX
                self.longPressView?.frame = frame
                self.longPressStartPoint = viewPoint
                let currentRect = self.longPressView?.converRect(fatherView: self) ?? .zero
                self.longPressStartX = currentRect.minX
            } else if newRect.maxX >= self.trackView.bounds.width-rightMinDistance {
                // 轨道最右边吸附效果----到轨道最右边了，移动不了了
                if self.scrollDirection == .right, (self.trackView.bounds.width-rightMinDistance) == newRect.maxX, !overlapping  {
                    PlaySystemSound()
                }
                let trackRect = self.trackView.converRect(fatherView: self)
                frame.origin.x = trackRect.maxX-frame.width
                self.longPressView?.frame = frame
                self.longPressStartPoint = viewPoint
                let currentRect = self.longPressView?.converRect(fatherView: self) ?? .zero
                self.longPressStartX = currentRect.minX
            } else {
                // 中线/片段之间吸附效果
                //吸附距离
                let adsorbDistance = Double(WGVideoEffectsConfig.shareModel.adsorptionDistance)
                //吸附位置
                let adsorbPosition = self.centerLineView.frame.midX
                if scrollDirection == .left {
                    if Double(effectRect.minX - adsorbPosition) <= adsorbDistance && Double(effectRect.minX - adsorbPosition) >= adsorbDistance - 1.0 {
                        if !overlapping {
                            // 吸附left min
                            self.addCenterLineAdsorption(minX: true, point: viewPoint)
                        }
                    } else if Double(effectRect.maxX - adsorbPosition) <= adsorbDistance && Double(effectRect.maxX - adsorbPosition) >= adsorbDistance - 1.0 {
                        if !overlapping {
                            // 吸附left max
                            self.addCenterLineAdsorption(minX: false, point: viewPoint)
                        }
                    } else {
                        var isStart = false
                        let effectInTrackRect = self.longPressView?.converRect(fatherView: self.trackView) ?? .zero
                        let longPresswidth = self.longPressView?.frame.width ?? .zero
                        if let rectInfo = self.clipProgressRects.first { (view, rect) -> Bool in
                            let rightDistance = Double(effectInTrackRect.maxX-rect.minX)
                            let leftDistance = Double(effectInTrackRect.minX - rect.maxX)
                            if rightDistance > 0, rightDistance <= adsorbDistance, view.effectClipInfo.leftDistance >= longPresswidth {
                                return true
                            }
                            if leftDistance > 0, leftDistance <= adsorbDistance, view.effectClipInfo.rightDistance >= longPresswidth {
                                isStart = true
                                return true
                            }
                            return false
                        } {
                            var moveFrame = self.longPressView?.frame ?? .zero
                            let proRect = rectInfo.key.processView.converRect(fatherView: self)
                            if isStart {
                                moveFrame.origin.x = proRect.maxX
                            } else {
                                moveFrame.origin.x = proRect.minX-moveFrame.width
                            }
                            self.longPressView?.frame = moveFrame
                            print("找到了附近片段:\(rectInfo.key), value:\(rectInfo.value)")
                            self.updateLongPressViewFrame(point: viewPoint)
                        }
                        print("left 和其他片段添加吸附效果")
                    }
                } else if scrollDirection == .right {
                    if Double(effectRect.minX - adsorbPosition) >= -adsorbDistance && Double(effectRect.minX - adsorbPosition) <= -(adsorbDistance - 1.0) {
                        if !overlapping {
                            // 吸附right min
                            self.addCenterLineAdsorption(minX: true, point: viewPoint)
                        }
                    } else if Double(effectRect.maxX - adsorbPosition) >= -adsorbDistance && Double(effectRect.maxX - adsorbPosition) <= -(adsorbDistance - 1.0) {
                        if !overlapping {
                            // 吸附right max
                            self.addCenterLineAdsorption(minX: false, point: viewPoint)
                        }
                    } else {
                        var isStart = false
                        let effectInTrackRect = self.longPressView?.converRect(fatherView: self.trackView) ?? .zero
                        let longPresswidth = self.longPressView?.frame.width ?? .zero
                        if let rectInfo = self.clipProgressRects.first { (view, rect) -> Bool in
                            let rightDistance = Double(rect.minX - effectInTrackRect.maxX)
                            let leftDistance = Double(rect.maxX - effectInTrackRect.minX )
                            if rightDistance > 0, rightDistance <= adsorbDistance, view.effectClipInfo.leftDistance >= longPresswidth {
                                return true
                            }
                            if leftDistance > 0, leftDistance <= adsorbDistance, view.effectClipInfo.rightDistance >= longPresswidth {
                                isStart = true
                                return true
                            }
                            return false
                        } {
                            var moveFrame = self.longPressView?.frame ?? .zero
                            let proRect = rectInfo.key.processView.converRect(fatherView: self)
                            if isStart {
                                moveFrame.origin.x = proRect.maxX
                            } else {
                                moveFrame.origin.x = proRect.minX-moveFrame.width
                            }
                            self.longPressView?.frame = moveFrame
                            print("找到了附近片段:\(rectInfo.key), value:\(rectInfo.value)")
                            self.updateLongPressViewFrame(point: viewPoint)
                        }
                        // right 和其他片段添加吸附效果
                    }
                }
            }
        }
        let moveFrame = self.longPressView?.converRect(fatherView: self.trackView) ?? .zero
        if self.clipRects.first(where: { (clipRect) -> Bool in
            return clipRect.intersects(moveFrame)
        }) != nil {
            self.longPressView?.isHighlight = true
        } else {
            self.longPressView?.isHighlight = false
        }
    }
    
    // 更新scrollview偏移量
    @objc func doDisplayLink(sender: CADisplayLink) {
        var offset = self.scrollView.contentOffset
        if let moveView = self.longPressView {
            if scrollDirection == .left {
                offset.x = offset.x - WGVideoEffectsConfig.shareModel.scrollSpeed
            } else if scrollDirection == .right{
                offset.x = offset.x + WGVideoEffectsConfig.shareModel.scrollSpeed
            }
            scrollView.setContentOffset(offset, animated: false)
            let rect = moveView.converRect(fatherView: self.trackView)
            if scrollDirection == .left, rect.minX <= 0 {
                if rect.minX != 0 {
                    offset.x = offset.x - rect.minX
                    scrollView.setContentOffset(offset, animated: false)
                }
                self.displayLink.isPaused = true
            }
            if scrollDirection == .right, rect.maxX >= self.trackView.frame.width {
                print("向右滚动到边界了")
                if rect.maxX != self.trackView.frame.width {
                    offset.x = offset.x - (rect.maxX-self.trackView.frame.width)
                    scrollView.setContentOffset(offset, animated: false)
                }
                self.displayLink.isPaused = true
            }
            self.doDelegateValueChange()
        }
    }
    
    // 增加中线吸附效果
    func addCenterLineAdsorption(minX: Bool, point: CGPoint) {
        var frame = self.longPressView?.frame ?? .zero
        if minX {
            frame.origin.x = self.centerLineView.frame.maxX
        } else {
            frame.origin.x = self.centerLineView.frame.minX - frame.size.width
        }
        self.longPressView?.frame = frame
        self.updateLongPressViewFrame(point: point)
    }
    
    // 更新移动片段的位置
    func updateLongPressViewFrame(point: CGPoint) {
        self.longPressStartPoint = point
        let currentRect = self.longPressView?.converRect(fatherView: self) ?? .zero
        self.longPressStartX = currentRect.minX
        // 增加一个吸附延迟
        self.isUserInteractionEnabled = false
        PlaySystemSound()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
            self.isUserInteractionEnabled = true
            // 为了解决吸附之后手指和试图不跟随问题，需要重新算下最新的longPressStartX
            if let clipView = self.selectClipView {
                let oldFrame = self.longPressView?.frame ?? .zero
                let viewPoint = clipView.longPressGes.location(in: clipView)
                self.longPressStartPoint = viewPoint
                let distance = viewPoint.x-point.x
                var frame = self.longPressView?.frame ?? .zero
                frame.origin.x += distance
                self.longPressView?.frame = frame
                let currentRect = self.longPressView?.converRect(fatherView: self) ?? .zero
                self.longPressStartX = currentRect.minX
                self.longPressView?.frame = oldFrame
            }
            
        }
    }
}
