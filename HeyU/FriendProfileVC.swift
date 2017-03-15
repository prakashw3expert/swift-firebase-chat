//
//  FriendProfileVC.swift
//  HeyU
//
//  Created by Bekground on 01/02/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class FriendProfileVC: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var tblUserInfo: UITableView!
    var user_id : String?
    var userInfo = [String : AnyObject]()
    var image = UIImage()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tblUserInfo.register(UINib(nibName: "FriendProfileCell", bundle: nil), forCellReuseIdentifier: "profilecell")
        tblUserInfo.addParallax(with: self.image, andHeight: 200)
        self.getUser()

       

    }

    func getImage() {
        if let userPhoto = userInfo["userPhoto"] as! String? {
            let url = URL(string: userPhoto)
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!)
                DispatchQueue.main.async {
                    self.tblUserInfo.addParallax(with: UIImage(data: data!), andHeight: 200)
                }
            }
        }
    }

    func getUser() {
        
       let userref = FIRDatabase.database().reference().child("users").child(self.user_id!)
        
        userref.observe(.value, with: { (snapshot) in
            
            print(snapshot)
            
            guard let userdict = snapshot.value as? [String: AnyObject] else {
                
                return
                
            }
            self.lblTitle.text = userdict["name"] as? String
            self.userInfo = userdict
            
            
            DispatchQueue.main.async {
                // self.getImage()
                self.tblUserInfo.reloadData()
                
                
            }
            
        }, withCancel: nil)
        
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "profilecell", for: indexPath) as! FriendProfileCell
        
        cell.selectionStyle = .none
        
        if indexPath.row == 0 {
            
            cell.lblHeading.text = "Mobile"
            cell.lblValue.text = userInfo["mobile"] as? String
            
        }
        else if indexPath.row == 1 {
            cell.lblHeading.text = "Email"
            cell.lblValue.text = userInfo["email"] as? String
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    @IBAction func backAction(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
}
