# ios-pwa-wrap
Makes possible of publishing PWA to Apple Store like TWA from Google. Firebase cloud messaging are used for Push Notifications.
# Quick start
## Install Pods references
>- Install **CocoaPods** to the system
>- Go to Repo folder and do in terminal ``pod install``
>- Open file **squoosh-app.xcworkspace**
## Generate Firebase keys
>- Go https://console.firebase.google.com/
>- Create new project
>- Generate and download **GoogleService-Info.plist**
>- Copy it to ``/squoosh-app`` folder
## Change Squoosh to your website
> This app was setup to squoosh pwa website just for example. You should change this settings to yours. Don't forget about **WKAppBoundDomains** in **Info.plist**
# JS Features
## Push topic subscribe
```javascript
if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.push) {
  window.iOSPushCapability = true;
}
mobilePushSubscribe = function(topic, eventValue, unsubscribe?) {
  if (window.iOSPushCapability) {
    window.webkit.messageHandlers.push.postMessage(JSON.stringify({
      topic: pushTopic, // topic name to subscribe/unsubscribe
      eventValue, // user object: name, email, id, etc.
      unsubscribe // true/false
    }));
  }
}
```
## Print page dialog
```javascript
if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.print) {
  window.iOSPrintCapability = true;
}
print = function() {
  if (window.iOSPrintCapability)
    window.webkit.messageHandlers.print.postMessage('print');
  else
    window.print();
}
```
***
Distributed as is, no concrete plans for improvements.
