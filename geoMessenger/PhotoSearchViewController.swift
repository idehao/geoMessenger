//
//  PhotoSearchViewController.swift
//  geoMessenger
//
//  Created by Ivor D. Addo on 4/3/17.
//  Copyright © 2017 deHao. All rights reserved.
//

import UIKit
import Firebase
import AlamofireImage
import VisualRecognitionV3

class PhotoSearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let apiKey = "d3f64203ddc20d0841b1310d02376d9684aa8668" // plug-in your apiKey from Watson here
    let version = "2017-04-05" // plug-in today’s date here
    let watsonCollectionName = "PhotoCollection" // watson collection id
    var watsonCollectionId = "PhotoCollection" // watson collection id
    
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var ref: FIRDatabaseReference!
    var existingImageUrls: [ImageUrlItem] = []
    var similarImageUrls: [ImageUrlItem] = []
    var newPhotoRecognitionURL: URL!
    var visualRecognition: VisualRecognition!
    
    @IBAction func btnSearch_Tap(_ sender: UIButton) {
     
        self.activityIndicator.isHidden = false // show activity indicator
        self.activityIndicator.startAnimating()
        self.btnSearch.isHidden = true // hide the upload button
        
        // MARK: Show an ActionSheet for picking the Photo or using the Camera
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
        //#1
        let pickPhotoAction = UIAlertAction(title: "Pick from the Gallery", style: .default) { (alert: UIAlertAction!) in
            // STEP 1: MARK - pick the image
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            {
                let imgPicker = UIImagePickerController()
                imgPicker.delegate = self
                imgPicker.sourceType = .photoLibrary
                imgPicker.allowsEditing = false
                // show the photoLibrary
                self.present(imgPicker, animated: true, completion: nil)
            }
            self.showButton()
        }
        
        //#2
        let takePhotoAction = UIAlertAction(title: "Take a Photo", style: .default) { (alert: UIAlertAction!) in
            if UIImagePickerController.isSourceTypeAvailable(.camera)
            {
                let imgPicker = UIImagePickerController()
                imgPicker.delegate = self
                imgPicker.sourceType = .camera
                imgPicker.allowsEditing = false
                // show the camera App
                self.present(imgPicker, animated: true, completion: nil)
            }
            self.showButton()
        }
        
        //#3 - use a cancel style with no action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) in
            // cancelled, show button and hide activity icon
            self.showButton()
        }
        
        //#4
        optionMenu.addAction(pickPhotoAction)
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        
        
    }
    
    func showButton()
    {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true // hide activity indicator
            self.activityIndicator.stopAnimating()
            self.btnSearch.isHidden = false // hide the upload button
        }
    }
    
    func hideButton()
    {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false // hide activity indicator
            self.activityIndicator.startAnimating()
            self.btnSearch.isHidden = true // hide the upload button
        }
    }
    
    
    // 2: create an instance variable
    var storageRef: FIRStorageReference!
    
    // 3: create a function for saving content to Firebase storage
    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    //
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgPhoto.image = selectedImage
        } else {
            print("Something went wrong")
        }
        
        dismiss(animated:true, completion: nil)
        
       
        
        performSearch()
        
       
    }
    
    func performSearch()
    {
         self.hideButton()
        
        // STEP 2: MARK - save the test image
        let imageData = UIImageJPEGRepresentation(imgPhoto.image!, 0.8) // compression quality
        let compressedJPEGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(compressedJPEGImage!, nil, nil, nil)
        
        // save to Firebase Storage
        let guid =  "search_image" // substitute with the current user's ID
        
        let imagePath = "\(guid)/\(guid).jpg"
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.storageRef.child(imagePath)
            .put(imageData!, metadata: metadata) {  (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
                
                // STEP 2b: Get the image URL
                // limit the size of uploaded images to < 2MB
                self.newPhotoRecognitionURL = URL(string: (metadata?.downloadURL()?.absoluteString)!)!
                
                
                // STEP 3: MARK - get a list of previous imageUrls from Firebase
                // Ideally, this will be a batch submission but the MCS SDK doesn't support it yet
                
                self.ref = FIRDatabase.database().reference()
                
                // get only the latest 15 photos for now
                self.ref.child("Photos").queryLimited(toLast: 4)
                    .observe(.value, with: { snapshot in
                    
                    // loop through the children and append them to the new array
                    for dbItem in snapshot.children.allObjects {
                        let gItem = (snapshot: dbItem )
                        
                        // convert the snapshot JSON value to your Struct type
                        let newValue = ImageUrlItem(snapshot: gItem as! FIRDataSnapshot)
                        self.existingImageUrls.append(newValue)
                    }
                        
                    // STEP 4: MARK make call to API with
                    //searchImageUrl and existingImageUrls
                    
                    // MARK - CALL IBM Watson here
                    self.visualRecognition = VisualRecognition(apiKey: self.apiKey, version: self.version)
                    

                    // MARK - classify the curent Image
                    self.classifyImage()
                    
                    
                    // MARK - create a collection
                   self.createCollection()
                    
                    // MARK - Add images to the Watson collection
                    for existingImageUrlItem in self.existingImageUrls {
                        
                        print(existingImageUrlItem.imageUrl)
                        self.addCurrentImageToCollection(imageURL: URL(string: existingImageUrlItem.imageUrl)!)
                    }

                    // MARK - Find Similar Images
                    self.findSimilarImages()
                    
                    // MARK - Eventually permanently store new photo reports to the collection and eliminate the programmatic createCollection and removeCollection calls
                   
                        
                        
                    // TODO:
                    print(self.similarImageUrls)

                    //self.showButton()
                    
                    self.collectionView.reloadData()
                })
        }
         self.showButton()

    }
    
    
    func createCollection()
    {
        // create a collection and
        self.visualRecognition.createCollection(withName: self.watsonCollectionName, success: { (collection) in
            
            self.watsonCollectionId = collection.collectionID
            print("Collection Created")
            print(self.watsonCollectionName)
            print(self.watsonCollectionId)
        })
    }
    
    func removeCollection()
    {
        // create a collection and
        self.visualRecognition.deleteCollection(withID: self.watsonCollectionId)
         print("Collection Removed")
    }
    
    func addCurrentImageToCollection(imageURL: URL)
    {
        // create a collection and
        self.visualRecognition.addImageToCollection(withID: self.watsonCollectionId, imageFile: imageURL) { (colImages) in
            // number of images
            print(colImages.collectionImages.count)
        }
    }
    
    
    func findSimilarImages()
    {
        print(newPhotoRecognitionURL! )
        print (self.watsonCollectionId)
        
        self.visualRecognition.findSimilarImages(toImageFile: newPhotoRecognitionURL!,
                                                 inCollectionID: self.watsonCollectionId,
                                                 limit: 9,
        failure: { (searchError) in
                                                    //
                                                    print(searchError)
            self.removeCollection()
        },
        success: { similarImageList in
        
        //self.visualRecognition.findSimilarImages(toImageFile: newPhotoRecognitionURL!, inCollectionID: self.watsonCollectionId, success: { similarImageList in
            //
            
            if let classifiedImage = similarImageList.similarImages.first
            {
                print(classifiedImage.score!)
                
                var counter = 1
                // loop through the children and append them to the new array
                for similarImageItem in similarImageList.similarImages {
                    
                    // only get top 9 similar images
                    //if counter < 9
                    //{
                        // convert the snapshot JSON value to your Struct type
                        let newValue = ImageUrlItem.init(imageUrl: similarImageItem.imageFile, key: String(counter))
                        self.similarImageUrls.append(newValue)
                        counter += 1
                    //}
                }
            }
            else
            {
                DispatchQueue.main.async {
                    // show alert of failure
                    let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
            self.removeCollection()
            
        })
        
        
    }
    
    func classifyImage()
    {
        // determine if IBM Watson call failed
        let failure = {(error:Error) in
            DispatchQueue.main.async {
                // show alert of failure
                let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
            
            // for troubleshooting only
            print(error)
        }
        
        // classify the image to show classified verbiage about the image
        self.visualRecognition.classify(image: (self.newPhotoRecognitionURL?.absoluteString)!, failure: failure){
            classifiedImages in
            
            if let classifiedImage = classifiedImages.images.first
            {
                print(classifiedImage.classifiers)
                
                if let results = classifiedImage.classifiers.first?.classes.first?.classification {
                    
                    DispatchQueue.main.async {
                        // success: show the results in the title bar
                        self.title = results
                        
                    }
                    
                }
            }
            else
            {
                DispatchQueue.main.async {
                    // show alert of failure
                    let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        activityIndicator.isHidden = true
        configureStorage()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set the number of items in your collection view - 9 max photos in this case
        return 9
    }
    
    
    //In order to access properties and methods in your Custom Cell Swift file, you will need to cast your cell to be of type, PhotoCell using as! PhotoCell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotoCell
        cell.backgroundColor = UIColor(red:0.96, green:0.97, blue:0.99, alpha:1.0)
        
        // Do any custom modifications you your cell, referencing the outlets you defined in the Custom cell file // if we have a label IBOutlet in PhotoCell we can customize it here
        //cell.label.text = "item \(indexPath.item)"
        
           // on page load when we have no search results, show nothing
           if similarImageUrls.count > 0 {
                let image = self.similarImageUrls[indexPath.row]
            
            // get image asynchronously via URL
            let url = URL(string: image.imageUrl)
            
            DispatchQueue.global().async {
                //let data = try? Data(contentsOf: url!)
                //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    cell.imgPhoto.af_setImage(withURL: url!) // change to this after alamofire is added
                    //cell.imgPhoto.image = UIImage(data: data!)
                }
            }

        }
        return cell
    }
    
}
