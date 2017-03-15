//
//  GroupInfoVC.swift
//  HeyU
//
//  Created by Bekground on 01/02/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase


class GroupInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource,UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var backGroundView: UIView!
    @IBOutlet var popUpView: UIView!
    @IBOutlet var lblnamewidth: NSLayoutConstraint!
    @IBOutlet var groupTitle: UILabel!
    @IBOutlet var tblGroupMember: UITableView!
    var MembersInfo = [[String : AnyObject]]()
    var groupInfo = [String : AnyObject]()
    var Members = [String]()
    var image = UIImage()
    var user_id : String?
    override func viewDidLoad() {
        super.viewDidLoad()

        tblGroupMember.register(UINib(nibName: "GroupInfoCell", bundle: nil), forCellReuseIdentifier: "groupinfocell")
        self.popUpView.alpha = 0
        self.popUpView.layer.cornerRadius = 5
        self.popUpView.clipsToBounds = true
        self.setupView()
       
        self.popUpView.tag = 99
        
        tblGroupMember.addParallax(with: self.image, andHeight: 180)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        

        UIView.animate(withDuration: 0.3, animations: {
            self.backGroundView.isHidden = true
            self.popUpView.frame = CGRect(x: 300, y: 26, width: 0, height: 0)
            self.popUpView.alpha = 0
        }, completion: nil)
        
        
    }
    func setupView() {
        let whichfont = UIFont(name: "Helvetica", size: 16)
        let myString: NSString = self.groupInfo["groupname"] as! NSString
        let size: CGSize = myString.size(attributes: [NSFontAttributeName: whichfont ?? UIFont.systemFont(ofSize: 16)])
        
        let width = size.width + 5
        
        if(width < 180) {
            self.lblnamewidth.constant = width
        }else{
            self.lblnamewidth.constant = 180
        }
        
        self.groupTitle.text = myString as String
//        Members = groupInfo["groupmembers"] as! Array
//        print(Members)
        
        if let tempDict = groupInfo["groupmembers"] {
            
            for (key,_) in tempDict as! [String : Bool] {
                
                Members.append(key)
            }
            
        }
        
        GetMembersInfo()
        
    }
    
    
    func setImage() {
        if let groupPhoto = groupInfo["groupPhoto"] as! String? {
        let url = URL(string: groupPhoto) 
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!)
            DispatchQueue.main.async {
                self.tblGroupMember.addParallax(with: UIImage(data: data!), andHeight: 180)
            }
        }
        }
    }
    
    func reloadTable() {
        
        print(self.MembersInfo)
//        print(self.MembersInfo.count)
        tblGroupMember.reloadData()
       // setImage()
        
    }
    func GetMembersInfo() {
        
        let ref = FIRDatabase.database().reference().child("users")
        
        self.MembersInfo.removeAll()
        for member in self.Members {
            
            ref.child(member).observe(.value, with: { (snapshot) in
                
                //  print(snapshot.value!)
                
                
                if let dict = snapshot.value as? [String : AnyObject] {
                    
                   // dict["member_id"] = snapshot.key as AnyObject?
                    self.MembersInfo.append(dict)
                    
                    /// sorting group based on name
                    
                    self.MembersInfo.sort(by: { (member1, member2) -> Bool in
                        
                        return (member1["name"] as! String) < (member2["name"] as! String)
                        
                    })
                    
                    
                }
                
                DispatchQueue.main.async {
                    self.reloadTable()
                }
                
            }, withCancel: nil)
        }
        
        
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.MembersInfo.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dict = self.MembersInfo[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupinfocell", for: indexPath) as! GroupInfoCell
        
        cell.friendName.text = dict["name"] as? String
        cell.friendStatus.text = dict["status"] as? String
        
        if let userPhoto = dict["userPhoto"] as? String {
            
            cell.friendImage.sd_setImage(with: URL(string: userPhoto))
            
        }
        else{
            cell.friendImage.image = UIImage(named: "avatar.png")
        }
        return cell
        
    }
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    @IBAction func btnMoreAction(_ sender: Any) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.backGroundView.isHidden = false
            self.popUpView.alpha = 1
            self.popUpView.frame = CGRect(x: 153, y: 26, width: 160, height: 93)
            
            }, completion: nil)
        
        
    }
    
    func PicImageFromLibrary() {
        
        let piker = UIImagePickerController()
        
        piker.delegate = self
        piker.sourceType = .photoLibrary
        
        present(piker, animated: true, completion: nil)
        
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            print("Upload image now")
            var data: Data = Data()
            data = UIImageJPEGRepresentation(image, 0.1)!
            
            let filePath = "\(self.user_id!)/\("groupPhoto")"
            let storageRef = FIRStorage.storage().reference()
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.child(filePath).put(data, metadata: metadata){(metadata,error) in
                if let error = error {
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Failed", message:"Unable to Upload image of group", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (_) -> Void in

                        return
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                    
                }else{
                    //store downloadURL
                    let downloadURL = metadata!.downloadURL()!.absoluteString
                    //store downloadURL at database
                    
                    let databaseRef = FIRDatabase.database().reference()
                    databaseRef.child("groups").child(self.user_id!).updateChildValues(["groupPhoto" : downloadURL])
                    
                    self.tblGroupMember.addParallax(with: image, andHeight: 180)
                    
                }
                
            }

//            groupImage.image = image
//            groupImage.contentMode = .scaleAspectFit
            
        }
        picker.dismiss(animated: true, completion: nil)
        
        
        
        
    }

   
    @IBAction func changeIconTapped(_ sender: Any) {
        
        self.popUpView.alpha = 0
        self.backGroundView.isHidden = true
        self.PicImageFromLibrary()
        
    }

    @IBAction func addMemberTapped(_ sender: Any) {
        
        let page = AddNewGroupVC(nibName: "AddNewGroupVC", bundle: nil)
        page.isNewGroup = false
        page.existingMembers = self.Members
        page.groupId = self.user_id
        self.present(page, animated: true, completion: nil)
    }
    
    @IBAction func exitGrouptapped(_ sender: Any) {
    }
    
}
