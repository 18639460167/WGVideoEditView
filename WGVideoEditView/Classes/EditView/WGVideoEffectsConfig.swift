//
//  UFVideoEditTimeInfoModel.swift
//  UFSliderViewDemo
//
//  Created by 窝瓜 on 2021/7/17.
//  Copyright © 2021 black. All rights reserved.
//  视频编辑器基本信息

import UIKit
import AudioToolbox

// 震动效果
public func PlaySystemSound() {
    // 1519
    AudioServicesPlaySystemSound(1520)
}

// scroll滚动方向
public enum UFVideoEditScrollDirection {
    case noMove
    case left
    case right
}

// 全部更新数据类型
public enum UFVideoEffectUpdateType {
    case add            // 增加片段
    case delete         // 删除片段
    case update         // 片段信息更新(移动、调整时长)
    case replace        // 替换
}

public final class WGVideoEffectsConfig: NSObject {
    public static let shareModel: WGVideoEffectsConfig = WGVideoEffectsConfig.init()
    public var videoDuration: CGFloat = 0.0   // 视频时长
    public var minDuration: CGFloat = 1.0       // 单个片段最短时长
    public var timeScale: CGFloat = 1.0         // 时间刻度(默认1s)
    public var timeThumbs: [UIImage] = []       // 视频关键帧缩略图
    public var scrollSpeed: CGFloat = 1.5       // 到达屏幕边缘，scroll自动滚动速度(默认每秒1.5pt)
    public var adsorptionDistance: CGFloat = 4.0 // 产生吸附效果的距离
    
    public var recodingAlpha: CGFloat = 0.3       // (录制过程中除了当前录制片段，其他试图的透明度变化)
    
    public var clipViewNormalAlpha: CGFloat = 0.7   // 特效片段默认透明度
    public var clipViewSelectAlpha: CGFloat = 1.0   // 特效片段选中透明度
    public var clipViewMoveAlpha: CGFloat = 0.4     // 特效片段长按透明度
    public var clipViewRadius: CGFloat = 4.0        // 特效片段圆角大小
    
    public var scrollEndCancelSelectClip = true   // 滑动结束如果当前帧没在选中片段上，则取消片段选中
    
    public var sliderCommonStyle: UFSliderCommonStyle = UFSliderCommonStyle.init()  // 调整时长滑块UI样式
    public var timeScaleStyle: UFTimeScaleToolStyle = UFTimeScaleToolStyle.init()   // 时间刻度栏UI样式
    public var thumbsToolStyle: UFThumbsToolStyle = UFThumbsToolStyle.init()        // 关键帧栏UI样式
    public var centerLineStyle: UFCenterLineStyle = UFCenterLineStyle.init()        // 中心轴UI样式
    
    // 注意：需要先设置视频时长
    public func getThumbs() -> NSInteger {
        let scale = self.timeScale
        var thumbs = Int(floor(videoDuration/scale))
        if CGFloat(thumbs)+scale/2.0 < videoDuration {
            thumbs += 1
        } else {
            thumbs += 2
        }
        print("关键帧数量===\(thumbs)")
        return thumbs
    }
    
}

