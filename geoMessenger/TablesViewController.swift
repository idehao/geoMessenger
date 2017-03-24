//
//  TablesViewController.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 3/23/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit
import Firebase

class TablesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var txtLastname: UITextField!

    @IBOutlet weak var txtFirstname: UITextField!
    
    @IBAction func btnAddUser(_ sender: CustomButton) {
        
        var ref: FIRDatabaseReference!
        
        ref = FIRDatabase.database().reference()
        
        let userTable : [String : Any] =
            ["FirstName": txtFirstname.text!,
             "LastName": txtLastname.text!,
             "IsApproved": false]
        
        // add to the Firebase JSON node for MyUsers
        ref.child("MyUsers").childByAutoId().setValue(userTable)
        
        // show confirmation alert
        let ac = UIAlertController(title: "User Saved!", message:"The user information  was saved successfully!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        
        // reset controls
        txtLastname.text = nil
        txtFirstname.text = nil
    }
}
