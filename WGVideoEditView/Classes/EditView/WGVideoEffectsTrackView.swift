//
//  UFVideoEditTrackView.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/19.
//  Copyright © 2021 black. All rights reserved.
//  时间轨道

import UIKit

class WGVideoEffectsTrackView: UIView {

    var clipViewList: [WGEffectTimeClipView] = []
    // 子试图超出父试图增加响应事件
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.bounds.contains(point) {return true}
        for subView:UIView in self.subviews {
            let hitPoint = self.convert(point, to: subView)
            if subView.bounds.contains(hitPoint) {return true}
        }
        return false
    }

    // 增加特效片段
    func addClipView(view: WGEffectTimeClipView) {
        clipViewList.append(view)
        self.addSubview(view)
    }
    
    // 删除片段
    func deleteClipView(clipView: WGEffectTimeClipView) {
        clipView.removeFromSuperview()
        let clipList = clipViewList.filter { (view) -> Bool in
            return view != clipView
        }
        self.clipViewList = clipList
    }
}
