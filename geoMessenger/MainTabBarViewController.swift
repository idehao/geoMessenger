//
//  MainTabBarViewController.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 3/24/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBar.barTintColor = UIColor(red:0.70, green:0.97, blue:0.91, alpha:1.0)
        
        // how to convert hex value to UIcolor
        //http://uicolor.xyz/#/hex-to-ui
        
        //equivalent to: #3498db
    }

}
