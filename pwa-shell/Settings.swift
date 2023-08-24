//
//  Settings.swift
//  pwa-shell
//
//  Created by Gleb Khmyznikov on 11/23/19.
//  
//

import WebKit

struct Cookie {
    var name: String
    var value: String
}

let gcmMessageIDKey = "87336923954"

let rootUrl = URL(string: "https://www.khmyznikov.com/ms-auth-test/")!

// rootUrl should be in allowedOrigins. allowedOrigins + authOrigins <= 10 domains max.
// All domains should be in WKAppBoundDomains list
let allowedOrigins = [ "www.khmyznikov.com" ]
let authOrigins = [ "login.microsoftonline.com", "login.live.com", "account.live.com", "tomayac.github.io", "whatpwacando.today"]


let platformCookie = Cookie(name: "app-platform", value: "ios/ipados")

// UI options
let displayMode = "fullscreen" // standalone / fullscreen.
let adaptiveUIStyle = true     // iOS 15+ only. Change app theme on the fly to dark/light related to WebView background color.
let overrideStatusBar = false   // iOS 13-14 only. if you don't support dark/light system theme.
let statusBarTheme = "dark"    // dark / light, related to override option.
let pullToRefresh = true    // Enable/disable pull down to refresh page
