//
//  FirstViewController.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 2/26/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class FirstViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var messageNodeRef : FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.delegate = self
        
        // set initial location to Marquette University
        let initialLocation = CLLocation(latitude: 43.043914, longitude: -87.917262)
        centerMapOnLocation(location: initialLocation)
        
        // create Firebase DB reference
        messageNodeRef = FIRDatabase.database().reference().child("messages")
        
        // use the observe handler to poll for realtime updates
        let pinMessageId = "msg-1"
        var pinMessage: Message?
        messageNodeRef.child(pinMessageId).observe(.value, with: { (snapshot: FIRDataSnapshot) in
            
            if let dictionary = snapshot.value as? [String: Any]
            {
                // if the pin already exists, remove it first
                if pinMessage != nil
                {
                    self.mapView.removeAnnotation(pinMessage!)
                }
                
                // map the JSON tags to the Message class' properties
                let pinLat = dictionary["latitude"] as! Double
                let pinLong = dictionary["longitude"] as! Double
                let messageDisabled = dictionary["isDisabled"] as! Bool
                
                let message = Message(title: (dictionary["title"] as? String)!,
                                      locationName: (dictionary["locationName"] as? String)!,
                                      username: (dictionary["username"] as? String)!,
                                      coordinate: CLLocationCoordinate2D(latitude: pinLat, longitude: pinLong),
                                      isDisabled: messageDisabled
                )
                
                pinMessage = message

                // if the message is not disabled, show the message as an annotation
                if !message.isDisabled
                {
                    self.mapView.addAnnotation(message)
                }
            }
        })
    }
    
    
//    let london = Capital(title: "London", coordinate: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), info: "Home to the 2012 Summer Olympics.")
//    let oslo = Capital(title: "Oslo", coordinate: CLLocationCoordinate2D(latitude: 59.95, longitude: 10.75), info: "Founded over a thousand years ago.")
//    let paris = Capital(title: "Paris", coordinate: CLLocationCoordinate2D(latitude: 48.8567, longitude: 2.3508), info: "Often called the City of Light.")
//    let rome = Capital(title: "Rome", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: 12.5), info: "Has a whole country inside it.")
//    let washington = Capital(title: "Washington DC", coordinate: CLLocationCoordinate2D(latitude: 38.895111, longitude: -77.036667), info: "Named after George himself.")

    
    
    let regionRadius: CLLocationDistance = 1000
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    // MARK: - location manager to authorize user location for Maps app
    var locationManager = CLLocationManager()
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    


}

