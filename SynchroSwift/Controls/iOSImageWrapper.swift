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
    /*
     * !!! This didn't really port.  Not sure we need it, but should verify...
     *
    private class func createNSUrl(uri: Uri) -> NSUrl
    {
        return NSUrl(uri.GetComponents(UriComponents.HttpRequestUrl, UriFormat.UriEscaped));
    }
    */

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
        processElementProperty(controlSpec["resource"], { (value) in
            if ((value == nil) || (value!.asString() == ""))
            {
                image.image = nil;
            }
            else
            {
                var url = NSURL(string: self.toString(value));
                if let validUrl = url
                {
                    var request: NSURLRequest = NSURLRequest(URL: validUrl);
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                        if let err = error
                        {
                            logger.error("Failed to load image, reason: \(err.description)");
                        }
                        else
                        {
                            var loadedImage = UIImage(data: data)
                            image.image = loadedImage;
                        }
                    })

                }
            }
        });
    }
}
