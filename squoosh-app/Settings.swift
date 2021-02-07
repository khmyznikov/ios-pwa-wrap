//
//  Settings.swift
//  squoosh-app
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

let rootUrl = URL(string: "https://squoosh.app")!
let allowedOrigin = "squoosh.app"


let platformCookie = Cookie(name: "app-platform", value: "ios/ipados")


let statusBarColor = "#FF3399"
let statusBarStyle = UIStatusBarStyle.lightContent
