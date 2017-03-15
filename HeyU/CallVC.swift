//
//  CallVC.swift
//  HeyU
//
//  Created by Bekground on 09/03/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase
class CallVC: UIViewController {

    @IBOutlet var lblname: UILabel!
    @IBOutlet var userImage: UIImageView!
    @IBOutlet var rejectBtn: UIButton!
    @IBOutlet var ansBtn: UIButton!
    
    @IBOutlet var callerReject: UIButton!
    var uid: String?
    var myCallingRef: FIRDatabaseReference?
    var callerImage : UIImage?
    var username: String?
    var imcalling: Bool?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        userImage.layer.cornerRadius = userImage.frame.size.width / 2
        userImage.clipsToBounds = true
        
        ansBtn.layer.cornerRadius = ansBtn.frame.size.width / 2
        ansBtn.clipsToBounds = true
        
        rejectBtn.layer.cornerRadius = rejectBtn.frame.size.width / 2
        rejectBtn.clipsToBounds = true
        
        callerReject.layer.cornerRadius = rejectBtn.frame.size.width / 2
        callerReject.clipsToBounds = true


        if imcalling! {
            ansBtn.isHidden = true
            rejectBtn.isHidden = true
            callerReject.isHidden = false
            userImage.image = callerImage
            lblname.text = username!
        }
        else{
            
            callerReject.isHidden = true
            rejectBtn.isHidden = false
            ansBtn.isHidden = false
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func AnswerTapped(_ sender: Any) {
        
        
        
    }
    @IBAction func RejectTapped(_ sender: Any) {
        
        if imcalling! {
            myCallingRef?.child("Calling").removeValue()
            dismiss(animated: true, completion: nil)
        }
        
        
    }
    @IBAction func rejectByReceiver(_ sender: Any) {
        
        myCallingRef?.child("Calling").removeValue()
        dismiss(animated: true, completion: nil)
        
    }
    
}
