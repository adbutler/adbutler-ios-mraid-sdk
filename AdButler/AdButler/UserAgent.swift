//
//  UserAgent.swift
//  AdButler
//
//  Created by Will Prevett on 2020-10-15.
//  https://stackoverflow.com/questions/8579019/how-to-get-the-user-agent-on-ios
//

import WebKit

class UAString {

    static var userAgent : String = ""

    @discardableResult init(view parent: UIView) {

        if UAString.userAgent.isEmpty {

            let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

            webView.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(webView)

            webView.evaluateJavaScript("navigator.userAgent") { result, _ in
                UAString.userAgent = result as? String ?? ""
            }
        }
    }

}
