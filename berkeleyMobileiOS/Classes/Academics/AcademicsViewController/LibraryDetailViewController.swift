//
//  LibraryDetailViewController.swift
//  berkeleyMobileiOS
//
//  Created by Sampath Duddu on 11/13/16.
//  Copyright © 2016 org.berkeleyMobile. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMaps

fileprivate let kLibraryCellHeight: CGFloat = 125.0

class LibraryDetailViewController: UIViewController, IBInitializable, GMSMapViewDelegate, CLLocationManagerDelegate, ResourceDetailProvider {
    var image: UIImage?

    @IBOutlet weak var LibraryTableView: UITableView!

    @IBOutlet weak var libraryStack: UIStackView!
    @IBOutlet var libraryStartEndTime: UILabel!
    @IBOutlet var libraryStatus: UILabel!
    @IBOutlet var libraryImage: UIImageView!
    @IBOutlet var libraryDetailTableView: UITableView!
    @IBOutlet var libraryMapView: GMSMapView!
    @IBOutlet var libraryName: UILabel!
    @IBOutlet var libraryAddress: UIButton!
    @IBOutlet weak var libraryInfoTableview: UITableView!

    var library: Library!
    var locationManager = CLLocationManager()


    var iconImages = [UIImage]()
    var libInfo = [String]()
    
    var weeklyTimes = [String]()

    // MARK: - IBInitalizable
    typealias IBComponent = LibraryDetailViewController

    static var componentID: String { return className(IBComponent.self) }

