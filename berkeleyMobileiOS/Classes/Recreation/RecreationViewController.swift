//
//  RecreationViewController.swift
//  berkeleyMobileiOS
//
//  Created by Alex Takahashi on 10/30/16.
//  Copyright © 2016 org.berkeleyMobile. All rights reserved.
//

import UIKit
import Material

fileprivate let kGyms = "Gyms"
class RecreationViewController: BaseViewController {
    //Sets up initial tab look for this class
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preparePageTabBarItem()
    }
    override func viewDidLoad() {
        sectionNamesByIndex = [0:kGyms]
        sectionNames = [kGyms]
        
        let activityView = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.view.addSubview(activityView)
        activityView.center=self.view.center;
        activityView.startAnimating()
        
        GymDataSource.fetchGyms { (_ gyms: [Gym]?) in
            if gyms == nil
            {
                print("[ERROR @ RecreationViewController] failed to fetch Gyms")
                activityView.stopAnimating()
            }
            self.resources[kGyms] = gyms!
            self.baseTableView.reloadData()
            
            if self.resources.count == self.sectionNames.count
            {
                activityView.stopAnimating()
            }
        }
    }
    //Make sure tab bar is highlighted properly
    override func viewDidAppear(_ animated: Bool) {
        ConvenienceMethods.setCurrentTabStyle(pageTabBarVC: pageTabBarController!, ForSelectedViewController: self)
    }
    
    //Customize Tab Bar Presence
    private func preparePageTabBarItem() {
        pageTabBarItem.image = #imageLiteral(resourceName: "50x50-Gym_32x32")
        pageTabBarItem.image = pageTabBarItem.image!.withRenderingMode(.alwaysTemplate)
        pageTabBarItem.imageView?.contentMode = .scaleAspectFit
    }

}
