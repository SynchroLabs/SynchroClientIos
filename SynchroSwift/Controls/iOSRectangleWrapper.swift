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

private var commands = [CommandName.OnTap.Attribute];

public class iOSRectangleWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating rectangle element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let rect = UIView();
        self._control = rect;
        
        rect.layer.masksToBounds = true; // So that fill color will stay inside of border (if any)
        
        processElementDimensions(controlSpec, defaultWidth: 128, defaultHeight: 128);
        applyFrameworkElementDefaults(rect);
        
        processElementProperty(controlSpec, attributeName: "border", setValue: { (value) in rect.layer.borderColor = self.toColor(value)?.CGColor });
        processElementProperty(controlSpec, attributeName: "borderThickness", setValue: { (value) in
            if let theValue = value
            {
                rect.layer.borderWidth = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: "cornerRadius", setValue: { (value) in
            if let theValue = value
            {
                rect.layer.cornerRadius = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        
        processElementProperty(controlSpec, attributeName: "fill", setValue: { (value) in rect.backgroundColor = self.toColor(value) });
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnTap.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
        
        if (getCommand(CommandName.OnTap) != nil)
        {
            let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("imageTapped:"))
            rect.userInteractionEnabled = true
            rect.addGestureRecognizer(tapGestureRecognizer)
        }
        
        logger.debug("Rectangle created, size: \(rect.frame.size)");
    }
    
    func imageTapped(img: AnyObject)
    {
        if let command = getCommand(CommandName.OnTap)
        {
            logger.debug("Rectangle tap with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
        }
    }

}
