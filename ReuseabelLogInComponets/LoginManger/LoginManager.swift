//
//  LoginManager.swift
//  ReuseabelLogInComponets
//
//  Created by Sumit Goswami on 09/03/18.
//  Copyright © 2018 SimformSolutions. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit


class LoginManager: NSObject {
    
    
    struct Static {
        static let instance = LoginManager()
    }
    
    class var shared: LoginManager {
        return Static.instance
    }
    
    let facebookManger = FBSDKLoginManager()
    
    func facebookConfiguration(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?)  {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func facebookUrlConfiguration(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func loginWithFacebook(permission:[ReadPermissions]? = nil,requriedFields:[NeededFields]? = nil,controller:UIViewController,_ loginCompletion:@escaping (FBSDKAccessToken?, NSError?)->(),_ userDatacompletion:@escaping(AnyObject?, NSError?)->Void)  {
        
        facebookManger.logIn(withReadPermissions:getReadPermission(readPermission: permission), from: controller) { (result, error) in
            if let unwrappedError = error {
                self.facebookManger.logOut()
                loginCompletion(nil,unwrappedError as NSError?)
            } else if (result?.isCancelled)! {
                self.facebookManger.logOut()
                loginCompletion(nil,nil)
            } else {
                guard let uResult = result else {
                    loginCompletion(nil,Error.facebookNoResult)
                    return
                }
                if uResult.declinedPermissions.count == 0 {
                    if let _ = uResult.token.tokenString {
                        FBSDKGraphRequest.init(graphPath: "me", parameters:["fields":self.getNeededFields(requiredPermission: requriedFields)] ).start(completionHandler: { (connection, response, meError) in
                            if let unwrappedMeError = meError {
                                userDatacompletion(nil,unwrappedMeError as NSError?)
                            }else{
                                if requriedFields == nil {
                                  userDatacompletion(self.parseUserData(dataResponse: response as AnyObject),nil)
                                  return
                                }
                                userDatacompletion(response as AnyObject?,nil)
                            }
                        })
                    }
                    loginCompletion(uResult.token, nil)
                } else {
                    self.showPopUp(viewController: controller)
                    loginCompletion(uResult.token, nil)
                }
            }
        }
    }
    
    private func getReadPermission(readPermission:[ReadPermissions]?) -> [String] {
        var permissionString:[String] = [String]()
        if readPermission == nil {
           return FacebookConstante.readPermissions
        } else {
            for value in readPermission! {
                permissionString.append(value.rawValue)
            }
        }
        return permissionString
    }
    
    private func getNeededFields(requiredPermission:[NeededFields]?) -> String {
        var permissionString:String = ""
        if requiredPermission == nil {
            return FacebookConstante.neededFields
        } else {
            for value in requiredPermission! {
                permissionString.append(value.rawValue)
                if value.rawValue != requiredPermission?.last?.rawValue {
                    permissionString.append(",")
                }
            }
        }
        return permissionString
    }
    
    private func showPopUp(viewController:UIViewController) {
        let alert = UIAlertController(title: "Permissions Declined", message: "please give all permissions needed to sigup user", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func parseUserData(dataResponse:AnyObject) -> UserData {
        let userData = UserData()
        
        if let about = dataResponse.object(forKey: NeededFields.about.rawValue) as? String {
           userData.about = about
        }
        if let birthday = dataResponse.object(forKey: NeededFields.birthday.rawValue) as? String {
           userData.birthday = birthday
        }
        if let email = dataResponse.object(forKey: NeededFields.email.rawValue) as? String {
           userData.email = email
        }
        if let firstName = dataResponse.object(forKey: NeededFields.firstName.rawValue) as? String {
           userData.firstName = firstName
        }
        if let lastName = dataResponse.object(forKey: NeededFields.lastName.rawValue) as? String {
           userData.lastName = lastName
        }
        if let gender = dataResponse.object(forKey: NeededFields.gender.rawValue) as? String {
           userData.gender = gender
        }
        if let name = dataResponse.object(forKey: NeededFields.name.rawValue) as? String {
           userData.name = name
        }
        if let id = dataResponse.object(forKey: NeededFields.id.rawValue) as? String {
           userData.id = id
        }

        return userData
    }
    
}



extension AppDelegate {
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
      return  LoginManager.shared.facebookUrlConfiguration(application, open: url, sourceApplication: sourceApplication,   annotation: annotation)
    }
}


