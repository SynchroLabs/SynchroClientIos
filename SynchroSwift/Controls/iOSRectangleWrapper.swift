//
//  iOSRectangleWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSRectangleWrapper");

class RectangleView : UIView
{
    var _color: UIColor? = UIColor.clearColor();
    
    init()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    var color: UIColor?
    {
        get { return _color; }
        set(value)
        {
            _color = value;
            self.setNeedsDisplay();
        }
    }
    
    override func drawRect(rect: CGRect)
    {
        super.drawRect(rect);
        
        if let context = UIGraphicsGetCurrentContext()
        {
            if let theColor = _color?.CGColor
            {
                CGContextSetFillColorWithColor(context, theColor);
            }
            CGContextFillRect(context, rect);
        }
    }
}

public class iOSRectangleWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating rectangle element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        var rect = RectangleView();
        self._control = rect;
        
        rect.layer.masksToBounds = true; // So that fill color will stay inside of border (if any)
        
        processElementDimensions(controlSpec, defaultWidth: 128, defaultHeight: 128);
        applyFrameworkElementDefaults(rect);
        
        processElementProperty(controlSpec["border"], setValue: { (value) in rect.layer.borderColor = self.toColor(value)?.CGColor });
        processElementProperty(controlSpec["borderThickness"], setValue: { (value) in
            if let theValue = value
            {
                rect.layer.borderWidth = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec["cornerRadius"], setValue: { (value) in
            if let theValue = value
            {
                rect.layer.cornerRadius = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec["fill"], setValue: { (value) in rect.color = self.toColor(value) });
    }
}
