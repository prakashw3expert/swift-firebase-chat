//
//  SignupVC.swift
//  HeyU
//
//  Created by Bekground on 24/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import DigitsKit

class SignupVC: UIViewController {

    @IBOutlet var loginView: UIView!
    
    @IBOutlet var txtConfirmPassword: UITextField!
    @IBOutlet var confirmPasswordView: UIView!
    @IBOutlet var bgScroll: UIScrollView!
    @IBOutlet var lblLogo: UILabel!
    @IBOutlet var signUpView: UIView!
    @IBOutlet var btnSignup: UIButton!
    @IBOutlet var txtPassword: UITextField!
    @IBOutlet var txtEmail: UITextField!
    @IBOutlet var passwordView: UIView!
    @IBOutlet var nameView: UIView!
    @IBOutlet var emailView: UIView!
    
    @IBOutlet var txtName: UITextField!
    @IBOutlet var emailViewLogin: UIView!
    @IBOutlet var txtPasswordLogin: UITextField!
    @IBOutlet var txtEmailLogin: UITextField!
    
    @IBOutlet var btnsignIn: UIButton!
    @IBOutlet var passwordViewlogin: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        if(UIScreen.main.bounds.height > 480){
            bgScroll.isScrollEnabled = false
        }
        setupView()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signinTapped(_ sender: UIButton) {
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
            self.loginView.alpha = 1.0
            self.signUpView.alpha = 0.0
            
            self.loginView.isHidden = false
            self.signUpView.isHidden = true
        }, completion: nil)
   

        
    }

    @IBAction func signUpTapped(_ sender: UIButton) {
        
        print("signup tapped")
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
            self.signUpView.alpha = 1.0
            self.loginView.alpha = 0.0
            self.loginView.isHidden = true
            self.signUpView.isHidden = false
        }, completion: nil)
        
    }
    
    /// Login is here***********************
    @IBAction func LoginAction(_ sender: UIButton) {
        
        if txtEmailLogin.text == "" {
            
            print("enter email")
            txtEmailLogin.becomeFirstResponder()
            
            
        }
        else if txtPasswordLogin.text == "" {
            print("enter password")
            txtPasswordLogin.becomeFirstResponder()
            
        }
        else if (!isValidEmail(testStr: txtEmailLogin.text!))
        {
            print("Invalid email")
            let alert = UIAlertController(title: "Alert", message: "Invalid Email", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        else{
        
        FIRAuth.auth()?.signIn(withEmail: txtEmailLogin.text!, password: txtPasswordLogin.text!, completion: { (user, error) in
            
            if (error != nil){
                
                print("Login error : \(error?.localizedDescription)")
                let alert = UIAlertController(title: "Alert", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else{
                print("Login successfull")
               // print("token for push notification is : \(FIRInstanceID.instanceID().token())")
                self.connectToFirebase()
                self.getUserInfo()
                
            }
            
        })
        }
        
        
    }
    
    func getUserInfo() {
        
        let uid = FIRAuth.auth()?.currentUser?.uid
        
        let ref = FIRDatabase.database().reference().child("users").child(uid!)
        ref.observe(.value, with: { (snapshot) in
            
            print(snapshot)
            
           if let dict = snapshot.value as? [String : AnyObject] {
            
             let mobileno = dict["mobile"] as! String
            
            mobileNumber = mobileno as Any
            UserDefaults.standard.set(mobileno, forKey: "mobileNumber")
            UserDefaults.standard.synchronize()
                
            }
            
            
            }, withCancel: nil)
        
    }
    
    func connectToFirebase() {
       
        FIRMessaging.messaging().connect { (error) in
            
            if error != nil {
                print("Unable to connect to FCM")
            }
            else{
                print("Connected to FCM")
            }
        }
        
        
        let user_id: String = (FIRAuth.auth()?.currentUser?.uid)!
        let connectedRef = FIRDatabase.database().reference(fromURL: "https://heyuchat.firebaseio.com/.info/connected")
        
        connectedRef.observe(.value, with: { (snapshot) in
            
          print("User is: \(snapshot)")
            if (snapshot.value as! Bool){
                
                let myConnectionRef = FIRDatabase.database().reference().child("users").child(user_id)
                myConnectionRef.child("Online").child(user_id).onDisconnectSetValue(false)
                myConnectionRef.child("Lastseen") .onDisconnectSetValue([user_id : FIRServerValue.timestamp()])
                
                myConnectionRef.child("Online").setValue([user_id : true])
                FIRDatabase.database().goOnline()
                
               UserDefaults.standard.set(true, forKey: "isLogin")
               UserDefaults.standard.synchronize()
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.goToTabBar()
                
                
//                let vc = InboxViewController(nibName: "InboxViewController", bundle: nil)
//                
//                self.navigationController?.pushViewController(vc, animated: true)
                
            }
            
        }, withCancel: nil)
        
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
       
        return true
        
    }
    func setupView() {
        
        loginView.frame = CGRect(x: 0, y: lblLogo.frame.origin.y + lblLogo.frame.size.height + 16, width: 320, height: loginView.frame.size.height)
        
        bgScroll.addSubview(loginView)
        
        signUpView.frame = CGRect(x: 0, y: lblLogo.frame.origin.y + lblLogo.frame.size.height + 16, width: 320, height: signUpView.frame.size.height)
        
        bgScroll.addSubview(signUpView)
        
        loginView.isHidden = false;
        loginView.alpha = 1.0;
        signUpView.isHidden = true;
        signUpView.alpha = 0.0;
        
        self.btnSignup.layer.cornerRadius = 20;
        self.btnSignup.clipsToBounds = true
        self.btnsignIn.layer.cornerRadius = 20;
        self.btnsignIn.clipsToBounds = true
        self.emailView.layer.cornerRadius = 20;
        self.emailView.clipsToBounds = true
        
        self.passwordView.layer.cornerRadius = 20
        self.passwordView.clipsToBounds = true
        
        self.confirmPasswordView.layer.cornerRadius = 20
        self.confirmPasswordView.clipsToBounds = true
        
        self.nameView.layer.cornerRadius = 20
        self.nameView.clipsToBounds = true
        
        self.emailViewLogin.layer.cornerRadius = 20;
        self.emailViewLogin.clipsToBounds = true
        
        self.passwordViewlogin.layer.cornerRadius = 20
        self.passwordViewlogin.clipsToBounds = true
        
        

        
    bgScroll.contentSize = CGSize(width: 320, height: signUpView.frame.size.height + 135 + 20)
 
        
    }
    /// signup is here *********************
    @IBAction func btnSignupTapped(_ sender: UIButton) {
        
        if txtName.text == "" {
            
            txtName.becomeFirstResponder()
        }
        else if txtEmail.text == "" {
            
            txtEmail.becomeFirstResponder()
        }
        else if txtPassword.text == "" {
            
            txtPassword.becomeFirstResponder()
        }
        else if txtConfirmPassword.text == "" {
            
            txtConfirmPassword.becomeFirstResponder()
        }
        else if (!isValidEmail(testStr: txtEmail.text!))
        {
            print("Invalid email")
            let alert = UIAlertController(title: "Alert", message: "Invalid Email", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        else{
            
            if txtPassword.text != txtConfirmPassword.text {
                
                print("password not matched")
                return
            }
            
        let digits = Digits.sharedInstance()
        let configuration = DGTAuthenticationConfiguration(accountFields: .defaultOptionMask)
        configuration?.title = "HeyU"
        configuration?.phoneNumber = "+91"
        configuration?.appearance = self.makeTheme()
        
        digits.authenticate(with: nil, configuration: configuration!) { session, error in
            
            if ((session?.userID) != nil) {
                
                var mobileNumber = session?.phoneNumber
                mobileNumber = mobileNumber?.replacingOccurrences(of: "+91", with: "")
                
                UserDefaults.standard.setValue(mobileNumber, forKey: "mobileNumber")
                
                UserDefaults.standard.synchronize()
                
                if self.validateInput()! {
                    if self.isValidEmail(testStr: self.txtEmail.text!){
                        
                        self.addDataToFirebase()
                    }
                    else{
                        print("invalid email id")
                        
                    }
                    
                }
                else{
                    print("invalid input")
                    return
                }

                
             Digits.sharedInstance().logOut()
                
            }
            else{
                
                print("Authentication error : \(error?.localizedDescription)")
            }
            
            
        }
        }
        
        
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    func validateInput() -> Bool? {
        
        if txtEmail.text != "" && txtPassword.text != "" {
            return true
        }
        else{
            return false
        }
        
    }
    
    func makeTheme() -> DGTAppearance {
        
        let theme = DGTAppearance()
        theme.bodyFont = UIFont(name: "Helvetica", size: 16)
        theme.labelFont = UIFont(name: "Helvetica-Bold", size: 22)
        theme.accentColor = UIColor.white
        theme.backgroundColor = UIColor(red: 224.0/255.0, green: 28.0/255.0, blue: 39.0/255.0, alpha: 1.0)
        
       // theme.logoImage = UIImage(named: "")
        return theme
        
    }
    
    func addDataToFirebase() {
        
        print("valid")
        let email = txtEmail.text!
        FIRAuth.auth()?.createUser(withEmail: email, password: txtPassword.text!, completion: { (user, error) in
            
            if (error != nil) {
                print(error?.localizedDescription as Any)
                
                let alert = UIAlertController(title: "Alert", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
            }
            else{
                
                print("User created successfully")
                print("Display name : \(user?.displayName)")
                print("email address : \(user?.email)")
                
                let uid = FIRAuth.auth()?.currentUser?.uid
                let fullname = self.txtName.text!
                //                        let email = self.txtEmail.text!
                let mobile = mobileNumber
                let userRef = FIRDatabase.database().reference().child("users").child(uid!)
                
                let values = ["name" : fullname, "email" : email, "profileImage" : nil, "status" : "Available", "mobile" : mobile]
                userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                    
                    if (error == nil) {
                        print("Data uploaded to Firebase")
                        
                            print("Button clicked")
                            UserDefaults.standard.set(true, forKey: "isLogin")
                            UserDefaults.standard.synchronize()
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            
                            appDelegate.goToTabBar()
                            
                            
                        
                    }
                    else{
                        print("Error saving data : \(error?.localizedDescription)")
                    }
                    
                })
                
                
                
                
            }
        })
        
        
    }

}
