# ios-pwa-wrap
Makes possible of publishing PWA to Apple Store like TWA from Google. Firebase cloud messaging are used for Push Notifications.
# Gallery
| Launch process | Native Push API request | MSAL Auth Redirect |
|---|---|---|
|![Launch process](https://user-images.githubusercontent.com/6115884/111901850-68c73c80-8a4b-11eb-840d-64e80020a034.gif)|![Native Push API request](https://user-images.githubusercontent.com/6115884/113514430-33f0d480-9577-11eb-9fc5-09fda0ee44e6.gif)|<img width="549" alt="Auth Redirect Example" src="https://user-images.githubusercontent.com/6115884/111901222-ab871580-8a47-11eb-9ac9-e5fc877ba1b9.png">|


# Quick start
## Install Pods references
>- Install **CocoaPods** to the system
>- Go to Repo folder and do in terminal ``pod install``
>- Open file **pwa-shell.xcworkspace**
## Generate Firebase keys
>- Go https://console.firebase.google.com/
>- Create new project
>- Generate and download **GoogleService-Info.plist**
>- Copy it to ``/pwa-shell`` folder
## Change to your website
> This app was setup to my website just for example. You should change this settings to yours. Don't forget about **WKAppBoundDomains** in **Info.plist**
# JS Features
## Push permission request
```javascript
if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers['push-permission']) {
  window.iOSPushCapability = true;
}
pushRequest = function(){
  if (window.iOSPushCapability)
    window.webkit.messageHandlers['push-permission'].postMessage('push-permission');
}
window.addEventListener('push-permission', (message) => {
  if (message && message.detail){
    switch (message.detail) {
      case 'granted':
        // permission granted
        break;
      default:
        // permission denied
        break;
    }
  }
});
```
## Push topic subscribe
```javascript
if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers['push-subscribe']) {
  window.iOSPushCapability = true;
}
mobilePushSubscribe = function(topic, eventValue, unsubscribe?) {
  if (window.iOSPushCapability) {
    window.webkit.messageHandlers['push-subscribe'].postMessage(JSON.stringify({
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
printView = function() {
  if (window.iOSPrintCapability)
    window.webkit.messageHandlers.print.postMessage('print');
  else
    window.print();
}
```

***
## TO DO:
- More ellegant solution for toolbar and statusbar
