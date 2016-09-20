//
//  iOSCanvasWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSCanvasWrapper");

open class iOSCanvasWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating canvas element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let canvas = UIView();
        self._control = canvas;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(canvas);
        
        if let contents = controlSpec["contents"] as? JArray
        {
            createControls(controlList: contents, onCreateControl: { (childControlSpec, childControlWrapper) in
                childControlWrapper.processElementProperty(childControlSpec, attributeName: "left", setValue: { (value) in
                    if let theValue = value
                    {
                        var childFrame = childControlWrapper.control!.frame;
                        childFrame.x = CGFloat(self.toDeviceUnits(theValue));
                        childControlWrapper.control!.frame = childFrame;
                        // !!! Resize canvas to contain control
                    }
                });
                childControlWrapper.processElementProperty(childControlSpec, attributeName: "top", setValue: { (value) in
                    if let theValue = value
                    {
                        var childFrame = childControlWrapper.control!.frame;
                        childFrame.y = CGFloat(self.toDeviceUnits(theValue));
                        childControlWrapper.control!.frame = childFrame;
                        // !!! Resize canvas to contain control
                    }
                });
                
                canvas.addSubview(childControlWrapper.control!);
            });
        }

    }
}
