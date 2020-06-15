//
//  TabBarController.swift
//  iNotesPro
//
//  Created by Nirmal Sumanth on 14/06/20.
//  Copyright © 2020 Nirmal Sumanth. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    @IBOutlet weak var defaultTabBar: UITabBar!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        

        // Do any additional setup after loading the view.
        
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "iNotes"{
            NotificationCenter.default.post(name: NotificationConstants.iNotesTabBarItemTapped, object: self, userInfo: nil)
        }
    }

}
