//
//  iOSButtonWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSButtonWrapper");

private var commands = [CommandName.OnClick.Attribute];

public class iOSButtonWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating button element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        let button = UIButton(type: UIButtonType.System);
        self._control = button;
        
        // For an image button (seems mutually exclusive the system/text button)...
        //
        //     let button = UIButton(type: UIButtonType.Custom);
        //     button.imageView!.contentMode = .ScaleAspectFit;
        //
        // Then load the image and set it using:
        //
        //     button.setImage(loadedImage, forState: .Normal);
        //
        // And if you want to size the button the the image (with insets, presumably), you can do that when setting the image also.
        //
        
        processElementDimensions(controlSpec);
        applyFrameworkElementDefaults(button);
        
        processElementProperty(controlSpec["caption"], setValue: { (value) in
            button.setTitle(self.toString(value), forState: .Normal);
            self.sizeToFit();
        });
                
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnClick.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
        
        if (getCommand(CommandName.OnClick) != nil)
        {
            button.addTarget(self, action: "pressed:", forControlEvents: .TouchUpInside);
        }
    }

    func pressed(sender: UIButton!)
    {
        if let command = getCommand(CommandName.OnClick)
        {
            logger.debug("Button click with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
        }
    }
}