    static func fromIB() -> IBComponent
    {
        return UIStoryboard.academics.instantiateViewController(withIdentifier: self.componentID) as! IBComponent
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0 {
            return 70
        } else {
            return 55
        }
    }


    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        iconImages.append(#imageLiteral(resourceName: "hours_2.0"))
        iconImages.append(#imageLiteral(resourceName: "phone_2.0"))
        iconImages.append(#imageLiteral(resourceName: "location_2.0"))

        libInfo.append(getLibraryStatusHours())
        libInfo.append(getLibraryPhoneNumber())
        libInfo.append(getLibraryLoc())

        libraryInfoTableview.delegate = self
        libraryInfoTableview.dataSource = self

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        var trivialDayStringsORDINAL = ["", "SUN","MON","TUE","WED","THU","FRI","SAT"]
        var localOpeningTime = ""
        var localClosingTime = ""
        var timeArr = [String]()
        for i in 1...7 {
            if let t = (self.library?.weeklyOpeningTimes[i]) {
                localOpeningTime = dateFormatter.string(from:t)
            }
            if let t = (self.library?.weeklyClosingTimes[i]) {
                localClosingTime = dateFormatter.string(from:t)
            }
            
            var timeRange:String = localOpeningTime + " : " + localClosingTime
            
            if (localOpeningTime == "" && localClosingTime == "") {
                timeRange = "CLOSED ALL DAY"
            }
            
            var timeInfo = trivialDayStringsORDINAL[i] + "  " + timeRange
            
            weeklyTimes.append(timeInfo)
        }
        
        print("wassap")
        
        
        setUpMap()
    }
    func getLibraryStatusHours() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        dateFormatter.timeZone = TimeZone(abbreviation: "PST")
        var trivialDayStringsORDINAL = ["", "SUN","MON","TUE","WED","THU","FRI","SAT"]
        let dow = Calendar.current.component(.weekday, from: Date())
        let translateddow = (dow - 2 + 7) % 7
        var localOpeningTime = ""
        var localClosingTime = ""
        if let t = (self.library?.weeklyOpeningTimes[translateddow]) {
            localOpeningTime = dateFormatter.string(from:t)
        }
        if let t = (self.library?.weeklyClosingTimes[translateddow]) {
            localClosingTime = dateFormatter.string(from:t)
        }

        var timeRange:String = localOpeningTime + " to " + localClosingTime
        var status = "Closed"

        if (localOpeningTime == "" && localClosingTime == "") {
            timeRange = "Closed Today"
        } else {
            if self.library.isOpen {
                status = "Open"
            }
        }

        var timeInfo = status + "    " + timeRange
        if (timeRange == "Closed Today") {
            timeInfo = timeRange
        }
        return timeInfo
    }

    func getLibraryPhoneNumber() -> String {
        return (self.library?.phoneNumber)!
    }

    func getLibraryWebsite() -> String {
//        return library.
        return "marisawong.comlmao"

    }


    func getLibraryLoc() -> String {
        if let loc = library.campusLocation {
            return loc
        } else {
            return "UC Berkeley"
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func callLibrary() {
        let numberArray = self.library?.phoneNumber?.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
        var number = ""
        for n in numberArray! {
            number += n
        }

        if let url = URL(string: "telprompt://\(number)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }


    @IBAction func favoriteLibrary(_ sender: Any) {
        guard let library = self.library else {
            return
        }
        library.isFavorited = !library.isFavorited
        FavoriteStore.shared.update(library)

        if library.isFavorited {
            (sender as! UIButton).setImage(#imageLiteral(resourceName: "heart-large-filled"), for: .normal)
        } else {
            (sender as! UIButton).setImage(#imageLiteral(resourceName: "heart-large"), for: .normal)
        }

    }

    func viewLibraryWebsite() {
        UIApplication.shared.open(NSURL(string: "http://www.lib.berkeley.edu/libraries/main-stacks")! as URL,  options: [:], completionHandler: nil)
    }


    func getMap() {
        let lat = library?.latitude!
        let lon = library?.longitude!

        UIApplication.shared.open(NSURL(string: "https://www.google.com/maps/dir/Current+Location/" + String(describing: lat!) + "," + String(describing: lon!))! as URL,  options: [:], completionHandler: nil)

    }

    func setUpMap() {
        //Setting up map view
        libraryMapView.delegate = self
        libraryMapView.isMyLocationEnabled = true
        let camera = GMSCameraPosition.camera(withLatitude: 37.871853, longitude: -122.258423, zoom: 15)
        self.libraryMapView.camera = camera
        self.libraryMapView.frame = self.view.frame
        self.libraryMapView.isMyLocationEnabled = true
        self.libraryMapView.delegate = self
        self.libraryMapView.isUserInteractionEnabled = false
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
            self.libraryMapView.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
        } catch {
            NSLog("The style definition could not be loaded: \(error)")
        }

        var lat = 37.0
        var lon = -37.0
        if let la = library?.latitude {
            lat = la
        }
        if let lo = library?.longitude {
            lon = lo
        }
        let marker = GMSMarker()

        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        marker.title = library?.name

        let status = library?.isOpen;
        if status! {
            marker.icon = #imageLiteral(resourceName: "blueStop")
            marker.snippet = "Open"
        } else {
            marker.icon = #imageLiteral(resourceName: "blueStop")
            marker.snippet = "Closed"

        }
        marker.map = self.libraryMapView

    }


    // MARK: - ResourceDetailProvider
    static func newInstance() -> ResourceDetailProvider {
        return fromIB()
    }

    var resource: Resource
    {
        get { return library }
        set
        {
            if viewIfLoaded == nil, library == nil, let newLibrary = newValue as? Library
            {
                library = newLibrary
                title = library.name
            }
        }
    }

    var text1: String? {
        return nil
    }
    var text2: String? {
        return nil
    }
    var viewController: UIViewController {
        return self
    }
    var imageURL: URL? {
        return library?.imageURL
    }

    var resetOffsetOnSizeChanged = false

    var buttons: [UIButton]
    {
        return []
    }

    var contentSizeChangeHandler: ((ResourceDetailProvider) -> Void)?
        {
        get { return nil }
        set {}
    }

    /// Get the contentSize property of the internal UIScrollView.
    var contentSize: CGSize
    {
        let width = view.bounds.width
        let height = libraryStack.height
        return CGSize(width: width, height: height)

    }

    /// Get/Set the contentOffset property of the internal UIScrollView.
    var contentOffset: CGPoint
        {
        get { return CGPoint.zero }
        set {}
    }

    /// Set of setContentOffset method of the internal UIScrollView.
    func setContentOffset(_ offset: CGPoint, animated: Bool){}

}

extension LibraryDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let libraryInfoCell = libraryInfoTableview.dequeueReusableCell(withIdentifier: "libraryCell", for: indexPath) as! LibraryDetailCell

        libraryInfoCell.libraryIconImage.image = iconImages[indexPath.row]
        libraryInfoCell.libraryIconInfo.text = libInfo[indexPath.row]
        libraryInfoCell.libraryIconInfo.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        return libraryInfoCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell?.selectionStyle = .none

        if indexPath.row == 1 {
            callLibrary()
        }
        else if indexPath.row == 2 {
            getMap()
        }
    }



}











