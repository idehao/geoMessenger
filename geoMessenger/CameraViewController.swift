//
//  CameraViewController.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 3/5/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit
import Firebase // 1: add library

class CameraViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{

    @IBOutlet weak var imgPhoto: UIImageView!
    
    
    // 2: create an instance variable
    var storageRef: FIRStorageReference!

    // 3: create a function for saving content to Firebase storage
    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureStorage() // 4: reference the storage functtion
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imgPhoto.image = selectedImage
        } else {
            print("Something went wrong")
        }
        
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    
    // create function for creating an alert when save is sucessful
    func savePhotoAlert(){
        let ac = UIAlertController(title: "Photo Saved!", message:"Your photo was saved successfully", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    
    }
    
    @IBAction func btnSavePhoto_Tap(_ sender: UIBarButtonItem) {
        // get the image in the imageView and save it to the Photo Album
        let imageData = UIImageJPEGRepresentation(imgPhoto.image!, 0.8) // compression quality
        let compressedJPEGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(compressedJPEGImage!, nil, nil, nil)
        
        // save to Firebase Storage
        //let guid =  "test_id" // substitute with the current user's ID

        let guid = UUID().uuidString // STEP 1: Generate new UUID

        
        let imagePath = "\(guid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.storageRef.child(imagePath)
            .put(imageData!, metadata: metadata) {  (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
                
                // STEP 2b: Get the image URL
                let imageUrl = metadata?.downloadURL()?.absoluteString
                
                // STEP 3: Add code to save the imageURL to the Realtime database
                var ref: FIRDatabaseReference!
                ref = FIRDatabase.database().reference()
                
                let imageNode : [String : String] = ["ImageUrl": imageUrl!]
                
                // add to the Firebase JSON node for MyUsers
                ref.child("Photos").childByAutoId().setValue(imageNode) /**/
                
                // call the function to show the alert
                self.savePhotoAlert()
        }
    }

    @IBAction func btnTakePhoto_TouchUpInside(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            let imgPicker = UIImagePickerController()
            imgPicker.delegate = self
            imgPicker.sourceType = .camera
            imgPicker.allowsEditing = false
            // show the camera App
            self.present(imgPicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnPickPhoto_TouchUpInside(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        {
            let imgPicker = UIImagePickerController()
            imgPicker.delegate = self
            imgPicker.sourceType = .photoLibrary
            imgPicker.allowsEditing = true // allow users to crop , etc.
            // show the photoLibrary
            self.present(imgPicker, animated: true, completion: nil)
        }
    }

}
