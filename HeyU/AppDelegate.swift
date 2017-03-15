//
//  AppDelegate.swift
//  HeyU
//
//  Created by Bekground on 23/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import DigitsKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var alertWindow: UIWindow?

    var window: UIWindow?
    var navController: UINavigationController?
    let tabBarController = UITabBarController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //        UserDefaults.standard.removeObject(forKey: "isLogin")
        //        UserDefaults.standard.synchronize()
        
        
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        Fabric.with([Digits.self])
        window = UIWindow.init(frame: UIScreen.main.bounds)
        navigateToSignup()
        window?.makeKeyAndVisible()
        return true
    }
    
    func navigateToSignup() -> Void {
        
        if(isLogin){
            
            self.connectToFirebase()
            
            self.goToTabBar()
            
//            let navigationController = UINavigationController(rootViewController: page)
//            navigationController.navigationBar.isTranslucent = true
//            navigationController.isNavigationBarHidden = true
//            self.window?.rootViewController = navigationController
            
        }
        else{
        
        let page : SignupVC = SignupVC(nibName:"SignupVC" , bundle : nil)
        let navigationController = UINavigationController(rootViewController: page)
        navigationController.navigationBar.isTranslucent = true
        navigationController.isNavigationBarHidden = true
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
       }
    }

    func goToSignup(){
        
        let page : SignupVC = SignupVC(nibName:"SignupVC" , bundle : nil)
        let navigationController = UINavigationController(rootViewController: page)
        navigationController.navigationBar.isTranslucent = true
        navigationController.isNavigationBarHidden = true
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
    }
    
    
    func goToTabBar() {
        
        let inbox : InboxViewController = InboxViewController(nibName:"InboxViewController" , bundle : nil)
        inbox.tabBarItem = UITabBarItem(title: "Chat", image:UIImage(named: "chat.png"), tag: 1)
        
        let group : GroupVC = GroupVC(nibName:"GroupVC" , bundle : nil)
        group.tabBarItem = UITabBarItem(title: "Group", image:UIImage(named: "two-users (1).png"), tag: 2)
        
       
        let contacts : ContactVC = ContactVC(nibName:"ContactVC" , bundle : nil)
        contacts.fromInbox = false
       
        contacts.tabBarItem = UITabBarItem(title: "Contact", image:UIImage(named: "list.png"), tag: 3)
        
        let profile : ProfileVC = ProfileVC(nibName:"ProfileVC" , bundle : nil)
        profile.tabBarItem = UITabBarItem(title: "Profile", image:UIImage(named: "user (2).png"), tag: 4)
        
        let viewcontrollers = [inbox,group,contacts,profile]
        tabBarController.viewControllers = viewcontrollers
        
        navController = UINavigationController(rootViewController: tabBarController)
        navController?.navigationBar.isTranslucent = true
        navController?.isNavigationBarHidden = true
        window?.rootViewController = navController
        
        //            let navigationController = UINavigationController(rootViewController: page)
        //            navigationController.navigationBar.isTranslucent = true
        //            navigationController.isNavigationBarHidden = true
        //            self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
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
                
                self.observeCalls(ref: myConnectionRef)
//                let vc = InboxViewController(nibName: "InboxViewController", bundle: nil)
//                
//                self.navigationController?.pushViewController(vc, animated: true)
                
            }
            
        }, withCancel: nil)
        
        
        
    }

    func observeCalls(ref: FIRDatabaseReference) {
        
        ref.child("Calling").observe(.childAdded, with: { (snapshot) in
            
            print("calling ref found this \(snapshot)")
            print("Caller Id : \(snapshot.key)")
//            if self.alertWindow == nil {
//                
//                let screenBounds = UIScreen.main.bounds
//                self.alertWindow = UIWindow(frame: screenBounds)
//                self.alertWindow?.windowLevel = UIWindowLevelAlert;
//                
//            }
//            
            
            let page = CallingVC(nibName: "CallingVC", bundle: nil)
            
            page.RoomNameToGo = snapshot.key
            page.callRef = ref
            UserDefaults.standard.set(true, forKey: "isIncomingCall")
            UserDefaults.standard.synchronize()
           // page.imcalling = false
//            self.alertWindow?.rootViewController = page;
//            
//            self.alertWindow?.makeKeyAndVisible();
            
            if let rootViewController = UIApplication.topViewController() {
                
                page.view.backgroundColor = UIColor.clear
                rootViewController.navigationController?.definesPresentationContext = true
                page.modalPresentationStyle = UIModalPresentationStyle.currentContext
                rootViewController.navigationController?.present(page, animated: true, completion: nil)
            }
            
        }, withCancel: nil)
        
        ref.child("Calling").observe(.childRemoved, with: { (snapshot) in
            
            print("Call ended \(snapshot)")
            
            if let rootViewController = UIApplication.topViewController() {
                
               rootViewController.dismiss(animated: true, completion: nil)
            }
            
        }, withCancel: nil)
        
    }
    
    
    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return topViewController(base: top)
            } else if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
