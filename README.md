# ios-pwa-wrap
Makes possible of publishing PWA to Apple Store like TWA from Google. Supports work with push notifications from JS code, handle auth providers by redirect URL, handle external links, print page support, and loading animation. Firebase cloud messaging are used for Push Notifications.

Supports everything that can do Safari (like Location, Media, Share, Pay, and other Web APIs) and more (like Push, Print, and everything you added on top) with native callbacks.

This project has grown from the internal development of [Hostme App](https://www.hostmeapp.com/).

The [iOS part](https://github.com/pwa-builder/pwabuilder-ios) of [PWA Builder](https://www.pwabuilder.com/) project forked this repository as a template and it's should develop faster, so take a look at it first.

# Gallery
| Launch process | Native Push API request | MSAL Auth Redirect |
|---|---|---|
|![Launch process](https://user-images.githubusercontent.com/6115884/111901850-68c73c80-8a4b-11eb-840d-64e80020a034.gif)|![Native Push API request](https://user-images.githubusercontent.com/6115884/113514430-33f0d480-9577-11eb-9fc5-09fda0ee44e6.gif)|<img width="549" alt="Auth Redirect Example" src="https://user-images.githubusercontent.com/6115884/111901222-ab871580-8a47-11eb-9ac9-e5fc877ba1b9.png">|

| Handle Push content in JS | MacOS support |
|-|-|
|<img width="600" alt="Handle Push content in JS" src="https://user-images.githubusercontent.com/6115884/116286284-b5fba400-a797-11eb-8015-cd269915b82c.gif">|<img width="300" alt="MacOS support" src="https://user-images.githubusercontent.com/6115884/138604212-a52cdd41-c365-4509-8153-d817ca0e6136.jpg">|


# Quick start
## Install Pods references
>- Install **CocoaPods** to the system
>- Go to Repo folder and do in terminal ``pod install``
>- Open file **pwa-shell.xcworkspace**
## Generate Firebase keys
>- Go to https://console.firebase.google.com/
>- Create new project
>- Generate and download **GoogleService-Info.plist**
>- Copy it to ``/pwa-shell`` folder
## Generate APNS key
>- Go to https://developer.apple.com/account
>- Under "Certificates, IDs & Profiles", click on "Keys"
>- Click "+"
>- Give your key a name, and enable "Apple Push Notifications service (APNs)"
>- Click continue, then register. Download the .p8 key file.
## Upload the APNS key to firebase
>- Go to https://console.firebase.google.com/
>- Under your project, create an iOS app if you haven't already. Ensure the bundle ID is correct.
>- Go to the iOS app settings
>- Click on the "Cloud messaging" tab
>- Under "Apple app configuration", upload your APNS key.
## Change to your website
> This app was setup to my website just for example. You should change this settings to yours. Don't forget about **WKAppBoundDomains** in **Info.plist**
# JS Features
## Push permission request
```javascript
if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers['push-permission-request']) {
  window.iOSPushCapability = true;
}
pushPermissionRequest = function(){
  if (window.iOSPushCapability)
    window.webkit.messageHandlers['push-permission-request'].postMessage('push-permission-request');
}
window.addEventListener('push-permission-request', (message) => {
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
## Push permission state
```javascript
pushPermissionState = function(){
  window.webkit.messageHandlers['push-permission-state'].postMessage('push-permission-state');
}
window.addEventListener('push-permission-state', (message) => {
  if (message && message.detail){
    switch (message.detail) {
      case 'notDetermined':
        // permission not asked
        break;
      case 'denied':
        // permission denied
        break;
      case 'authorized':
      case 'ephemeral':
      case 'provisional':
        // permission granted
        break;
      case 'unknown':
      default:
        // something wrong
        break;
    }
  }
});
```
## Push notifications handle
```javascript
window.addEventListener('push-notification', (message) => {
    if (message && message.detail) { 
        console.log(message.detail);
        if (message.detail.aps && message.detail.aps.alert)
            alert(`${message.detail.aps.alert.title} ${message.detail.aps.alert.body}`);
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

# HTML Features
## Viewport
> don't forget to use viewport meta tag in your webapp
```html
<meta name="viewport" content="viewport-fit=cover, width=device-width, initial-scale=1.0, shrink-to-fit=no">
```

***
## TO DO:
- More ellegant solution for toolbar and statusbar
