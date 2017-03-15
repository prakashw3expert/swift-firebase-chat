//
//  ChatVC.swift
//  HeyU
//
//  Created by Bekground on 24/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase


class ChatVC: UIViewController,UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,UITextViewDelegate {
    fileprivate var videoProfile = AgoraRtcVideoProfile._VideoProfile_720P
    fileprivate var encryptionType = EncryptionType.xts128
    @IBOutlet var botttomconstraints: NSLayoutConstraint!
    @IBOutlet var tblTopconstraint: NSLayoutConstraint!
    @IBOutlet var btmconst: NSLayoutConstraint!
    @IBOutlet var lblnamewidth: NSLayoutConstraint!
    @IBOutlet var btnSend: UIButton!
    @IBOutlet var tblChat: UITableView!
    @IBOutlet var txtMessage: UITextView!
    @IBOutlet var indicator: UILabel!
    @IBOutlet var lblOnline: UILabel!
    @IBOutlet var friendImage: UIImageView!
    @IBOutlet var friendName: UILabel!
    var usernamegot : String!
    @IBOutlet var lblPlaceholde: UILabel!
    
    var MessagesArr = [Message]()
    var messageDictionary = [String: String]()
    var uid : String? = nil
    
    let userTypingQuery : FIRDatabaseQuery? = nil
    
    var Unreadrefference: FIRDatabaseReference? = nil
    var userIsTypingRef: FIRDatabaseReference? = nil
    var userref: FIRDatabaseReference? = nil
    var onlineRef: FIRDatabaseReference? = nil
    var msgref: FIRDatabaseReference? = nil
    var typingRefference: FIRDatabaseReference? = nil
    var messagesReference: FIRDatabaseReference? = nil
    
    var groupInfo = [String : AnyObject]()
    var isTyping : Bool?
    var isFriend : Bool?
    var localTyping : Bool?
    var mobile : String? = nil
    var toId : String? = nil
    var profileImageUrl: String? = nil
    
    // from other view controller
    
