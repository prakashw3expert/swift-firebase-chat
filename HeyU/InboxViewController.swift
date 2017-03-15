//
//  InboxViewController.swift
//  HeyU
//
//  Created by Bekground on 24/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class InboxViewController: UIViewController , UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tblChat: UITableView!
    @IBOutlet var searchView: UIView!
    @IBOutlet var txtSearch: UITextField!
    
    var MessagesArr = [Message]()
    var profileImageUrl : String?
    var unreadArr = [Any]()
    var mainUnreadDict = [String : AnyObject]()
    var messageDictionary = [String : AnyObject]()
    var mainDict = [String : AnyObject]()
    
    var uid : String?
    var check : Bool = false
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        tblChat.register(UINib(nibName: "InboxVCCell", bundle: nil), forCellReuseIdentifier: "inboxcell")
//        MessagesArr.removeAll()
//        self.loadDataForView()
        
     //   NotificationCenter.default.addObserver(self, selector: #selector(observeMessages), name: NSNotification.Name(rawValue: "observe"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(observeMessages), name: NSNotification.Name(rawValue: "clearUnreadMessages"), object: nil)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        
        tblChat.register(UINib(nibName: "InboxVCCell", bundle: nil), forCellReuseIdentifier: "inboxcell")

       
        self.loadDataForView()
    }
    
    func loadDataForView(){
        
        uid = FIRAuth.auth()?.currentUser?.uid
      
        self.observeMessages()
       // self.getUnreadCount()
        
    }
    
    func getUnreadCount() {
        
        uid = FIRAuth.auth()?.currentUser?.uid
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid!)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            
            ref.child(userId).observe(.childAdded, with: { (snapshot) in
             
                if snapshot.key == "unread-message" {
                    
                    ref.child(userId).child("unread-message").observe(.childAdded, with: { (snap) in
                        
                        ref.child(userId).observe(.childAdded, with: { (snapshot) in
                            
                            if snapshot.key == "unread-message" {
                                
                                print("unread messages : \(snapshot.childrenCount)")
                                self.mainUnreadDict[userId] = Int(snapshot.childrenCount) as AnyObject?
                                
                            }
                            
                        }, withCancel: nil)
                        
                        self.unreadArr.append(self.mainUnreadDict)
                        
                    }, withCancel: nil)
                    
                    DispatchQueue.main.async {
                        print("Unread Array Finally : \(self.unreadArr)")
                        self.tblChat.reloadData()
                    }
                    
                }
                
            }, withCancel: nil)
            
            
        }, withCancel: nil)
        
    }
    
    func observeMessages() {
        
        uid = FIRAuth.auth()?.currentUser?.uid
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid!)
        
        ref.observe(.childAdded, with: {(snapshot) in
         
            let userId = snapshot.key
            ref.child(userId).child("last-message").observe(.childAdded, with: { (snapshot) in
                
                let msgId = snapshot.key;
                self.getMessageByMessageId(msgId: msgId)
                
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
    func getMessageByMessageId(msgId: String) -> Void {
        
        let messagesReference = FIRDatabase.database().reference().child("messages").child(msgId)
        
        messagesReference.queryOrderedByKey().observe(.value, with: { (snapshot) in
        
            if let dictionary = snapshot.value as? [String:AnyObject] {
                
                let message = Message()
                message.setValuesForKeys(dictionary)
                print(message.text!)
                
                var partnerId = String()
                
                if message.toId == self.uid {
                    
                    partnerId = message.fromId!
                }
                else{
                    partnerId = message.toId!
                }
                
                self.mainDict[partnerId] = message
                
                self.MessagesArr = Array(self.mainDict.values) as! [Message]
                
                
                /// soring array here
                
                self.MessagesArr.sort(by: { (message1, message2) -> Bool in
                    
                    return (message1.timestamp?.doubleValue)! > (message2.timestamp?.doubleValue)!
                    
                })
                
                DispatchQueue.main.async {
                    
                    print("Dictionary is : \(self.mainDict)")
                    if self.MessagesArr.count == 0 {
                        print(" \n \n \n \nNo data")
                    }
                    else{
                        print("\n \n \n \n data found")
                        self.tblChat.reloadData()
                    }
                }
                
            }
            
            
            
            
        }, withCancel: nil)
        
    }
    
    func relativePast(for date : Date) -> String {
        
       // print("date is : \(date)")
        let units = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second, .weekOfYear])
        let components = Calendar.current.dateComponents(units, from: date, to: Date())
        
        if components.year! > 0 {
            return "\(components.year!) " + (components.year! > 1 ? "years ago" : "year ago")
            
        } else if components.month! > 0 {
            return "\(components.month!) " + (components.month! > 1 ? "months ago" : "month ago")
            
        } else if components.weekOfYear! > 0 {
            return "\(components.weekOfYear!) " + (components.weekOfYear! > 1 ? "weeks ago" : "week ago")
            
        } else if (components.day! > 0) {
            return (components.day! > 1 ? "\(components.day!) days ago" : "Yesterday")
            
        } else if components.hour! > 0 {
            return "\(components.hour!) " + (components.hour! > 1 ? "hours ago" : "hour ago")
            
        } else if components.minute! > 0 {
            return "\(components.minute!) " + (components.minute! > 1 ? "minutes ago" : "minute ago")
            
        } else {
            return "\(components.second!) " + (components.second! > 1 ? "seconds ago" : "second ago")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logout(_ sender: Any?) {
      
        let status : Bool =  ((try! FIRAuth.auth()?.signOut()) != nil)
        
        if (status){
            print("logout successfully")
            UserDefaults.standard.removeObject(forKey: "isLogin")
            UserDefaults.standard.synchronize()
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.goToSignup()
            
//            let vc = SignupVC(nibName: "SignupVC", bundle: nil)
//            self.navigationController?.pushViewController(vc, animated: true)
        }
        else{
            print("signout error")
            
            let alert = UIAlertController(title: "Oops", message: "Error while sign out", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Retry", style: UIAlertActionStyle.default, handler: { (_) -> Void in
                print("Retry pressed")
                
                self.logout(nil)
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.MessagesArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = MessagesArr[indexPath.row]
        
        let cell: InboxVCCell = tableView.dequeueReusableCell(withIdentifier: "inboxcell", for: indexPath) as! InboxVCCell
        
        cell.selectionStyle = .none
        cell.lblunreadcount.isHidden = true
        let timestamp = message.timestamp
        let interval: TimeInterval = Double(timestamp! as NSNumber)
        
        let date: Date = Date(timeIntervalSince1970: interval)
        
        cell.lableTime.text = self.relativePast(for: date)
        
        cell.lastmessage.text = message.text
        
        var partnerId = String()
        
        if message.toId == uid {
            
            partnerId = (message.fromId)!
        }
        else{
            partnerId = (message.toId)!
        }
        
        
        if unreadArr.count > 0 {
            var dic = [String:AnyObject]()
            for dicttt in unreadArr {
                
                dic = dicttt as! [String:AnyObject]
                
                if dic[partnerId] != nil {
                    
                    cell.lblunreadcount.text = dic[partnerId] as? String
                    
                    cell.lblunreadcount.isHidden = false
                }
                
            }
            
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(partnerId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            let temp = snapshot.value as! [String:AnyObject]
            cell.username.text = temp["name"] as! String?
            
            if let url = temp["userPhoto"] as! String? {
                cell.userimage.setShowActivityIndicator(true)
                cell.userimage.setIndicatorStyle(.gray)
                cell.userimage.sd_setImage(with: URL(string: url))
                
            }
            else{
                cell.userimage.image = UIImage(named: "avatar.png");
            }
            cell.mobile = temp["mobile"] as! String?
            
            
        }, withCancel: nil)
        
        
        
        return cell
    }
    
    @IBAction func closeSearchAction(_ sender: Any) {
        
    
        txtSearch.resignFirstResponder()
        txtSearch.text = ""
        
        UIView.animate(withDuration: 0.5, animations: {
            self.searchView.frame = CGRect(x: 0, y: -64, width: SCREEN_WIDTH, height: 64)
            self.check = true
        })
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @IBAction func newChatTapped(_ sender: Any) {
        
        let page = ContactVC(nibName: "ContactVC", bundle: nil)
        page.fromInbox = true
        self.navigationController?.pushViewController(page, animated: true)
//        self.present(page, animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let alertController = UIAlertController(title: "Are you sure to delete?", message: "", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
                action in
                
                print("Ok Pressed")
                
                let message = self.MessagesArr[indexPath.row]
                
                
                var partnerId = String()
                
                if message.toId == self.uid {
                    
                    partnerId = (message.fromId)!
                }
                else{
                    partnerId = (message.toId)!
                }
                
                FIRDatabase.database().reference()
                    .child("user-messages").child(self.uid!).child(partnerId).removeValue(completionBlock: { (error, ref) in
                        if error != nil {
                            print("Failed to delete message :",error!)
                            return
                        }
                        // one way but not safe
                        
                        self.mainDict.removeValue(forKey: partnerId)
                        
                        self.MessagesArr.remove(at: indexPath.row)
                        self.tblChat.deleteRows(at: [indexPath], with: .automatic)
                        self.observeMessages()
                        print("deleted")
                    })
                

                
            }
            )
            alertController.addAction(okAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
                action in
                
                
            }
            )
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = MessagesArr[indexPath.row]
      
        
        var partnerId = String()
        
        if message.toId == uid {
            
            partnerId = (message.fromId)!
        }
        else{
            partnerId = (message.toId)!
        }

        
        
        let page = ChatVC(nibName: "ChatVC", bundle: nil) as ChatVC
        
       page.isFriend = true
       page.user_id = partnerId
       
        
        self.navigationController?.pushViewController(page, animated: true)
        
        
        
    }
    @IBAction func searchTapped(_ sender: UIButton) {
      
            self.view.addSubview(searchView)
            UIView.animate(withDuration: 0.5, animations: {
                self.searchView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: 64)
                self.check = true
            })
        
    }
    

}
