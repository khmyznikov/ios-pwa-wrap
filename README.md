# ios-pwa-wrap

## [⚠️ Take a look at PWABuilder first ⚠️](https://docs.pwabuilder.com/#/builder/app-store?id=publishing-pwas-to-the-app-store)
## This template is used in [PWABuilder](https://www.pwabuilder.com/) service, and you can get pre-generated customized project for your Web App from there.

Makes possible of publishing PWA to Apple Store (works in EU) like TWA from Google. 

Supports work with push notifications from JS code, handle auth providers by redirect URL, handle external links, print page support, and loading animation. Firebase cloud messaging are used for Push Notifications.

Supports most things you can do in Safari (like Location, Media, Share, Pay, and other Web APIs) and more (like Push, Print, Download and everything you added on top) with native callbacks.

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

>  For **Apple M Silicon:** ([More options here](https://stackoverflow.com/questions/64901180/how-to-run-cocoapods-on-apple-silicon-m1))
   ```
   # Uninstall the local cocoapods gem
   sudo gem uninstall cocoapods
   # Reinstall cocoapods via Homebrew
   brew install cocoapods
   ```
  
>- Go to Repo folder and do in terminal ``pod install``
>- Open file **pwa-shell.xcworkspace**
>- xcode should support iOS15+
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
> This app was setup to my webapp just for example. You should change this settings to yours. 
- **WKAppBoundDomains** in **Info.plist**
- **Settings.swift**
- *URL Types* at Info tab
- *Associated Domains* at *Signing & Capabilities*
- Adjust *Capabilities* at *Signing & Capabilities* (leave only required for your app)



# JS Features
## [Example web app you can find here](https://github.com/khmyznikov/ios-pwa-shell)
## Push events and permissions
[push component sample](https://github.com/khmyznikov/ios-pwa-shell/blob/main/src/components/push.ts)

## Apple In-App Purchase
[iap component sample](https://github.com/khmyznikov/ios-pwa-shell/blob/main/src/components/in-app-purchase.ts)

## Print page, file download, alerts
[common component sample](https://github.com/khmyznikov/ios-pwa-shell/blob/main/src/pages/app-home.ts)


# HTML Features
## Viewport
> don't forget to use viewport meta tag in your webapp
```html
<meta name="viewport" content="viewport-fit=cover, width=device-width, initial-scale=1.0, shrink-to-fit=no">
```

***
## TO DO:
- More ellegant solution for toolbar and statusbar
