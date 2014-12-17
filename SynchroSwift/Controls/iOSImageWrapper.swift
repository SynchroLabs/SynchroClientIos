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
            if (value.asString() == "")
            {
                image.image = nil;
            }
            else
            {
                // !!! This really needs to be async, and it needs to verify that the NSURL was propertly formed, and it needs to 
                //     handle errors...
                //
                var imageData: NSData = NSData(contentsOfURL: NSURL(string: self.toString(value))!, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)!;
                image.image = UIImage(data:imageData);
            }
        });
    }
}
