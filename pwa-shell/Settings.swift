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
// 9 is MAX
let authOrigins = [ "login.microsoftonline.com", "login.live.com", "account.live.com", "tomayac.github.io", "whatpwacando.today"];


let platformCookie = Cookie(name: "app-platform", value: "ios/ipados")

let displayMode = "fullscreen" //standalone / fullscreen
