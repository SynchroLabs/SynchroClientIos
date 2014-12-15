//
//  iOSWebViewWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("iOSWebViewWrapper");

public class iOSWebViewWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating webview element");
        
        // !!! Implement
        
        super.init(parent: parent, bindingContext: bindingContext);
    }
}
