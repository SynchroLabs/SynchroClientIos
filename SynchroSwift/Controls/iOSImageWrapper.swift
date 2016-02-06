//
//  iOSImageWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSImageWrapper");

private var commands = [CommandName.OnTap.Attribute];

public class iOSImageWrapper : iOSControlWrapper
{
    public func toImageContentMode(value: JToken?, defaultMode: UIViewContentMode = UIViewContentMode.ScaleAspectFit) ->  UIViewContentMode
    {
        var mode = defaultMode;
        let modeValue = value?.asString();
        if (modeValue == "Stretch")
        {
            mode = UIViewContentMode.ScaleToFill;
        }
        else if (modeValue == "Fit")
        {
            mode = UIViewContentMode.ScaleAspectFit;
        }
        else if (modeValue == "Fill")
        {
            mode = UIViewContentMode.ScaleAspectFill;
        }
        return mode;
    }
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating image element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let image = UIImageView();
        image.clipsToBounds = true;
        image.contentMode = UIViewContentMode.ScaleAspectFit; // default
        
        self._control = image;
        
        // Image scaling
        //
        // image.ContentMode = UIViewContentMode.ScaleToFill;     // Stretch to fill
        // image.ContentMode = UIViewContentMode.ScaleAspectFit;  // Fit preserving aspect
        // image.ContentMode = UIViewContentMode.ScaleAspectFill; // Fill preserving aspect
        //
        // Note: When using fit or fill there is no built-in way to control the position/alignment of the image within the view (it is always centered).
        //       This could be accomplished by putting the UIImageView inside of another view and sizing / locating within that view based on desired
        //       content alignment, but that's more complexity than it's worth.
        //
        processElementProperty(controlSpec, attributeName: "scale", setValue: { (value) in
            image.contentMode = self.toImageContentMode(value);
            
            // There is some scaling state maintained on changing the contentMode that can only be reset by resetting the image (after updating the content mode)
            //
            let theImage = image.image;
            image.image = nil;
            image.image = theImage;
        });
        
        processElementDimensions(controlSpec, defaultWidth: 128, defaultHeight: 128);
        applyFrameworkElementDefaults(image);
        processElementProperty(controlSpec, attributeName: "resource", setValue: { (value) in
            if ((value == nil) || (value!.asString() == ""))
            {
                image.image = nil;
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
                                let loadedImage = UIImage(data: data!)
                                image.image = loadedImage;

                                logger.info("Image size - height: \(image.image?.size.height), width: \(image.image?.size.width)");
                                
                                if ((self.frameProperties.heightSpec != SizeSpec.WrapContent) && (self.frameProperties.widthSpec == SizeSpec.WrapContent))
                                {
                                    // Only height specified, set width based on image aspect
                                    //
                                    var frame = image.frame;
                                    var size = frame.size;
                                    
                                    size.width = loadedImage!.size.width / loadedImage!.size.height * size.height;
                                    
                                    frame.size = size;
                                    image.frame = frame;
                                    if (image.superview != nil)
                                    {
                                        image.superview!.setNeedsLayout();
                                    }
                                }
                                else if ((self.frameProperties.widthSpec != SizeSpec.WrapContent) && (self.frameProperties.heightSpec == SizeSpec.WrapContent))
                                {
                                    // Only width specified, set height based on image aspect
                                    //
                                    var frame = image.frame;
                                    var size = frame.size;
                                    
                                    size.height = loadedImage!.size.height / loadedImage!.size.width * size.width;
                                    
                                    frame.size = size;
                                    image.frame = frame;
                                    if (image.superview != nil)
                                    {
                                        image.superview!.setNeedsLayout();
                                    }
                                }
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
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnTap.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
        
        if (getCommand(CommandName.OnTap) != nil)
        {
            let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:Selector("imageTapped:"))
            image.userInteractionEnabled = true
            image.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func imageTapped(img: AnyObject)
    {
        if let command = getCommand(CommandName.OnTap)
        {
            logger.debug("Image tap with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
        }
    }
}
