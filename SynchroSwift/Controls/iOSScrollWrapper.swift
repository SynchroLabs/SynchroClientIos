//
//  iOSScrollWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSScrollWrapper");

class AutoSizingScrollView : UIScrollView
{
    var _controlWrapper: iOSControlWrapper;
    var _orientation: Orientation;
    
    init(controlWrapper: iOSControlWrapper , orientation: Orientation)
    {
        _controlWrapper = controlWrapper;
        _orientation = orientation;
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func layoutSubviews()
    {
        // this.Superview
        if (!self.dragging && !self.decelerating)
        {
            logger.debug("Laying out sub view");
        
            var size = CGSize(width: self.contentSize.width, height: self.contentSize.height);
            for view in self.subviews
            {
                if let childView = view as? UIView
                {
                    var childControlWrapper = _controlWrapper.getChildControlWrapper(childView);
                    if (childControlWrapper != nil)
                    {
                        var childFrame = childView.frame;
            
                        if (_orientation == Orientation.Vertical)
                        {
                            // Vertical scroll, child width is FillParent
                            //
                            if (childControlWrapper!.frameProperties.widthSpec == SizeSpec.FillParent)
                            {
                                childFrame.width = self.frame.width;
                            }
            
                            // Vertical scroll, size scroll area to content height
                            //
                            if ((childView.frame.y + childView.frame.height) > size.height)
                            {
                                size.height = childView.frame.y + childView.frame.height;
                            }
                        }
                        else
                        {
                            // Horizontal scroll, child height is FillParent
                            //
                            if (childControlWrapper!.frameProperties.heightSpec == SizeSpec.FillParent)
                            {
                                childFrame.height = self.frame.height;
                            }
            
                            // Horizontal scroll, size scroll area to content width
                            //
                            if ((childView.frame.x + childView.frame.width) > size.width)
                            {
                                size.width = childView.frame.x + childView.frame.width;
                            }
                        }
            
                        childView.frame = childFrame;
                    }
                    else
                    {
                        // In iOS 7.0+ the os puts a couple of it's own subviews into an auto-sizing
                        // scroll view.  We can safely ignore these.
                        //
                        logger.debug("Found subview that was not Synchro control: \(view)");
                    }
                }
            }
            self.contentSize = size;
        }
        
        super.layoutSubviews();
    }
}

public class iOSScrollWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating scroll element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        var orientation = self.toOrientation(controlSpec["orientation"], defaultOrientation: Orientation.Vertical);
        
        // https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/UIScrollView_pg/Introduction/Introduction.html
        //
        var scroller = AutoSizingScrollView(controlWrapper: self, orientation: orientation);
        self._control = scroller;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(scroller);
        
        if let contentsArray = controlSpec["contents"]? as? JArray
        {
            createControls(controlList: contentsArray, { (childControlSpec, childControlWrapper) in
                if let control = childControlWrapper.control
                {
                    scroller.addSubview(control);
                }
            });
        }
    }
}
