//
//  WebViewConfig.swift
//  squoosh-app
//
//  Created by Gleb Khmyznikov on 11/22/19.
//  
//

import UIKit
import WebKit

func createWebView(container: UIView, WKSMH: WKScriptMessageHandler, WKND: WKNavigationDelegate, NSO: NSObject, VC: ViewController) -> WKWebView{
    
    let config = WKWebViewConfiguration()
    let userContentController = WKUserContentController()

    userContentController.add(WKSMH, name: "print")
    userContentController.add(WKSMH, name: "push")
    config.userContentController = userContentController
    
    if #available(iOS 14, *) {
        config.limitsNavigationsToAppBoundDomains = true;
    }
    
    var webView = WKWebView()
    
    setCustomCookie(webView: webView)
    

    let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
    webView = WKWebView(frame: CGRect(x: 0, y: statusBarHeight, width: container.frame.width, height: container.frame.height - statusBarHeight), configuration: config)


    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    webView.isHidden = true;

    webView.navigationDelegate = WKND;

    webView.scrollView.bounces = false;
    webView.allowsBackForwardNavigationGestures = false
    

    webView.scrollView.contentInsetAdjustmentBehavior = .never


    webView.addObserver(NSO, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: NSKeyValueObservingOptions.new, context: nil)
    
    return webView
}

func setCustomCookie(webView: WKWebView) {
    let _platformCookie = HTTPCookie(properties: [
        .domain: rootUrl.host!,
        .path: "/",
        .name: platformCookie.name,
        .value: platformCookie.value,
        .secure: "FALSE",
        .expires: NSDate(timeIntervalSinceNow: 31556926)
    ])!

    webView.configuration.websiteDataStore.httpCookieStore.setCookie(_platformCookie)

}

func createStatusBar(container: UIView) -> UIView {
    let app = UIApplication.shared
    let statusBarHeight: CGFloat = app.statusBarFrame.size.height
          
    let statusBarView = UIView()
    statusBarView.backgroundColor = hexStringToUIColor(hex: statusBarColor)
    container.addSubview(statusBarView)

    statusBarView.translatesAutoresizingMaskIntoConstraints = false
    statusBarView.heightAnchor
      .constraint(equalToConstant: statusBarHeight).isActive = true
    statusBarView.widthAnchor
      .constraint(equalTo: container.widthAnchor, multiplier: 1.0).isActive = true
    statusBarView.topAnchor
      .constraint(equalTo: container.topAnchor).isActive = true
    statusBarView.centerXAnchor
      .constraint(equalTo: container.centerXAnchor).isActive = true
    
    statusBarView.isHidden = true
    
    return statusBarView
}

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

extension ViewController: WKUIDelegate {
    // handle links opening in new tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated {
            if let requestUrl = navigationAction.request.url{
                if let requestHost = requestUrl.host {
                    if (requestHost.range(of: allowedOrigin) != nil ) {
                        decisionHandler(.allow)
                    } else {
                        decisionHandler(.cancel)
                        if (UIApplication.shared.canOpenURL(requestUrl)) {
                            UIApplication.shared.open(requestUrl)
                        }
                    }
                } else {
                    if (navigationAction.request.url?.scheme == "tel" || navigationAction.request.url?.scheme == "mailto" ){
                        decisionHandler(.cancel)
                        if (UIApplication.shared.canOpenURL(requestUrl)) {
                            UIApplication.shared.open(requestUrl)
                        }
                    }
                    else {
                        decisionHandler(.allow)
                    }
                }
            }
        }
        else {
            decisionHandler(.allow)
        }
    }
}
