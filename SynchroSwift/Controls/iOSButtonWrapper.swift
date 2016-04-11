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


class LessSuckingButton : UIButton
{
    // UIButton does not account for title insets in size calc...
    //
    internal override func sizeThatFits(size: CGSize) -> CGSize
    {
        let theSize = super.sizeThatFits(size);
        
        let adjustedWidth = theSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight = theSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        
        return CGSize(width: adjustedWidth, height: adjustedHeight);
    }
}

public class iOSButtonWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating button element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let button = LessSuckingButton(type: UIButtonType.System);
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
        
        processElementProperty(controlSpec, attributeName: "caption", setValue: { (value) in
            // Add some edge insets to give spacing to the left/right of the text
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0 ,right: 5);
            button.setTitle(self.toString(value), forState: .Normal);
            self.sizeToFit();
        });

        processElementProperty(controlSpec, attributeName: "foreground", setValue: { (value) in
            button.setTitleColor(self.toColor(value), forState: .Normal);
        });

        processElementProperty(controlSpec, attributeName: "foregroundDisabled", setValue: { (value) in
            button.setTitleColor(self.toColor(value), forState: .Disabled);
        });

        processElementProperty(controlSpec, attributeName: "cornerRadius", setValue: { (value) in
            button.layer.cornerRadius = CGFloat(self.toDeviceUnits(value!));
        });

        processElementProperty(controlSpec, attributeName: "resource", setValue: { (value) in
            if ((value == nil) || (value!.asString() == ""))
            {
                button.setImage(nil, forState: UIControlState.Normal);
            }
            else
            {
                let url = NSURL(string: self.toString(value));
                if let validUrl = url
                {
                    logger.info("Loading image for URL: \(validUrl)");
                    let request: NSURLRequest = NSURLRequest(URL: validUrl);
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        if let err = error
                        {
                            logger.error("Failed to load image, reason: \(err.description)");
                            return;
                        }
                        
                        if (response != nil)
                        {
                            let httpResponse = response as! NSHTTPURLResponse
                            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
                            {
                                logger.info("Image loaded from URL: \(validUrl)");
                                let loadedImage = UIImage(data: data!);
                                button.setBackgroundImage(loadedImage, forState: UIControlState.Normal);
                            }
                            else
                            {
                                logger.info("Image load failed with http status: \(httpResponse.statusCode) from URL: \(validUrl)");
                            }
                        }
                        else
                        {
                            logger.error("Image load failed without returning error or response (should be impossible)");
                        }
                    })
                }
                else
                {
                    logger.error("Invalid URL for image: \(url)");
                }
            }
        });

                
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnClick.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
        
        if (getCommand(CommandName.OnClick) != nil)
        {
            button.addTarget(self, action: #selector(pressed), forControlEvents: .TouchUpInside);
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
