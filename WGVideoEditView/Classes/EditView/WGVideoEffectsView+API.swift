//
//  UFVideoEditView+API.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/19.
//  Copyright © 2021 black. All rights reserved.
//

import Foundation
import UIKit

extension WGVideoEffectsView {
    
    /// 更新播放进度
    /// -params
    /// -progress: (0-1)
    public func updatePlayProgress(progress: CGFloat) {
        var newProgress = progress < 0 ?  0 : progress
        newProgress = newProgress > 1.0 ? 1.0 : newProgress
        let offsetX = self.trackView.frame.width*newProgress
        self.autoScroll = true
        self.scrollView.setContentOffset(CGPoint.init(x: offsetX, y: 0), animated: false)
        if let clipView = self.selectClipView, WGVideoEffectsConfig.shareModel.scrollEndCancelSelectClip {
            let clipRect = clipView.processView.converRect(fatherView: self.trackView)
            let lineRect = self.centerLineView.converRect(fatherView: self.trackView)
            if !clipRect.intersects(lineRect) {
                self.cancelSelectClipView()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+0.0001) {
            self.autoScroll = false
        }
    }
    
    /// 删除片段
    /// -handle: 是否需要更新回调全部信息
    /// -type: 更新类型(删除/覆盖)
    public func deleteEffectClip(clipView: WGEffectTimeClipView? = nil,
                                 handle: Bool = true,
                                 type: UFVideoEffectUpdateType = .delete) {
        var deleteClipView = self.selectClipView
        if clipView != nil {
            deleteClipView = clipView
        } else {
            if let selectClip = self.selectClipView {
                self.delegate?.cancelSelectVideoEffectClip(clipView: selectClip, sender: self)
            }
        }
        if let delView = deleteClipView {
            self.trackView.deleteClipView(clipView: delView)
            if handle {
                self.doDelegateEffectInfoChange(type: type)
            }
        }
        self.selectClipView = nil
    }
    
    /// 取消选中片段
    public func cancelSelectClipView() {
        if let clipView = self.selectClipView {
            self.delegate?.cancelSelectVideoEffectClip(clipView: clipView, sender: self)
        }
        self.selectClipView?.clipViewStatus = .normal
        self.selectClipView = nil
    }
    
    /// 素材信息替换
    public func replaceClipViewEffectInfo(clipView: WGEffectTimeClipView? = nil) {
        let selectView = (clipView != nil) ? clipView : self.selectClipView
        if let clipView = selectView {
            clipView.updateEffectInfo()
            self.doDelegateEffectInfoChange(type: .replace)
        }
    }
    
    /// 增加特效片段
    /// - info: 特效基本信息(起始帧、时长、UI样式)
    /// - 内部会根据info对覆盖的片段做分段处理
    /// - select: 是否选中新增的片段
    public func addEffectClip(info: UFEffectClipInfo,
                              select: Bool = false) {
        let config = WGVideoEffectsConfig.shareModel
        let widthScale = self.trackView.frame.width / config.videoDuration
        let startX = info.startTimeInVideo * widthScale-config.sliderCommonStyle.sliderWidth
        let width = info.clipOriginDuration * widthScale + 2.0*config.sliderCommonStyle.sliderWidth
        let addInfo = info.copy() as! UFEffectClipInfo
        if addInfo.clipID.count == 0 {
            addInfo.clipID = NSUUID().uuidString.lowercased()
        }
        let clipView = WGEffectTimeClipView.init(frame: CGRect.init(x: startX, y: 0, width: width, height: config.sliderCommonStyle.trackHeight), info: addInfo)
        clipView.sliderDelegate = self
        clipView.longPressDelegate = self
        self.trackView.addClipView(view: clipView)
        if select {
            clipView.sliderDelegate?.didTapClipViewActin(sender: clipView)
        }
        let newConvertRect = clipView.processView.converRect(fatherView: self.trackView)
        let intersectsList = self.trackView.clipViewList.filter { (view) -> Bool in
            if view != clipView {
                let convertRect = view.processView.converRect(fatherView: self.trackView)
                return convertRect.intersects(newConvertRect)
            }
            return false
        }
        
        let minTimScale = (WGVideoEffectsConfig.shareModel.minDuration/WGVideoEffectsConfig.shareModel.videoDuration)*self.trackView.frame.width
        for view in intersectsList {
            let progressView = view.processView
            let clipRect = progressView.converRect(fatherView: self.trackView)
            let progressRect = clipView.processView.converRect(fatherView: view)
            if newConvertRect.minX <= clipRect.minX && newConvertRect.maxX >= clipRect.maxX {
                // 该片段被完全覆盖，需要删除掉
                self.deleteEffectClip(clipView: view, handle: false, type: .add)
                continue
            }
            // 判断左侧裁剪情况
            if (newConvertRect.minX-minTimScale < clipRect.minX) {
                if newConvertRect.maxX+minTimScale > clipRect.maxX {
                    // 两端都小于最短时长，需要删除
                    self.deleteEffectClip(clipView: view, handle: false, type: .add)
                } else {
                    // 右侧移动裁剪
                    let startX = progressRect.maxX-WGVideoEffectsConfig.shareModel.sliderCommonStyle.sliderWidth
                    view.updateSliderFrame(left: true, minX: startX)
                }
            } else if (newConvertRect.maxX+minTimScale > clipRect.maxX) {
                if (newConvertRect.minX-minTimScale < clipRect.minX) {
                    // 两端都小于最短时长，需要删除
                    self.deleteEffectClip(clipView: view, handle: false, type: .add)
                } else {
                    // 左侧移动裁剪
                    let startX = progressRect.minX
                    view.updateSliderFrame(left: false, minX: startX)
                }
            } else {
                // 复制成2个片段，一个向右裁剪，一个向左裁剪
                // 1、新的view左侧移动裁剪
                let newInfo = view.effectClipInfo.copy() as! UFEffectClipInfo
                newInfo.clipID = NSUUID().uuidString.lowercased()
                let newClipView = WGEffectTimeClipView.init(frame: view.frame, info: newInfo)
                newClipView.rightSliderIcon.frame = view.rightSliderIcon.frame
                newClipView.leftSliderIcon.frame = view.leftSliderIcon.frame
                newClipView.sliderDelegate = self
                newClipView.longPressDelegate = self
                self.trackView.addClipView(view: newClipView)
                self.trackView.bringSubview(toFront: clipView)
                var startX = progressRect.maxX-WGVideoEffectsConfig.shareModel.sliderCommonStyle.sliderWidth
                newClipView.updateSliderFrame(left: true, minX: startX)
                // 2、当前view右侧移动裁剪
                startX = progressRect.minX
                view.updateSliderFrame(left: false, minX: startX)
            }
        }
        self.doDelegateEffectInfoChange(type: .add)
    }
}
// MARK: - 录制功能
extension WGVideoEffectsView {
    /// 开始录制
    /// -info: 片段信息(背景颜色、名称)
    public func startRecord(info: UFEffectClipInfo) {
        self.cancelSelectClipView()
        self.updateRecordMaskStatus(start: true)
        let currentProgress = self.currentProgress
        let clipInfo = info
        clipInfo.clipID = NSUUID().uuidString.lowercased()
        clipInfo.startTimeInVideo = currentProgress*videoDration
        let startX = currentProgress*self.recordingTrackView.frame.width-WGVideoEffectsConfig.shareModel.sliderCommonStyle.sliderWidth
        let width = 0.5 + 2.0*sliderWidth
        let clipView = WGEffectTimeClipView.init(frame: CGRect.init(x: startX, y: 0, width: width, height: WGVideoEffectsConfig.shareModel.sliderCommonStyle.trackHeight), info: clipInfo)
        self.recordingTrackView.addSubview(clipView)
        clipView.clipViewStatus = .recording
        self.recordingClipView = clipView
        self.isUserInteractionEnabled = false
    }
    