    var user_id : String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tblChat.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "chatcell")
       tblChat.register(UINib(nibName: "GroupChatCell", bundle: nil), forCellReuseIdentifier: "groupchatcell")
        
        lblOnline.isHidden = true
        localTyping = false
        indicator.text = ""
        isTyping = false
        setUpNotifications()
        uid = FIRAuth.auth()?.currentUser?.uid
        
        if isFriend! {
           self.getUser()
            self.observeMessages()
        }
        else{
            self.getGroup()
            self.observeGroupMessages()
        }
        
        
        friendImage.layer.cornerRadius = 19
        friendImage.clipsToBounds = true
        
        btnSend.layer.cornerRadius = 5
        btnSend.clipsToBounds = true
        
        lblOnline.layer.cornerRadius = 5
        lblOnline.clipsToBounds = true
        
        txtMessage.layer.cornerRadius = 5
        txtMessage.clipsToBounds = true
        
        self.perform(#selector(scrollToBottomAnimated), with: nil, afterDelay: 0)
        if isFriend! {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(openFriendInfo))
            self.friendName.isUserInteractionEnabled = true
            self.friendName.addGestureRecognizer(gesture)
        }
        else{
            let gesture = UITapGestureRecognizer(target: self, action: #selector(openGroupInfo))
            self.friendName.isUserInteractionEnabled = true
            self.friendName.addGestureRecognizer(gesture)
        }
        
        
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func callbtnPressed(_ sender: Any) {
        
        
        let callingRef = FIRDatabase.database().reference().child("users").child(user_id!)
        callingRef.child("Calling").onDisconnectRemoveValue()
       // callingRef.child("Calling").child(uid!).onDisconnectSetValue(false)
        callingRef.child("Calling").setValue([uid! : true])
        
        let page = StartVideoCallVC(nibName: "StartVideoCallVC", bundle: nil)
        page.roomName = self.uid!
        page.videoProfile = videoProfile
        page.encryptionSecret = ""
        page.encryptionType = encryptionType
        //page.delegate = self
        UserDefaults.standard.set(false, forKey: "isIncomingCall")
        UserDefaults.standard.synchronize()
        
       
        present(page, animated: true, completion: nil)
        
        
        
    }
    
    func openFriendInfo() {
        
        let page = FriendProfileVC(nibName: "FriendProfileVC", bundle: nil)
        page.image = self.friendImage.image!
        page.user_id = self.user_id
        self.navigationController?.pushViewController(page, animated: true)
        
        
    }
    func openGroupInfo() {
        
        let page = GroupInfoVC(nibName: "GroupInfoVC", bundle: nil)
        
        page.groupInfo = self.groupInfo
        page.image = self.friendImage.image!
        page.user_id = self.user_id
        self.navigationController?.pushViewController(page, animated: true)
        
        
    }
    func observeGroupMessages() {
        
        msgref = FIRDatabase.database().reference().child("user-group-messages")
        
       // let userId = self.user_id
        
        self.msgref?.child(self.user_id!).child("messages").observe(.childAdded, with: { (snapshot) in
            
            let msgId = snapshot.key
            
            self.GetGroupMessagesFromMessageId(msgId: msgId)
            
        }, withCancel: nil)
        
    }
    func GetGroupMessagesFromMessageId(msgId: String) {
        
        messagesReference = FIRDatabase.database().reference().child("group-messages").child(msgId)
        
        messagesReference?.observe(.value, with: { (snapshot) in
            
            if let dict = snapshot.value as? [String : AnyObject] {
                
                let message = Message()
                
                message.setValuesForKeys(dict)
                print(message.text!)
                
                self.MessagesArr.append(message)
                
            }
            
            //            if (dict["fromId"] as! String == self.uid! && dict["toId"] as? String == self.user_id || dict["fromId"] as? String == self.user_id && dict["toId"] as? String == self.uid) {
            //
            //                self.MessagesArr.append(dict)
            //            }
            
            
            DispatchQueue.main.async {
                
                self.tblChat.reloadData()
                self.scrollToBottomAnimated()
                
            }
            
        }, withCancel: nil)
        
    }

    
    func getGroup() {
        
        let whichfont = UIFont(name: "Helvetica", size: 16)
        let myString: NSString = self.groupInfo["groupname"] as! NSString
        let size: CGSize = myString.size(attributes: [NSFontAttributeName: whichfont ?? UIFont.systemFont(ofSize: 16)])
        
        let width = size.width + 5
        
        if(width < 180) {
            self.lblnamewidth.constant = width
        }else{
            self.lblnamewidth.constant = 180
        }
        

        
        self.friendName.text = self.groupInfo["groupname"] as! String?
        
        if let groupPhoto = self.groupInfo["groupPhoto"] as! String? {
            
            self.friendImage.sd_setImage(with: URL(string: groupPhoto))
            
        }
        else{
            self.friendImage.image = UIImage(named: "image.png")
        }
        
    }
    
    func clearUnreadCount() {
        
        Unreadrefference = FIRDatabase.database().reference().child("user-messages").child(uid!).child(self.toId!)
        
        Unreadrefference?.observe(.childAdded, with: { (snapshot) in
            
            let unreadRef = FIRDatabase.database().reference().child("user-messages").child(self.uid!).child(self.toId!).child("unread-message")
            unreadRef.setValue(nil)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearUnreadMessages"), object: nil)
            
            
        }, withCancel: nil)
        
    }
    func getUser() {
        
        userref = FIRDatabase.database().reference().child("users").child(self.user_id!)
        
        userref?.observe(.value, with: { (snapshot) in
            
            print(snapshot)
            
            guard let userdict = snapshot.value as? [String: AnyObject] else {
                
                return
                
            }
            
                    self.usernamegot = userdict["name"] as? String
                    self.mobile = userdict["mobile"] as? String
                    let whichfont = UIFont(name: "Helvetica", size: 16)
                    let myString: NSString = self.usernamegot as NSString
                    let size: CGSize = myString.size(attributes: [NSFontAttributeName: whichfont ?? UIFont.systemFont(ofSize: 16)])
                    
                    let width = size.width + 5
                    
                    if(width < 180) {
                        self.lblnamewidth.constant = width
                    }else{
                        self.lblnamewidth.constant = 180
                    }
            
            if let url = userdict["userPhoto"] as? String {
                
                self.friendImage.sd_setImage(with: URL(string: url))
                
            }
            else{
                self.friendImage.image = UIImage(named: "avatar.png")
            }
            
                    self.friendName.text = self.usernamegot
            
            
        }, withCancel: nil)

        
        
    }
    
    func observeMessages() {
        
        msgref = FIRDatabase.database().reference().child("user-messages").child(uid!)
        
            let userId = self.user_id
            
            self.msgref?.child(userId!).child("messages").observe(.childAdded, with: { (snapshot) in
                
                let msgId = snapshot.key
                
                self.GetMessagesFromMessageId(msgId: msgId)
                
            }, withCancel: nil)
            
        
    }
    
    func relativePast(for date : Date) -> String {
        
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

    
    func GetMessagesFromMessageId(msgId: String) {
        
        messagesReference = FIRDatabase.database().reference().child("messages").child(msgId)
        
        messagesReference?.observe(.value, with: { (snapshot) in
            
           if let dict = snapshot.value as? [String : AnyObject] {
            
             let message = Message()
            
            message.setValuesForKeys(dict)
            print(message.text!)
            
            self.MessagesArr.append(message)
            
            }
            
//            if (dict["fromId"] as! String == self.uid! && dict["toId"] as? String == self.user_id || dict["fromId"] as? String == self.user_id && dict["toId"] as? String == self.uid) {
//                
//                self.MessagesArr.append(dict)
//            }
            
            
            DispatchQueue.main.async {
                
                self.tblChat.reloadData()
                self.scrollToBottomAnimated()
                
            }
            
        }, withCancel: nil)
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return MessagesArr.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = MessagesArr[indexPath.row]
        
        if isFriend! {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatcell", for: indexPath) as! ChatCell
        
        cell.selectionStyle = .none
        
        let messageString = message.text
        
        let titleFont = UIFont(name: "Helvetica", size: 14)
        
        let sizeMessage = CGSize(width: SCREEN_WIDTH - 92, height: CGFloat.greatestFiniteMagnitude)
        
        let sizeer = self.getLabelHeightwithText(stringText: messageString!, andsizeConstraints: sizeMessage, withFont: titleFont!)
        
        if message.fromId == uid {
            
            cell.chatArrowRec.isHidden = false
            cell.chatArrowSend.isHidden = true
            
            cell.lblMessage.textAlignment = .left
            
            if sizeer.height < 27  {
                cell.grayViewHeight.constant = 35
            }
            else{
                cell.grayViewHeight.constant = sizeer.height + 8
                
            }
            let leadConstraint = SCREEN_WIDTH - (sizeer.width + 40)
            
            cell.lead.constant = leadConstraint
            
            cell.trail.constant = 12
            cell.lblMessage.textColor = UIColor.white
            
            cell.grayChatCellView.backgroundColor = UIColor(red: 225.0/255.0, green: 28.0/255.0, blue: 39.0/255.0, alpha: 1.0)
            
            
        }
        else{
            
            cell.chatArrowRec.isHidden = true
            cell.chatArrowSend.isHidden = false
            
            cell.lblMessage.textAlignment = .left
            
            if sizeer.height < 27  {
                cell.grayViewHeight.constant = 35
            }
            else{
                cell.grayViewHeight.constant = sizeer.height + 8
                
            }
            let trailConstraint = SCREEN_WIDTH - (sizeer.width + 40)
            
            cell.trail.constant = trailConstraint
            
            cell.lead.constant = 12
            cell.lblMessage.textColor = UIColor.black
            
            cell.grayChatCellView.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)

            
            
            
            
        }
        
        
        cell.lblMessage.text = messageString!
        
        return cell
        }
        else{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "groupchatcell", for: indexPath) as! GroupChatCell
            
            cell.selectionStyle = .none
            
            let messageString = message.text
            
            let titleFont = UIFont(name: "Helvetica", size: 14)
            
            let sizeMessage = CGSize(width: SCREEN_WIDTH - 92, height: CGFloat.greatestFiniteMagnitude)
            
            let sizeer = self.getLabelHeightwithText(stringText: messageString!, andsizeConstraints: sizeMessage, withFont: titleFont!)
            
            if message.fromId == uid {
                
                cell.chatArrowRec.isHidden = false
                cell.chatArrowSend.isHidden = true
                cell.senderName.isHidden = true
                cell.message.textAlignment = .left
                cell.messageTop.constant = -22
                if sizeer.height < 27  {
                    cell.grayViewHeight.constant = 30//48
                    
                }
                else{
                    cell.grayViewHeight.constant = sizeer.height + 8//12
                    
                }
                let leadConstraint = SCREEN_WIDTH - (sizeer.width + 40)
                
                
                cell.lead.constant = leadConstraint
                
                cell.trail.constant = 12
                cell.message.textColor = UIColor.white
                
                cell.grayChatCellView.backgroundColor = UIColor(red: 225.0/255.0, green: 28.0/255.0, blue: 39.0/255.0, alpha: 1.0)
                
                
            }
            else{
                
                cell.chatArrowRec.isHidden = true
                cell.chatArrowSend.isHidden = false
                cell.senderName.isHidden = false
                cell.messageTop.constant = 0
                cell.message.textAlignment = .left
                
                if sizeer.height < 27  {
                    cell.grayViewHeight.constant = 48
                }
                else{
                    cell.grayViewHeight.constant = sizeer.height + 12
                    
                }
                if sizeer.width < 85 {
                    let trailConstraint = SCREEN_WIDTH - (sizeer.width + 110)
                    cell.trail.constant = trailConstraint
                }
                else{
                    let trailConstraint = SCREEN_WIDTH - (sizeer.width + 75)
                    cell.trail.constant = trailConstraint
                }
                
                
               // cell.trail.constant = trailConstraint
                
                cell.lead.constant = 12
                cell.message.textColor = UIColor.black
                
                cell.grayChatCellView.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
                
                
                
                
                
            }
            
            
            cell.message.text = messageString!
            cell.senderName.text = message.fromMobile
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let message = MessagesArr[indexPath.row]
        
        let messageString = message.text
        
        let titleFont = UIFont(name: "Helvetica", size: 14)
        
        let sizeMessage = CGSize(width: SCREEN_WIDTH - 92, height: SCREEN_HEIGHT)
        
        let sizeer = self.getLabelHeightwithText(stringText: messageString!, andsizeConstraints: sizeMessage, withFont: titleFont!)
        
        if isFriend! {
            if sizeer.height < 35 {
                return 44
            }
            else{
                return sizeer.height + 22
            }
        }
        else{
        
        if message.fromId == uid {
            if sizeer.height < 35 {
                return 44
            }
            else{
                return sizeer.height + 22
            }
        }
        else{
            if sizeer.height < 35 {
                return 69
            }
            else{
                return sizeer.height + 27
            }

        }
        }
        

        
    }
    
    func getLabelHeightwithText(stringText: String, andsizeConstraints labelSize: CGSize, withFont font:UIFont) -> CGSize {
        
        
        let constraints = CGSize(width: labelSize.width, height: CGFloat.greatestFiniteMagnitude)
        let size : CGSize?
        
        let context = NSStringDrawingContext()
        let boundingBox = stringText.boundingRect(with: constraints, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: context).size
        
        
        size = CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        
        return size!
        
    }
    
    func scrollToBottomAnimated() {
        
        let rows = tblChat.numberOfRows(inSection: 0)
        
        if(rows > 0) {
            
            tblChat.scrollToRow(at: NSIndexPath(row: rows - 1, section: 0) as IndexPath, at: .bottom, animated: false)
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.handleSend(true)
        return true
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if !textView.hasText {
            lblPlaceholde.isHidden = true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if !textView.hasText {
            lblPlaceholde.isHidden = false
            
            FIRDatabase.database().reference().child("user-messages").child(self.user_id!).child(uid!).child("typing").removeValue()
            
            indicator.isHidden = true
            
        }
        else{
            
            lblPlaceholde.isHidden = true
            isTyping = !(textView.text != nil)
            
            FIRDatabase.database().reference().child("user-messages").child(self.user_id!).child(uid!).child("typing").child(uid!).setValue(NSNumber(booleanLiteral: true))
            
            
        }
        
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
        }
        
        return true
        
    }
    
    func setUpNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardshowed), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardhidden), name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardshowed(notification : Notification) {
        
        let keyboardInfo = notification.userInfo
        let keyboardFrameBegin = keyboardInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue
        
        let keyboardHeight = keyboardFrameBegin.cgRectValue.size.height
        
        botttomconstraints.constant = CGFloat(keyboardHeight)
        btmconst.constant = CGFloat(keyboardHeight)
        self.perform(#selector(scrollToBottomAnimated), with: nil, afterDelay: 0)
        
        
    }
    
    func keyboardhidden(notification : NSNotification) {
        
        botttomconstraints.constant = 0
        btmconst.constant = 0
         self.perform(#selector(scrollToBottomAnimated), with: nil, afterDelay: 0)
        
        
    }
    
    @IBAction func backAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "observe"), object: nil)
        
        
        self.navigationController!.popViewController(animated: true)
        
    }
    
    @IBAction func friendProfileTapped(_ sender: Any) {
    }
    @IBAction func handleSend(_ sender: Any) {
        
        if isFriend! {
        
        let set = NSCharacterSet.whitespaces
        if txtMessage.text.trimmingCharacters(in: set).characters.count == 0 {
            return
        }
        let messageText = txtMessage.text!
        txtMessage.text = ""
        let toId = self.user_id
        let fromId = FIRAuth.auth()?.currentUser?.uid
        
        let interval = NSDate().timeIntervalSince1970
        
        let timestamp = NSNumber(value: interval)
        
            let values = ["fromId": fromId!, "toId": toId!, "text": messageText, "timestamp": timestamp, "fromMobile" : mobileNumber as! String] as [String : Any]
        
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            
            if !(error != nil) {
                
                print("Message sent")
                
                self.isTyping = false
                let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId!).child(toId!).child("messages")
                 let messageId = childRef.key
                
                userMessagesRef.updateChildValues([messageId : NSNumber(booleanLiteral: true)])
                
                
                let recipientMessageRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("messages")
                
                recipientMessageRef.updateChildValues([messageId : NSNumber(booleanLiteral: true)])
                
                FIRDatabase.database().reference().child("user-messages").child(self.user_id!).child(self.uid!).child("typing").removeValue()
                
                // adding last message here
                
                let userLastMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId!).child(toId!).child("last-message")
                
                userLastMessagesRef.setValue([messageId: NSNumber(booleanLiteral: true)])
                
                let recipientLastMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("last-message")
                
                recipientLastMessagesRef.setValue([messageId: NSNumber(booleanLiteral: true)])

                let recipientUnreadMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("unread-message")
                
                recipientUnreadMessagesRef.updateChildValues([messageId: NSNumber(booleanLiteral: true)])
                
            }
            
            
        })
        
        }
        else{
            
            let set = NSCharacterSet.whitespaces
            if txtMessage.text.trimmingCharacters(in: set).characters.count == 0 {
                return
            }
            let messageText = txtMessage.text!
            txtMessage.text = ""
            let toId = self.user_id
            let fromId = FIRAuth.auth()?.currentUser?.uid
            
            let interval = NSDate().timeIntervalSince1970
            
            let timestamp = NSNumber(value: interval)
            
            let values = ["fromId": fromId!, "toId": toId!, "text": messageText, "timestamp": timestamp, "fromMobile" : mobileNumber as! String] as [String : Any]
            
            let ref = FIRDatabase.database().reference().child("group-messages")
            let childRef = ref.childByAutoId()
            
            childRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                
                if !(error != nil) {
                    
                    print("Message sent")
                    
                    self.isTyping = false
                    let userMessagesRef = FIRDatabase.database().reference().child("user-group-messages").child(toId!).child("messages")
                    let messageId = childRef.key
                    
                    userMessagesRef.updateChildValues([messageId : NSNumber(booleanLiteral: true)])
                    
                    
//                    let recipientMessageRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("messages")
//                    
//                    recipientMessageRef.updateChildValues([messageId : NSNumber(booleanLiteral: true)])
                    
                    FIRDatabase.database().reference().child("user-group-messages").child(self.user_id!).child(self.uid!).child("typing").removeValue()
                    
                    // adding last message here
                    
                    let groupLastMessagesRef = FIRDatabase.database().reference().child("user-group-messages").child(toId!).child("last-message")
                    
                    groupLastMessagesRef.setValue([messageId: NSNumber(booleanLiteral: true)])
                    
//                    let recipientLastMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("last-message")
//                    
//                    recipientLastMessagesRef.setValue([messageId: NSNumber(booleanLiteral: true)])
                    
//                    let recipientUnreadMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId!).child("unread-message")
//                    
//                    recipientUnreadMessagesRef.updateChildValues([messageId: NSNumber(booleanLiteral: true)])
                    
                }
                
                
            })

            
        }
        
        
        
    }
}
