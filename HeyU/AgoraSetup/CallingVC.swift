//
//  CallingVC.swift
//  HeyU
//
//  Created by BekGround-2 on 10/03/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

class CallingVC: UIViewController {

    @IBOutlet var answerVieww: UIView!
    var player : AVAudioPlayer?
    @IBOutlet var rejectBtn: UIButton!
    @IBOutlet var ansBtn: UIButton!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var encryptionTextField: UITextField!
    @IBOutlet weak var encryptionButton: UIButton!
    var RoomNameToGo : String?
    var callRef : FIRDatabaseReference?
    fileprivate var videoProfile = AgoraRtcVideoProfile._VideoProfile_720P
    fileprivate var encryptionType = EncryptionType.xts128 {
        didSet {
            encryptionButton?.setTitle(encryptionType.description(), for: UIControlState())
        }
    }
    
    

    @IBAction func RejectTapped(_ sender: Any) {
        
        let ref = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!)
        ref.child("Calling").removeValue()
        self.callRef?.child("Calling").removeValue()
        player?.stop()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func answerTapped(_ sender: Any) {
        
       //self.view.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
      // self.view.isOpaque = false
       answerVieww.isHidden = true
        print(RoomNameToGo!)
        player?.stop()
        enter(roomName: self.RoomNameToGo!)
        
        
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }
        
        switch segueId {
        case "mainToSettings":
            let settingsVC = segue.destination as! SettingVC
            settingsVC.videoProfile = videoProfile
            settingsVC.delegate = self
        case "mainToRoom":
            let roomVC = segue.destination as! StartVideoCallVC
            roomVC.roomName = (sender as! String)
            roomVC.encryptionSecret = encryptionTextField.text
            roomVC.encryptionType = encryptionType
            roomVC.videoProfile = videoProfile
            roomVC.delegate = self
        default:
            break
        }
    }
    @IBAction func presentSetting(_ sender: Any) {
        
        
    }
    
    @IBAction func doRoomNameTextFieldEditing(_ sender: UITextField) {
        if let text = sender.text , !text.isEmpty {
            let legalString = MediaCharacter.updateToLegalMediaString(from: text)
            sender.text = legalString
        }
    }
    
    @IBAction func doEncryptionTextFieldEditing(_ sender: UITextField) {
        if let text = sender.text , !text.isEmpty {
            let legalString = MediaCharacter.updateToLegalMediaString(from: text)
            sender.text = legalString
        }
    }
    
    @IBAction func doEncryptionTypePressed(_ sender: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for encryptionType in EncryptionType.allValue {
            let action = UIAlertAction(title: encryptionType.description(), style: .default) { [weak self] _ in
                self?.encryptionType = encryptionType
            }
            sheet.addAction(action)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cancel)
        sheet.popoverPresentationController?.sourceView = encryptionButton
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func doJoinPressed(_ sender: UIButton) {
        enter(roomName: "56789")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(closeAnswerScreen), name: NSNotification.Name(rawValue: "closeAnswerScreen"), object: nil)
        
        
        rejectBtn.layer.cornerRadius = rejectBtn.frame.size.width / 2
        rejectBtn.clipsToBounds = true
        
        ansBtn.layer.cornerRadius = rejectBtn.frame.size.width / 2
        ansBtn.clipsToBounds = true
        playSound()
       
    }
    func closeAnswerScreen() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playSound(){
        //TODO fix this!
        let path = Bundle.main.path(forResource: "Bumro-Bumro", ofType:"mp3")!
        let url = URL(fileURLWithPath: path)
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
}

private extension CallingVC {
    func enter(roomName: String?) {
        guard let roomName = roomName , !roomName.isEmpty else {
            return
        }
        
        
        
//        dismiss(animated: true, completion: { () -> Void in
//            let page = StartVideoCallVC(nibName: "StartVideoCallVC", bundle: nil)
//            page.roomName = roomName
//            page.myRef = self.callRef
//            page.videoProfile = self.videoProfile
//            page.encryptionSecret = ""
//            page.encryptionType = self.encryptionType
//            present(page, animated: true, completion: nil)
//        });
        let page = StartVideoCallVC(nibName: "StartVideoCallVC", bundle: nil)
        page.roomName = roomName
        page.myRef = self.callRef
        page.videoProfile = videoProfile
        page.encryptionSecret = ""
        page.encryptionType = encryptionType
        self.dismiss(animated: false, completion: {
            let animation = CATransition()
            animation.duration = 0.5
            animation.type = kCATransitionPush
            animation.subtype = kCATransitionFromRight
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            page.view.layer.add(animation, forKey: "SwitchToView")
            
            UIApplication.topViewController()?.present(page, animated: false, completion: nil)})
        
        //present(page, animated: true, completion: nil)
    }
    
    
}

extension CallingVC: SettingsVCDelegate {
    func settingsVC(_ settingsVC: SettingVC, didSelectProfile profile: AgoraRtcVideoProfile) {
        videoProfile = profile
        dismiss(animated: true, completion: nil)
    }
}

extension CallingVC: RoomVCDelegate {
    func roomVCNeedClose(_ roomVC: StartVideoCallVC) {
        dismiss(animated: true, completion: nil)
    }
}

extension CallingVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case roomNameTextField:     enter(roomName: textField.text)
        case encryptionTextField:   textField.resignFirstResponder()
        default: break
        }
        
        return true
    }

}
