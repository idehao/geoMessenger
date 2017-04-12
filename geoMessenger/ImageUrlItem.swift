//
//  ImageUrlItem.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 4/3/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import Foundation
import Firebase

struct ImageUrlItem {
    
    let key: String
    let imageUrl: String
    let ref: FIRDatabaseReference?
    
    init(imageUrl: String, key: String = "") {
        self.key = key
        self.imageUrl = imageUrl
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        imageUrl = snapshotValue["ImageUrl"] as! String // must map to firebase names
        ref = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "imageUrl": imageUrl
        ]
    }
    
}