// 时间刻度UI样式
public struct UFTimeScaleToolStyle {
    public init() {}
    public var timeScaleHeight: CGFloat = 20.0  // 时间刻度栏高度
    public var timeScaleTop: CGFloat = 2.0      // 时间刻度距离顶部高度
    public var timeScaleWidth: CGFloat = 40.0     // 每个时间刻度宽度
    public var font: UIFont = UIFont.systemFont(ofSize: 9, weight: .bold)   // 字体大小
    public var fontColor: UIColor = UIColor.white.withAlphaComponent(0.3)   // 字体颜色
    public var tagSize: CGSize = CGSize.init(width: 1, height: 2)           // 中心刻度大小
    public var tagColor: UIColor = UIColor.white.withAlphaComponent(0.3)    // 中心刻度颜色
}
// 关键帧栏UI样式
public struct UFThumbsToolStyle {
    public init() {}
    public var thumbsHeight: CGFloat = 32.0     // 关键帧栏高度CGFloat
    public var thumbAndTimeDistance: CGFloat = 4    // 关键帧与时间刻度的垂直间距
    public var radius: CGFloat = 4.0            // 圆角大小
    public var alpha: CGFloat = 0.8             // 缩略图透明度
    public var tapHighlight: Bool = true        // 点击是否有高亮状态(默认按压有个透明度变化)
}
// 调整时长滑块通用样式
public struct UFSliderCommonStyle {
    public init() {}
    public var sliderWidth: CGFloat = 18.0      // 左右滑块宽度
    public var leftSliderImage: UIImage?        // 左滑杆图片
    public var rightSliderImage: UIImage?       // 右滑杆图片
    public var trackDistance: CGFloat = 8.0     // 轨道之间的垂直距离
    public var trackHeight: CGFloat = 40.0      // 轨道高度
}
// 中心轴UI样式
public struct UFCenterLineStyle {
    public init() {}
    public var centerLineWidth: CGFloat = 2.0  // 中心轴宽度
    public var centerLineColor: UIColor = UIColor.white    // 中心轴背景色
    public var centerLineTop: CGFloat = 20.0  // 距离顶部高度
    public var centerLineBottom: CGFloat = 5.0    // 距离底部高度
}

// 增加片段的信息
public class UFEffectClipInfo: NSObject, NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let objc = UFEffectClipInfo.init()
        if let customer = self.extraInformation as? NSObject, customer.conforms(to: NSCopying.self) {
            objc.extraInformation = customer.copy()
        } else {
            objc.extraInformation = extraInformation
        }
        objc.startTimeInVideo = self.startTimeInVideo
        objc.clipOriginDuration = self.clipOriginDuration
        objc.startTimeInEffect = self.startTimeInEffect
        objc.clipEffectDuration = self.clipEffectDuration
        objc.effectName = self.effectName
        objc.effectID = self.effectID
        objc.font = self.font
        objc.fontColor = self.fontColor
        objc.backgroundColor = self.backgroundColor
        objc.radius = self.radius
        objc.borderColor = self.borderColor
        objc.nameLeftMargin = self.nameLeftMargin
        objc.betweenDistance = self.betweenDistance
        objc.clipID = self.clipID
        objc.leftDistance = self.leftDistance
        objc.rightDistance = self.rightDistance
        return objc
    }
    
    public var effectName: String = ""                  // 特效显示名称
    public var effectID: String = ""                    // 特效ID
    public var startTimeInVideo: CGFloat = 0.0          // 有效片段相对于视频的起始时间
    public var clipOriginDuration: CGFloat = 0.0        // 特效片段的原始时长(录制完就不会变了)
    public var startTimeInEffect: CGFloat = 0.0         // 相对于原始时长起始时间(eg: 2)
    public var clipEffectDuration: CGFloat = 0.0        // 裁剪之后的有效时长
    // 原始片段在视频中的起始位置
    public var startTimeOriginEffectInViddeo: CGFloat = 0.0
    // 原始片段在视频中的结束位置
    public var endTimeOriginEffectInViddeo: CGFloat = 0.0
    public var extraInformation: Any?                      // 外面传进来的额外信息(矩阵、帧图片等)
    
    public var font: UIFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    public var fontColor: UIColor = UIColor.white
    public var backgroundColor: UIColor = UIColor.white  // 背景色
    public var radius: CGFloat = 4.0                // 圆角大小
    public var borderColor: UIColor = UIColor.white // 边框颜色
    public var nameLeftMargin: CGFloat = 8.0        // 文字左边距
    public var betweenDistance: CGFloat = 1.0       // 两个特效间的距离
    
    public var clipID: String = ""      // 特效唯一标示(组件内部生成，外部不用赋值)
    var leftDistance: CGFloat = 0       // 距离左片段距离(内部片段之间吸附用到)
    var rightDistance: CGFloat = 0      // 距离右片段距离(内部片段之间吸附用到)
}

