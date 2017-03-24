//
//  Message.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 2/26/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit
import MapKit

class Message: NSObject, MKAnnotation {

    let title: String?
    let locationName: String
    let username: String
    let coordinate: CLLocationCoordinate2D
    let isDisabled: Bool
    
    init(title: String, locationName: String, username: String, coordinate: CLLocationCoordinate2D, isDisabled: Bool) {
        self.title = title
        self.locationName = locationName
        self.username = username
        self.coordinate = coordinate
        self.isDisabled = isDisabled
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
    
}
