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
let allowedOrigin = "www.khmyznikov.com"
let authOrigin_1 = "login.microsoftonline.com"
let authOrigin_2 = "login.live.com"



let platformCookie = Cookie(name: "app-platform", value: "ios/ipados")


//let statusBarColor = "#FFFFFF"
//let statusBarStyle = UIStatusBarStyle.lightContent
