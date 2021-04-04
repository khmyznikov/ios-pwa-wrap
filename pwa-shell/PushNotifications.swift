//
//  PushNotifications.swift
//  pwa-shell
//
//  Created by Gleb Khmyznikov on 11/23/19.
//  
//

import WebKit
import FirebaseMessaging

class SubscribeMessage {
    var topic  = ""
    var eventValue = ""
    var unsubscribe = false
    struct Keys {
        static var TOPIC = "topic"
        static var UNSUBSCRIBE = "unsubscribe"
        static var EVENTVALUE = "eventValue"
    }
    convenience init(dict: Dictionary<String,Any>) {
        self.init()
        if let topic = dict[Keys.TOPIC] as? String {
            self.topic = topic
        }
        if let unsubscribe = dict[Keys.UNSUBSCRIBE] as? Bool {
            self.unsubscribe = unsubscribe
        }
        if let eventValue = dict[Keys.EVENTVALUE] as? String {
            self.eventValue = eventValue
        }
    }
}

func handleSubscribeTouch(message: WKScriptMessage) {
  // [START subscribe_topic]
    let subscribeMessages = parseSubscribeMessage(message: message)
    if (subscribeMessages.count > 0){
        let _message = subscribeMessages[0]
        if (_message.unsubscribe) {
            Messaging.messaging().unsubscribe(fromTopic: _message.topic) { error in }
        }
        else {
            Messaging.messaging().subscribe(toTopic: _message.topic) { error in }
        }
    }
    

  // [END subscribe_topic]
}

func parseSubscribeMessage(message: WKScriptMessage) -> [SubscribeMessage] {
    var subscribeMessages = [SubscribeMessage]()
    if let objStr = message.body as? String {

        let data: Data = objStr.data(using: .utf8)!
        do {
            let jsObj = try JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))
            if let jsonObjDict = jsObj as? Dictionary<String, Any> {
                let subscribeMessage = SubscribeMessage(dict: jsonObjDict)
                subscribeMessages.append(subscribeMessage)
            } else if let jsonArr = jsObj as? [Dictionary<String, Any>] {
                for jsonObj in jsonArr {
                    let sMessage = SubscribeMessage(dict: jsonObj)
                    subscribeMessages.append(sMessage)
                }
            }
        } catch _ {
            
        }
    }
    return subscribeMessages
}

func returnPermissionState(webView: WKWebView, isGranted: Bool){
    DispatchQueue.main.async(execute: {
        if (isGranted){
            webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission', { detail: 'granted' }))")
        }
        else {
            webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission', { detail: 'denied' }))")
        }
    })
}
func handlePushPermission(webView: WKWebView) {
    let application = UIApplication.shared
    UNUserNotificationCenter.current().getNotificationSettings () { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { (success, error) in
                        if error == nil {
                            if success == true {
                                returnPermissionState(webView: webView, isGranted: true)
                                application.registerForRemoteNotifications()
                            }
                            else {
                                returnPermissionState(webView: webView,isGranted: false)
                            }
                        }
                        else {
                            returnPermissionState(webView: webView, isGranted: false)
                        }
                    }
                )
            case .denied:
                returnPermissionState(webView: webView, isGranted: false)
            case .authorized, .ephemeral, .provisional:
                returnPermissionState(webView: webView, isGranted: true)
            @unknown default:
                return;
            }
        }
}

//    @IBAction func handleLogTokenTouch(_ sender: UIButton) {
//      // [START log_fcm_reg_token]
//      let token = Messaging.messaging().fcmToken
//      print("FCM token: \(token ?? "")")
//      // [END log_fcm_reg_token]
//      self.fcmTokenMessage.text  = "Logged FCM token: \(token ?? "")"
//
//      // [START log_iid_reg_token]
//      InstanceID.instanceID().instanceID { (result, error) in
//        if let error = error {
//          print("Error fetching remote instance ID: \(error)")
//        } else if let result = result {
//          print("Remote instance ID token: \(result.token)")
//          self.instanceIDTokenMessage.text  = "Remote InstanceID token: \(result.token)"
//        }
//      }
//      // [END log_iid_reg_token]
//    }



//    @objc func displayFCMToken(notification: NSNotification){
//      guard let userInfo = notification.userInfo else {return}
//      if let fcmToken = userInfo["token"] as? String {
//        self.fcmTokenMessage.text = "Received FCM token: \(fcmToken)"
//      }
//    }
