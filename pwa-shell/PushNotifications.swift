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

func returnPermissionState(isGranted: Bool){
    DispatchQueue.main.async(execute: {
        if (isGranted){
            PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission', { detail: 'granted' }))")
        }
        else {
            PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission', { detail: 'denied' }))")
        }
    })
}
func handlePushPermission(webView: WKWebView) {
    UNUserNotificationCenter.current().getNotificationSettings () { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: { (success, error) in
                        if error == nil {
                            if success == true {
                                returnPermissionState(isGranted: true)
                                DispatchQueue.main.async {
                                  UIApplication.shared.registerForRemoteNotifications()
                                }
                            }
                            else {
                                returnPermissionState(isGranted: false)
                            }
                        }
                        else {
                            returnPermissionState(isGranted: false)
                        }
                    }
                )
            case .denied:
                returnPermissionState(isGranted: false)
            case .authorized, .ephemeral, .provisional:
                returnPermissionState(isGranted: true)
            @unknown default:
                return;
            }
        }
}
func sendPushToWebView(userInfo: [AnyHashable: Any]){
    var json = "";
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: userInfo)
        json = String(data: jsonData, encoding: .utf8)!
    } catch {
        print("ERROR: userInfo parsing problem")
        return
    }
    func checkViewAndEvaluate() {
        if (!PWAShell.webView.isHidden && !PWAShell.webView.isLoading ) {
            DispatchQueue.main.async(execute: {
                PWAShell.webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-notification', { detail: \(json) }))")
            })
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkViewAndEvaluate()
            }
        }
    }
    checkViewAndEvaluate()
}
