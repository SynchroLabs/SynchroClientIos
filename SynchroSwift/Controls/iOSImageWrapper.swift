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

public class iOSImageWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating image element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        var image = UIImageView();
        self._control = image;
        
        // !!! Image scaling
        //
        // image.ContentMode = UIViewContentMode.ScaleToFill;     // Stretch to fill
        // image.ContentMode = UIViewContentMode.ScaleAspectFit;  // Fit preserving aspect
        // image.ContentMode = UIViewContentMode.ScaleAspectFill; // Fill preserving aspect
        
        processElementDimensions(controlSpec, defaultWidth: 128, defaultHeight: 128);
        applyFrameworkElementDefaults(image);
        processElementProperty(controlSpec["resource"], setValue: { (value) in
            if ((value == nil) || (value!.asString() == ""))
            {
                image.image = nil;
            }
            else
            {
                var url = NSURL(string: self.toString(value));
                if let validUrl = url
                {
                    logger.info("Loading image for URL: \(validUrl)");
                    var request: NSURLRequest = NSURLRequest(URL: validUrl);
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                        let httpResponse = response as! NSHTTPURLResponse;
                        if let err = error
                        {
                            logger.error("Failed to load image, reason: \(err.description)");
                        }
                        else if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300)
                        {
                            logger.info("Image loaded from URL: \(validUrl)");
                            var loadedImage = UIImage(data: data)
                            image.image = loadedImage;
                        }
                        else
                        {
                            logger.info("Image load failed with http status: \(httpResponse.statusCode) from URL: \(validUrl)");
                        }
                    })
                }
                else
                {
                    logger.error("Invalid URL for image: \(url)");
                }
            }
        });
    }
}
