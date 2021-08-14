//
//  ViewController.swift
//  WGVideoEditView
//
//  Created by 1587337963@qq.com on 08/14/2021.
//  Copyright (c) 2021 1587337963@qq.com. All rights reserved.
//

import UIKit
import WGVideoEditView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let view = WGVideoEffectsView.init(frame: CGRect.init(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 300))
        self.view.addSubview(view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

