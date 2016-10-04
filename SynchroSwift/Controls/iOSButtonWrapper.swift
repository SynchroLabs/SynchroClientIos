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

extension UIButton
{
    func setInsets()
    {
        // For text only buttons we want a little more vertically padding (to ensure viable min height on
        // buttons using the default system font).
        //
        let hPadding = CGFloat(5);
        let vPadding = CGFloat(8);
        contentEdgeInsets = UIEdgeInsets(top: vPadding, left: hPadding, bottom: vPadding, right: hPadding);
    }
    
    func setImageInsets(_ hasText: Bool)
    {
        // If there is an image, we'll set standard padding (overriding the exagerated vertical padding set above)
        // and we'll make some adjustments to put some space between the image and text (assuming we have text), while
        // keeping everything centered.
        //
        let padding = CGFloat(5);
        let spacing = hasText ? CGFloat(5) : 0;
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing, bottom: 0, right: 0);
        contentEdgeInsets = UIEdgeInsets(top: padding, left: padding + spacing/2, bottom: padding, right: padding);
    }
}

class ButtonFontSetter : iOSFontSetter
{
    var _controlWrapper: iOSButtonWrapper;
    var _button: UIButton;
    
    internal init(controlWrapper: iOSButtonWrapper, button: UIButton)
    {
        _controlWrapper = controlWrapper;
        _button = button;
        super.init(font: button.titleLabel!.font);
    }
    
    internal override func setFont(_ font: UIFont)
    {
        _button.titleLabel!.font = font;
        _controlWrapper.sizeToFit();
    }
}

open class iOSButtonWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating button element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let button = UIButton(type: UIButtonType.system);
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

        button.setInsets();
        self.sizeToFit();
        
        processElementProperty(controlSpec, attributeName: "caption", setValue: { (value) in
            button.setTitle(self.toString(value), for: UIControlState());
            self.sizeToFit();
        });

        processElementProperty(controlSpec, attributeName: "icon", setValue: { (value) in
            let img = iOSControlWrapper.loadImageFromIcon(self.toString(value));
            button.setImage(img, for: UIControlState());
            button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            button.setImageInsets(controlSpec["caption"] != nil);
            self.sizeToFit();
        });

        processElementProperty(controlSpec, attributeName: "color", altAttributeName: "foreground", setValue: { (value) in
            // I think tintColor does what we want (it's still affected by the enabled/disabled state - it doesn't look
            // exactly like other disabled text, but it looks disabled-ish).  Most importantly, it affects the image
            // and title in the same way.
            //
            button.tintColor = self.toColor(value);
            
            // Old solution:
            //
            // let disabledColor = button.titleColorForState(.Disabled);
            // button.setTitleColor(self.toColor(value), forState: .Normal);
            // button.setTitleColor(disabledColor, forState: .Disabled);
        });

        processFontAttribute(controlSpec, fontSetter: ButtonFontSetter(controlWrapper: self, button: button));

        processElementProperty(controlSpec, attributeName: "cornerRadius", setValue: { (value) in
            button.layer.cornerRadius = CGFloat(self.toDeviceUnits(value!));
        });
        
        processElementProperty(controlSpec, attributeName: "resource", setValue: { (value) in
            if ((value == nil) || (value!.asString() == ""))
            {
                button.setImage(nil, for: UIControlState());
            }
            else
            {
                let url = URL(string: self.toString(value));
                if let validUrl = url
                {
                    logger.info("Loading image for URL: \(validUrl)");
                    let request: URLRequest = URLRequest(url: validUrl);
                    NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: {(response: URLResponse?, data: Data?, error: Error?) -> Void in
                        if let err = error
                        {
                            logger.error("Failed to load image, reason: \(err.localizedDescription)");
                            return;
                        }
                        
                        if (response != nil)
                        {
                            let httpResponse = response as! HTTPURLResponse
                            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
                            {
                                logger.info("Image loaded from URL: \(validUrl)");
                                let loadedImage = UIImage(data: data!);
                                button.setBackgroundImage(loadedImage, for: UIControlState());
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
            button.addTarget(self, action: #selector(pressed), for: .touchUpInside);
        }
    }

    func pressed(_ sender: UIButton!)
    {
        logger.info("Title insets: \(sender.titleEdgeInsets)");
        logger.info("Content insets: \(sender.contentEdgeInsets)");

        if let command = getCommand(CommandName.OnClick)
        {
            logger.debug("Button click with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
        }
    }
}
