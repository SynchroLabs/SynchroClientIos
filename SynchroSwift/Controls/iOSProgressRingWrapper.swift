//
//  iOSProgressRingWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSProgressRingWrapper");

open class iOSProgressRingWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating progress ring element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let progress = UIActivityIndicatorView();
        progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray;
        
        self._control = progress;
        
        processElementDimensions(controlSpec); // Size to system default for control (if implicit)
        
        applyFrameworkElementDefaults(progress);
        
        processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in
            let animate = self.toBoolean(value);
            let isAnimating = progress.isAnimating;
            if (animate && !isAnimating)
            {
                progress.startAnimating();
            }
            else if (!animate && isAnimating)
            {
                progress.stopAnimating();
            }
        });
    }
}
