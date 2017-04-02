//
//  CampusResourceDetailViewController.swift
//  berkeleyMobileiOS
//
//  Created by Sampath Duddu on 4/1/17.
//  Copyright © 2017 org.berkeleyMobile. All rights reserved.
//

import UIKit
import GoogleMaps
import RealmSwift
import MessageUI

class CampusResourceDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GMSMapViewDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet var campusResourceImage: UIImageView!
    @IBOutlet var campusResourceName: UILabel!
    @IBOutlet var campusResourceAddress: UIButton!
    @IBOutlet var campusResourceMapView: GMSMapView!
    @IBOutlet var campusResourceTableView: UITableView!
    
    var campusResource:CampusResource?
    var locationManager = CLLocationManager()
    var realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //libraryImage.sd_setImage(with: library?.imageURL!)
        campusResourceTableView.delegate = self
        campusResourceTableView.dataSource = self
        self.title = campusResource?.name
        campusResourceName.text = campusResource?.name
        campusResourceAddress.setTitle(campusResource?.campusLocation, for: .normal)
        setUpMap()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "libraryTime") as! LibraryTimeCell
            
            cell.libraryStartEndTime.text = campusResource?.hours
            cell.libraryStatus.isHidden = true
            
//            //Calculating whether the library is open or not
//            var status = "Open"
//            if (self.library?.weeklyClosingTimes[0]?.compare(NSDate() as Date) == .orderedAscending) {
//                status = "Closed"
//            }
//            cell.libraryStatus.text = status
//            if (status == "Open") {
//                cell.libraryStatus.textColor = UIColor.green
//            } else {
//                cell.libraryStatus.textColor = UIColor.red
//            }
//            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "libraryOption") as! LibraryOptionsCell
            // For favoriting
            if (campusResource?.favorited == true) {
                cell.libraryFavoriteButton.setImage(UIImage(named:"heart-large-filled"), for: .normal)
            } else {
                cell.libraryFavoriteButton.setImage(UIImage(named:"heart-large"), for: .normal)
            }
            return cell
        }
    }
    
    func setUpMap() {
        //Setting up map view
        campusResourceMapView.delegate = self
        campusResourceMapView.isMyLocationEnabled = true
        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        self.campusResourceMapView.camera = camera
        self.campusResourceMapView.frame = self.view.frame
        self.campusResourceMapView.isMyLocationEnabled = true
        self.campusResourceMapView.delegate = self
        self.locationManager.startUpdatingLocation()
        
        let kMapStyle =
            "[" +
                "{ \"featureType\": \"administrative\", \"elementType\": \"geometry\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"poi\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"road\", \"elementType\": \"labels.icon\", \"stylers\": [ {  \"visibility\": \"off\" } ] }, " +
                "{ \"featureType\": \"transit\", \"stylers\": [ {  \"visibility\": \"off\" } ] } " +
        "]"
        
        do {
            // Set the map style by passing a valid JSON string.
            self.campusResourceMapView.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
        } catch {
            NSLog("The style definition could not be loaded: \(error)")
            //            print(error)
        }
        
        let lat = campusResource?.latitude!
        let lon = campusResource?.longitude!
        let marker = GMSMarker()
        
        marker.position = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        marker.title = campusResource?.name
        
//        let status = getLibraryStatus(library: library!)
//        if (status == "Open") {
//            marker.icon = GMSMarker.markerImage(with: .green)
//        } else {
//            marker.icon = GMSMarker.markerImage(with: .red)
//        }
//        
//        marker.snippet = status
        marker.map = self.campusResourceMapView
        
    }
    

    @IBAction func callCampusResource(_ sender: Any) {
        
        let numberArray = self.campusResource?.phoneNumber?.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
        var number = ""
        for n in numberArray! {
            number += n
        }
        
        if let url = URL(string: "telprompt://\(number)") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func favoriteCampusResource(_ sender: Any) {
        
        campusResource?.favorited = !(campusResource?.favorited!)!
        
        //Realm adding and deleting favorite libraries
        let favCampusResource = FavoriteCampusResource()
        favCampusResource.name = (campusResource?.name)!
        
        if (campusResource?.favorited == true) {
            (sender as! UIButton).setImage(UIImage(named:"heart-large-filled"), for: .normal)
        } else {
            (sender as! UIButton).setImage(UIImage(named:"heart-large"), for: .normal)
        }
        
        if (campusResource?.favorited)! {
            try! realm.write {
                realm.add(favCampusResource)
            }
        } else {
            let campusResources = realm.objects(FavoriteCampusResource.self)
            for campRes in campusResources {
                if campRes.name == campusResource?.name {
                    try! realm.write {
                        realm.delete(campRes)
                    }
                }
            }
        }

    }
    
    @IBAction func emailCampusResource(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([(campusResource?.email)!])
            mail.setMessageBody("", isHTML: true)
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    

}
