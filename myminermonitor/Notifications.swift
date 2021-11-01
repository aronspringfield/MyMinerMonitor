//
//  Notifications.swift
//  myminermonitor
//
//  Created by Aron Springfield on 11/04/2018.
//  Copyright © 2018 Aron Springfield. All rights reserved.
//

import UIKit
import UserNotifications

class Notifications: NSObject, UNUserNotificationCenterDelegate {

    static var shared: Notifications = {
        let pn = Notifications()
        UNUserNotificationCenter.current().delegate = pn
        return pn
    }()
    
    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func onPermissionGranted(_ completionHandler: @escaping (Bool) -> ()) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                self.requestPermission(completionHandler)
            } else {
                DispatchQueue.main.async {
                    completionHandler(true)
                }
            }
        }
    }
    
    func requestPermissionIfRequired() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                self.requestPermission()
            }
        }
    }
    
    private func requestPermission(_ completionHandler: ((Bool) -> ())? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in
            DispatchQueue.main.async {
                completionHandler?(granted)
            }
            if let error = error {
                NSLog("Uhoh. ERROR! \(error)")
            }
        }
    }
    
    // MARK: - Delegate Methods
    
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented.
    // The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction.
    // The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        // let userInfo = response.notification.request.content.userInfo
        // TODO: Navigate to correct wallet from here
    }
    
    // MARK: - Class Methods
    
    class func promptUserToEnableNotificationsAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Permission Denied", message: "Notifications have not been enabled for this app to use this feature.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Goto Settings", style: .default, handler: { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }))
        return alert
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
