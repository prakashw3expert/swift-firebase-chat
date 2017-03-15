//
//  AddNewGroupVC.swift
//  HeyU
//
//  Created by Bekground on 30/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class AddNewGroupVC: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tblContactList: UITableView!
    @IBOutlet var btnCreate: UIButton!
    
    var selectedMembers = [[String : String]]()
    var selectedIndex : Int?
    var FirebasePhoneList = [[String : String]]()
    var user_id : String?
    var isNewGroup : Bool?
    var existingMembers = [String]()
    var groupId : String?
    var membersKeys = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblContactList.register(UINib(nibName: "AddGroupCell", bundle: nil), forCellReuseIdentifier: "addgroupcell")
        self.tblContactList.allowsMultipleSelection = true

     
        self.user_id = FIRAuth.auth()?.currentUser?.uid

        if isNewGroup! {
            btnCreate.setTitle("Create", for: .normal)
           self.getContactsFromFirebase()
        }
        else{
            btnCreate.setTitle("Add", for: .normal)
            self.findNewMembers()
        }
        
    }
    func findNewMembers() {
        
        let ref = FIRDatabase.database().reference().child("users")
        
        ref.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key != self.user_id && !self.existingMembers.contains(snapshot.key) {
                
                guard let dictionary = snapshot.value as? [String :  AnyObject] else {
                    return
                }
                
                        let name = dictionary["name"] as! String
                        let mobileno = dictionary["mobile"] as! String
                        let status = dictionary["status"] as! String
                        
                        if let userPhoto = dictionary["userPhoto"] as? String {
                            
                            self.FirebasePhoneList.append(["name" : name, "mobile": mobileno, "status": status,"user_id" : snapshot.key, "userPhoto" : userPhoto])
                            
                        }
                        else{
                            self.FirebasePhoneList.append(["name" : name, "mobile": mobileno, "status": status,"user_id" : snapshot.key])
                        }

                
                
                
                
                DispatchQueue.main.async {
                    
                    print("Firebase contact list : \n\n \(self.FirebasePhoneList)")
                    
                    // self.getCommonContacts()
                    self.tblContactList.reloadData()
                    
                    
                }
            }
        }, withCancel: nil)

        
    }
    func getContactsFromFirebase() {
        
        let ref = FIRDatabase.database().reference().child("users")
        
        ref.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key != self.user_id {
                
                guard let dictionary = snapshot.value as? [String :  AnyObject] else {
                    return
                }
                
                //            print("user found : \n\n \(dictionary)")
                //            print(dictionary["mobile"] as! String)
                //            print(dictionary["name"] as! String)
                
                let name = dictionary["name"] as! String
                let mobileno = dictionary["mobile"] as! String
                let status = dictionary["status"] as! String
                
                if let userPhoto = dictionary["userPhoto"] as? String {
                    
                    self.FirebasePhoneList.append(["name" : name, "mobile": mobileno, "status": status,"user_id" : snapshot.key, "userPhoto" : userPhoto])
                    
                }
                else{
                    self.FirebasePhoneList.append(["name" : name, "mobile": mobileno, "status": status,"user_id" : snapshot.key])
                }
                
                
                DispatchQueue.main.async {
                    
                    print("Firebase contact list : \n\n \(self.FirebasePhoneList)")
                    
                    // self.getCommonContacts()
                    self.tblContactList.reloadData()
                    
                    
                }
            }
        }, withCancel: nil)

        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dict = self.FirebasePhoneList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "addgroupcell", for: indexPath) as! AddGroupCell
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none
        cell.friendName.text = dict["name"]
        cell.friendStatus.text = dict["status"]
        
        if let userPhoto = dict["userPhoto"] {
            
            cell.friendImage.sd_setImage(with: URL(string: userPhoto))
            
        }
        else{
            cell.friendImage.image = UIImage(named: "avatar.png")
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.FirebasePhoneList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        selectedMembers.append(self.FirebasePhoneList[indexPath.row])
        print(self.selectedMembers.count)
        
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        
       // selectedMembers.remove(at: indexPath.row)
        selectedMembers = selectedMembers.filter() { $0 != self.FirebasePhoneList[indexPath.row]}
        print(self.selectedMembers.count)
        
    }
    
    @IBAction func craeteBtnAction(_ sender: UIButton) {
        
        if sender.currentTitle == "Create" {
        
        if self.selectedMembers.count > 0 {
            
            let page = AddGroupSubjectVC(nibName: "AddGroupSubjectVC", bundle: nil)
            
            page.selectedMembers = self.selectedMembers
            self.navigationController?.pushViewController(page, animated: true)
            
        }
        else{
            print("Select Atleast one Participiant")
        }
        }
        else{
            
            if self.selectedMembers.count > 0 {
                
                print("Member Added function call here")
                for member in self.selectedMembers {
                    
                    membersKeys.append(member["user_id"]!)
                    
                }
                membersKeys.append(self.user_id!)
                
                let reference = FIRDatabase.database().reference().child("groups").child(self.groupId!).child("groupmembers")
                
                
                for key in self.membersKeys {
                    
                    let userRef = FIRDatabase.database().reference().child("users")
                    
                    reference.updateChildValues([key : NSNumber(booleanLiteral: true)])
                    
                    userRef.child(key).child("groups").updateChildValues([self.groupId! : NSNumber(booleanLiteral: true)])
                    
                }
                
                let alert = UIAlertController(title: "Success", message:"Member Added", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (_) -> Void in
                    print("Ok clicked")
                    
                    self.dismiss(animated: true, completion: nil)
                    
                }))

                
                
                
                
                
            }
            else{
                print("Select Atleast one Participiant")
            }

            
        }
        
    }
    

    @IBAction func cancelAction(_ sender: Any) {
        print(self.selectedMembers)
        print(self.selectedMembers.count)
        if isNewGroup! {
            self.navigationController?.popViewController(animated: true)
        }
        else{
            self.dismiss(animated: true, completion: nil)
        }
        
        
    }
}
