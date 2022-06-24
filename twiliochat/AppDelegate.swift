import UIKit
import UserNotifications
import SlackTextViewController

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var devToken: String?
    var environment: APNSEnvironment?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10, *) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                })
            } else {
                let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
                UIApplication.shared.registerForRemoteNotifications()
            }
        
        
        self.environment = ProvisioningProfileInspector().apnsEnvironment()
            var envString = "Unknown"
            if environment != APNSEnvironment.unknown {
                if environment == APNSEnvironment.development {
                    envString = "Development"
                } else {
                    envString = "Production"
                }
            }
            print("APNS Environment detected as: \(envString) ");

        
        MessagingManager.sharedManager().presentLaunchScreen()
        MessagingManager.sharedManager().presentRootViewController()
        
       
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        for i in 0..<deviceToken.count {
          tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        print("Received token data! \(tokenString)")
        devToken = tokenString
      }
      
      func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Couldn't register: \(error)")
      }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        
        
        let title = userInfo[AnyHashable("title")] as? String
        let type = userInfo[AnyHashable("type")] as? String
        
        if let aps = userInfo[AnyHashable("aps")] as? [AnyHashable: Any] {
            
            //Alert was inaccesable due to type mismatch
            if let alert = aps[AnyHashable("alert")] as? [AnyHashable: Any] {

                //Alert body parsed seperatly
                let body = alert[AnyHashable("body")] as? String
                
                
                switch type {
                    case "confirmation":
                        //Accept or Decline a message
                        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
                        let AcceptAction = UIAlertAction(title: "Accept", style: .default, handler: {(_) in
                            //send something back to dispatch
                        })
                        let DeclineAction = UIAlertAction(title: "Decline", style: .default, handler: {(_) in
                            //create new chat window with dispatch
                            
                            let channelName = "Placeholder"

                            ChannelManager.sharedManager.createChannelWithName(name: channelName, completion: { _,_ in
                            ChannelManager.sharedManager.populateChannelDescriptors()
                            ChannelManager.sharedManager.joinGeneralChatRoomWithUniqueName(name: channelName, completion: {result in

                                print("Joined ", channelName)
                            
                            })
                            })
                        })
                        
                        alertController.addAction(AcceptAction)
                        alertController.addAction(DeclineAction)
                        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                        
                    case "alert":
                        //Alert Type Message (dismiss with a button)
                        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
                        let AcceptAction = UIAlertAction(title: "Accept", style: .default, handler: nil)
                        
                        alertController.addAction(AcceptAction)
                        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                
                    case "broadcast":
                        //Broadcast Type Message (dismiss with a button)
                        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
                        let AcceptAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                        
                        alertController.addAction(AcceptAction)
                        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                    
                    case "URL":
                        //Broadcast URL Type Message (dismiss with a button)
                        let alertController = UIAlertController(title: title, message: body, preferredStyle: .actionSheet)
                        let AcceptURL = UIAlertAction(title: "Go to URL", style: .default, handler: {(_) in
                            let url = URL(string: body!)!
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                //If you want handle the completion block than
                                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                                     print("Open url : \(success)")
                                })
                            }
                        })
                    
                        let DismissMsg = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                    
                        alertController.addAction(AcceptURL)
                        alertController.addAction(DismissMsg)
                        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                    
                default:
                        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
                        let AcceptAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                        
                        alertController.addAction(AcceptAction)
                        self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                }
                
                //Switch state different types (URL, Map (Lat, long), Image, Text update (news), Text Confirmation (Accept, Decline)
                //Add actions to the alert controller and build it at the end of the switch statement
                //display the window
                /*
                let alertController = UIAlertController(title: "Incoming Notification", message: body, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "Accept", style: .default, handler: nil)
                let customAction = UIAlertAction(title: "Decline", style: .default, handler: nil)
                
                alertController.addAction(defaultAction)
                alertController.addAction(customAction)
                */
                //self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                 
            }
        }
      }
}

