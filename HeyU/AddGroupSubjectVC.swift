//
//  AddGroupSubjectVC.swift
//  HeyU
//
//  Created by Bekground on 31/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class AddGroupSubjectVC: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var memberCollectionView: UICollectionView!
    @IBOutlet var groupImage: UIImageView!
    @IBOutlet var txtGroupSubject: UITextField!
    @IBOutlet var btnCreate: UIButton!
    var user_id : String?
    var selectedMembers = [[String : String]]()
    var membersKeys = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        memberCollectionView.register(UINib(nibName: "MemberCollectionCell", bundle: nil), forCellWithReuseIdentifier: "membercollection")

        user_id = FIRAuth.auth()?.currentUser?.uid
        let gesture = UITapGestureRecognizer(target: self, action: #selector(PicImageFromLibrary))
        groupImage.addGestureRecognizer(gesture)
        groupImage.isUserInteractionEnabled = true
        
        groupImage.layer.cornerRadius = 75/2
        groupImage.clipsToBounds = true
        
        btnCreate.layer.cornerRadius = 25
        btnCreate.clipsToBounds = true
        
        self.getMembersKeys()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dict = self.selectedMembers[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "membercollection", for: indexPath) as! MemberCollectionCell
        
        if let memberPhoto = dict["userPhoto"] {
            
            cell.memberImage.sd_setImage(with: URL(string: memberPhoto))
        }
        else{
            cell.memberImage.image = UIImage(named: "avatar.png")
        }
        return cell
    }

    func getMembersKeys() {
        
        for member in self.selectedMembers {
            
            membersKeys.append(member["user_id"]!)
            
        }
        membersKeys.append(self.user_id!)
        
    }
    
    func PicImageFromLibrary() {
        
        let piker = UIImagePickerController()
        
        piker.delegate = self
        piker.sourceType = .photoLibrary
        
        present(piker, animated: true, completion: nil)
        
        
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            groupImage.image = image
            groupImage.contentMode = .scaleAspectFit
            
        }
        picker.dismiss(animated: true, completion: nil)
        
        
        
        
    }

    @IBAction func btnCreateAction(_ sender: Any) {
        
        if txtGroupSubject.text == "" {
            txtGroupSubject.becomeFirstResponder()
            return
        }
        
        let ref = FIRDatabase.database().reference().child("groups")
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let currentDate = formatter.string(from: date)
        
        let values = ["groupname" : txtGroupSubject.text!,"owner" : self.user_id! , "createdate" : currentDate];
         //"groupmembers" : self.membersKeys
        let groupRef = ref.childByAutoId()
        groupRef.updateChildValues(values)
        
        let memberRef = FIRDatabase.database().reference().child("groups").child(groupRef.key).child("groupmembers")
        
        for key in self.membersKeys {
            
            memberRef.updateChildValues([key : NSNumber(booleanLiteral: true)])
        }
        
        /////
        print("Upload image now")
        var data: Data = Data()
        
        
        if let selectedImage = self.groupImage.image {
        data = UIImageJPEGRepresentation(selectedImage, 0.1)!
        let filePath = "\(groupRef.key)/\("groupPhoto")"
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
                databaseRef.child("groups").child(groupRef.key).updateChildValues(["groupPhoto": downloadURL])
                
                
            }
            
        }
        }
        ////
        
        for key in self.membersKeys {
            
            let userRef = FIRDatabase.database().reference().child("users")
            
            userRef.child(key).child("groups").updateChildValues([groupRef.key : NSNumber(booleanLiteral: true)])
            
        }
        
        let alert = UIAlertController(title: "Success", message:"Group Created", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (_) -> Void in
            print("Ok clicked")
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.tabBarController.selectedIndex = 1
            appDelegate.goToTabBar()
            
            
            
        }))

        self.present(alert, animated: true, completion: nil)
//        let page = GroupVC(nibName: "GroupVC", bundle: nil)
//        
//        self.navigationController?.pushViewController(page, animated: true)
        
    }

    @IBAction func backAction(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
        
    }

}
