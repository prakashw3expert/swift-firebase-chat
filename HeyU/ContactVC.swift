//
//  ContactVC.swift
//  HeyU
//
//  Created by Bekground on 25/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Contacts
import Firebase

class ContactVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var btnMore: UIButton!
    @IBOutlet var btnEdit: UIButton!
    @IBOutlet var tblContacts: UITableView!
    var localPhoneList = [[String : String]]()
    var FirebasePhoneList = [[String : String]]()
    var finalcontact = [[String: String]]()
    var user_id : String?
    var fromInbox : Bool?
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tblContacts.register(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contactcell")
        self.user_id = FIRAuth.auth()?.currentUser?.uid
        
        if fromInbox! {
            
            btnMore.isHidden = true
            btnEdit.setTitle("Back", for: .normal)
            
        }else{
            btnMore.isHidden = false
            btnEdit.isHidden = false
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        localPhoneList.removeAll()
        FirebasePhoneList.removeAll()
        
      //  if #available(iOS 9.0, *) {
          //  self.getContactsFromPhone()
            self.getContactsFromFirebase()
      //  } else {
            // Fallback on earlier versions
       // }

    }
    
    
    func getContactsFromPhone() {
        
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: {
            granted, error in
            
            guard granted else {
                let alert = UIAlertController(title: "Can't access contact", message: "Please go to Settings -> HeyU to enable contact permission", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey] as [Any]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
            var cnContacts = [CNContact]()
            
            do {
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    cnContacts.append(contact)
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }
            
          //  NSLog(">>>> Contact list: %@", cnContacts);
            for contact in cnContacts {
                let fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? "No Name"
                
                for ContctNumVar: CNLabeledValue in contact.phoneNumbers
                {
                    let MobNumVar  = (ContctNumVar.value).value(forKey: "digits") as? String
                   // NSLog("\(fullName): \(MobNumVar!)")
                    let originalmobilenumber = MobNumVar?.substring(from: (MobNumVar?.index((MobNumVar?.endIndex)!, offsetBy: -10))!)
                    self.localPhoneList.append(["name": fullName, "mobile": originalmobilenumber!])
                    
                    
                }
                
                
            }
            
           // print("The contact fetched : \n\n\n \(self.localPhoneList)")
        })
        
        
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
                
                self.FirebasePhoneList.sort(by: { (contact1, contact2) -> Bool in
                    
                    return (contact1["name"] )! < (contact2["name"])!
                    
                })
                
                
            DispatchQueue.main.async {
                
                print("Firebase contact list : \n\n \(self.FirebasePhoneList)")
                
               // self.getCommonContacts()
                self.tblContacts.reloadData()
                
                
            }
            }
        }, withCancel: nil)
        
        
    }
    
    func getCommonContacts() {
        
            for local in localPhoneList {
                for server in FirebasePhoneList {
                
                if(local["mobile"] == server["mobile"]) {
                    
                    if(!self.finalcontact.contains(where:{ $0 == ["name": local["name"]!, "mobile": server["mobile"]!, "status": server["status"]!]})) {
                        self.finalcontact.append(["name": local["name"]!, "mobile": server["mobile"]!, "status": server["status"]!])
                        print("contact found")
                    }
                    
                }
                
            }
            
        }
        self.tblContacts.reloadData()
       
    
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.FirebasePhoneList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dict = self.FirebasePhoneList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactcell", for: indexPath) as! ContactCell
        
        cell.selectionStyle = .none
        cell.friendName.text = dict["name"]
        cell.friendStatus.text = dict["status"]
        
        if let url = dict["userPhoto"] {
            cell.friendImage.sd_setImage(with: URL(string: url))
            
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //if !fromInbox! {
        
        let dict = self.FirebasePhoneList[indexPath.row]
        
        let page = ChatVC(nibName: "ChatVC", bundle: nil)
        
        page.user_id = dict["user_id"]
        page.usernamegot = dict["name"]
        page.isFriend = true
        
        self.navigationController?.pushViewController(page, animated: true)
        
        
        
//        cell.selectionStyle = .none
//        cell.friendName.text = dict["name"]
//        cell.friendStatus.text = dict["status"]
            
//        }else{
//            
//           
//                
//                let dict = self.FirebasePhoneList[indexPath.row]
//                let page = ChatVC(nibName: "ChatVC", bundle: nil)
//                
//                page.user_id = dict["user_id"]
//                page.usernamegot = dict["name"]
//                page.isFriend = true
//                self.navigationController?.pushViewController(page, animated: true)
//        
//            
//        }
        
    }

    @IBAction func editButtonTapped(_ sender: UIButton?) {
        
        if sender?.currentTitle == "Back" {
            
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        
    }
    
}