    /// 更新录制时间
    /// progress: 当前播放进度0-1
    public func updateRecordingProgress(progress: CGFloat) {
        let duration = WGVideoEffectsConfig.shareModel.videoDuration*progress
        if let clipView = self.recordingClipView {
            clipView.effectClipInfo.clipOriginDuration = duration-clipView.effectClipInfo.startTimeInVideo
            if (clipView.effectClipInfo.clipOriginDuration + clipView.effectClipInfo.startTimeInVideo) >= videoDration {
                clipView.effectClipInfo.clipOriginDuration = videoDration-clipView.effectClipInfo.startTimeInVideo
            }
            let width = (clipView.effectClipInfo.clipOriginDuration/WGVideoEffectsConfig.shareModel.videoDuration)*self.trackView.frame.width
            var clipFrame = clipView.frame
            clipFrame.size.width = width+2.0*sliderWidth
            clipView.frame = clipFrame
            clipView.updateRecordFrame()
            self.updatePlayProgress(progress: progress)
        }
    }
    
    /// 录制完成
    /// - 返回信息：录制是否成功
    public func recordingFinish() -> Bool{
        self.isUserInteractionEnabled = true
        var recordResult: Bool = false
        if let clipView = self.recordingClipView {
            if clipView.effectClipInfo.clipOriginDuration >= 1.0 {
                self.addEffectClip(info: clipView.effectClipInfo)
                recordResult = true
            } else {
                // 录制失败，seek到录制开始时间
                let rect = clipView.processView.converRect(fatherView: self.trackView)
                let offset = CGPoint.init(x: rect.minX, y: 0)
                self.scrollView.setContentOffset(offset, animated: true)
            }
        }
        self.recordingClipView?.removeFromSuperview()
        self.recordingClipView = nil
        self.updateRecordMaskStatus(start: false)
        return recordResult
    }
}
