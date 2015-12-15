//
//  iOSWebViewWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSWebViewWrapper");

public class iOSWebViewWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating webview element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let webView = UIWebView();
        self._control = webView;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(webView);
        
        // !!! TODO - iOS Web View
        processElementProperty(controlSpec, attributeName: "contents", setValue: { (value) in webView.loadHTMLString(self.toString(value), baseURL: nil); });
        processElementProperty(controlSpec, attributeName: "url", setValue: { (value) in
            if let url = NSURL(string: self.toString(value))
            {
                webView.loadRequest(NSURLRequest(URL: url));
            }
        });

    }
}

