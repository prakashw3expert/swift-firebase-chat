//
//  GroupVC.swift
//  HeyU
//
//  Created by Bekground on 25/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class GroupVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tblGroups: UITableView!
    var user_id : String?
    var Groups = [String]()
    
    var groupsInfo = [[String : AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tblGroups.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: "groupcell")
        user_id = FIRAuth.auth()?.currentUser?.uid
        
        
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getAllGroups()
    }
    
    

    func getAllGroups() {
        
        let groupRef = FIRDatabase.database().reference().child("users").child(self.user_id!).child("groups")
        
        groupRef.observe(.value, with: { (snapshot) in
            
           if let dict = snapshot.value as? [String : AnyObject] {
            
            self.Groups.removeAll()
            for key in dict {
                
                self.Groups.append(key.key)
                
            }
                
            }

            DispatchQueue.main.async {
                
                self.GetGroupInfo()
                
                
                
            }
            
        }, withCancel: nil)
        
    }
    
    func GetGroupInfo() {
        
        let ref = FIRDatabase.database().reference().child("groups")
        
        self.groupsInfo.removeAll()
        for group in Groups {
            
            ref.child(group).observe(.value, with: { (snapshot) in
                
              //  print(snapshot.value!)
                
                
                if var dict = snapshot.value as? [String : AnyObject] {
                    
                    dict["group_id"] = snapshot.key as AnyObject?
                    self.groupsInfo.append(dict)
                    
                    /// sorting group based on name
                    
                    self.groupsInfo.sort(by: { (group1, group2) -> Bool in
                        
                        return (group1["groupname"] as! String) < (group2["groupname"] as! String)
                        
                    })
                    
                 
                }
                
                DispatchQueue.main.async {
                    self.reloadTable()
                }
                
            }, withCancel: nil)
        }
        
        
        
    }
    
    func reloadTable() {
        
//        print(self.groupsInfo)
//        print(self.groupsInfo.count)
        
        self.tblGroups.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let dict = self.groupsInfo[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupcell", for: indexPath) as! GroupCell
        cell.selectionStyle = .none
        cell.groupName.text = dict["groupname"] as! String?
        cell.createDate.text = "Created on : \(dict["createdate"] as! String)"
        cell.totalMembers.text = "Total Members : \(Int((dict["groupmembers"]?.count)!))"
        
        if let groupPhoto = dict["groupPhoto"] as! String? {
            cell.groupImage.setShowActivityIndicator(true)
            cell.groupImage.setIndicatorStyle(.gray)
            
            cell.groupImage.sd_setImage(with: URL(string: groupPhoto), placeholderImage: UIImage(named: "image.png"), options:.refreshCached)
        }
        else{
            cell.groupImage.image = UIImage(named: "image.png")
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let Group = groupsInfo[indexPath.row]
        
        let page = ChatVC(nibName: "ChatVC", bundle: nil)
        page.user_id = Group["group_id"] as! String?
        page.groupInfo = Group
        page.isFriend = false
        self.navigationController?.pushViewController(page, animated: true)
        
        
    }
    
    @IBAction func editAction(_ sender: Any) {
    }

    @IBAction func addBtnAction(_ sender: Any) {
        
        let page = AddNewGroupVC(nibName: "AddNewGroupVC", bundle: nil)
        page.isNewGroup = true
        self.navigationController?.pushViewController(page, animated: true)
        
    }
}
