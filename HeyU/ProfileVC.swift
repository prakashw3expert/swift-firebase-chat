//
//  ProfileVC.swift
//  HeyU
//
//  Created by Bekground on 25/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class ProfileVC: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet var userImage: UIImageView!
    @IBOutlet var username: UILabel!
    
    @IBOutlet var userStatus: UILabel!
    
    @IBOutlet var userEmail: UILabel!
    
    @IBOutlet var userMobile: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.getUserData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func getUserData() {
        
        let user_id = FIRAuth.auth()?.currentUser?.uid
        
        let ref = FIRDatabase.database().reference().child("users").child(user_id!)
        ref.observe(.value, with: { (snapshot) in
            
            print("snap shot value is : \n\n\n \(snapshot.value)")
            let userDict = snapshot.value as! [String : AnyObject]
            
            self.username.text = userDict["name"] as! String?
            self.userStatus.text = userDict["status"] as! String?
            self.userEmail.text = userDict["email"] as! String?
            self.userMobile.text = userDict["mobile"] as! String?
            if let url = userDict["userPhoto"] as! String? {
                
                self.userImage.sd_setImage(with: URL(string: url))
            }
            
        }, withCancel: nil)
        
    }
    
    func setupView() {
        
        
        self.userImage.layer.borderWidth = 1
        self.userImage.layer.borderColor = UIColor.white.cgColor
        self.userImage.layer.cornerRadius = 50
        self.userImage.clipsToBounds = true
        
    }
    @IBAction func logoutTapped(_ sender: Any) {
    }
    @IBAction func editTapped(_ sender: UIButton) {
    }
    @IBAction func deleteAccountTapped(_ sender: UIButton) {
    }
    @IBAction func imageTapped(_ sender: Any) {
        
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            print("Camera clicked")
            self.imageFromCamera()
       
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            print("Gallery clicked")
            
            self.imageFromGallery()
            
        }))
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)

        
        
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary contains multiple representations of the image, and this uses the original.
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        //userImage.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: {
            
            print("Upload image now")
            var data: Data = Data()
            
            data = UIImageJPEGRepresentation(selectedImage, 0.1)!
            let filePath = "\(FIRAuth.auth()!.currentUser!.uid)/\("userPhoto")"
            let storageRef = FIRStorage.storage().reference()
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
    
            storageRef.child(filePath).put(data, metadata: metadata){(metadata,error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }else{
                    //store downloadURL
                    let downloadURL = metadata!.downloadURL()!.absoluteString
                    //store downloadURL at database
                  
                    let databaseRef = FIRDatabase.database().reference()
                databaseRef.child("users").child(FIRAuth.auth()!.currentUser!.uid).updateChildValues(["userPhoto": downloadURL])
                    
                    self.userImage.image = selectedImage
                }
                
            }
            
        })
    }

    func imageFromGallery() {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = .photoLibrary
        
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func imageFromCamera() {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = .camera
        
        
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }

}
