//
//  UFVideoEditTools.swift
//  UFViewComponent
//
//  Created by 窝瓜 on 2021/7/21.
//

import Foundation
import UIKit

extension UIView {
    func converRect(fatherView: UIView? = nil) -> CGRect {
        var faView = fatherView
        if fatherView == nil {
            faView = self.superview
        }
        return self.convert(self.bounds, to: faView)
    }
}

public extension UIImage {
    static func uf_image(imageName:String,bundle:(anyClass:AnyClass?,bundleName:String?)?) -> UIImage?{
          guard bundle != nil else {
              return UIImage(named: imageName)
          }
          if let bundleInClass = bundle?.anyClass {
              let frameworkBundle = Bundle.init(for: bundleInClass)
              if let bundleName = bundle?.bundleName , let url = frameworkBundle.url(forResource: bundleName, withExtension: "bundle") {
                  let imageBundle =  Bundle(url: url)
                  return UIImage(named: imageName, in: imageBundle, compatibleWith: nil)
              }else {
                  return UIImage(named: imageName, in: frameworkBundle, compatibleWith: nil)
              }
          }
          return nil
      }
    
    static func uf_image(named name: String, componentClass: AnyClass?) -> UIImage? {
        return uf_image(imageName: name, bundle: (componentClass, nil))
    }
}
