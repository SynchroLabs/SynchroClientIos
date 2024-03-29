//
//  iOSStackPanelWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSStackPanelWrapper");

// "Star space" is the term used to refer to the allocation of "extra" space based on star heights
// or widths (for example, a width of "2*" means the element wants a 2x pro-rata allocation of
// any extra space available).
//
// By managing the total available star space, and returning to each caller their proportion of the
// remaining unallocated space, we will ensure that the final consumer will get the remainder
// of the total space (this mitigates rounding errors to some extent by at least guaranteeing
// that the total space usage is correct).
//
open class StarSpaceManager
{
    var _totalStars = 0;
    var _totalStarSpace: Double = 0.0;
    
    public init(totalStars: Int, totalStarSpace: Double)
    {
        _totalStars = totalStars;
        _totalStarSpace = totalStarSpace;
    }
    
    open func getStarSpace(_ numStars: Int) -> Double
    {
        var starSpace: Double = 0.0;
        if ((_totalStarSpace > 0) && (_totalStars > 0))
        {
            starSpace = (_totalStarSpace/Double(_totalStars)) * Double(numStars);
            _totalStars -= numStars;
            _totalStarSpace -= starSpace;
        }
        return starSpace;
    }
}

class StackPanelView : PaddedView
{
    var _controlWrapper: iOSControlWrapper;
    var _orientation = Orientation.vertical;
    
    internal init(controlWrapper: iOSControlWrapper)
    {
        _controlWrapper = controlWrapper;
        super.init();
    }

    required internal init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    internal var orientation: Orientation
    {
        get { return _orientation; }
        set(value)
        {
            _orientation = value;
            self.setNeedsLayout();
        }
    }
    
    internal override var intrinsicContentSize : CGSize
    {
        // Compute the "wrap contents" (minimum) size for our contents.  This will not include
        // any allocation for star-sized children, if any (whose minimum size is implicitly zero).
        //
        var intrinsicSize = CGSize(width: 0, height: 0);
        
        for childView in self.subviews
        {
            if (childView.isHidden == true)
            {
                // Skip hidden children for layout purposes
                continue;
            }
        
            if let childControlWrapper = _controlWrapper.getChildControlWrapper(childView as UIView)
            {
                // For FillParent ("star sized") elements, we don't want to count the current value in that dimension in
                // the maximum or total values (those items will grow to fit when we arrange them later).
                //
                let countedChildHeight: CGFloat = (childControlWrapper.frameProperties.starHeight == 0) ? childView.frame.height : 0;
                let countedChildWidth: CGFloat = (childControlWrapper.frameProperties.starWidth == 0) ? childView.frame.width : 0;
                
                let margin = childControlWrapper.margin;
                
                if (_orientation == Orientation.horizontal)
                {
                    // Add to the width, update height as appropriate
                    intrinsicSize.width += countedChildWidth + (margin.left + margin.right);
                    intrinsicSize.height = max(intrinsicSize.height, countedChildHeight + (margin.top + margin.bottom));
                }
                else // Orientation.Vertical
                {
                    // Add to the height, update width as appropriate
                    intrinsicSize.height += countedChildHeight + (margin.top + margin.bottom);
                    intrinsicSize.width = max(intrinsicSize.width, countedChildWidth + (margin.left + margin.right));
                }
            }
        }
        
        logger.debug("Intrinsic size: \(intrinsicSize)");
        return intrinsicSize;
    }
    
    internal override func addSubview(_ view: UIView)
    {
        super.addSubview(view);
    }
    
    internal override func layoutSubviews()
    {
        logger.debug("StackPanelView - Layout subviews");
        
        super.layoutSubviews();
        
        if (((_controlWrapper.frameProperties.heightSpec == SizeSpec.fillParent) && (self.frame.height == 0)) ||
            ((_controlWrapper.frameProperties.widthSpec == SizeSpec.fillParent) && (self.frame.width == 0)))
        {
            // If either dimension is star sized, and the current size in that dimension is zero, then we
            // can't layout our children (we have no space to lay them out in anyway).  So this is a noop.
            //
            return;
        }
        
        // Determine the maximum subview size in the dimension perpendicular to the orientation, and the total
        // subview allocation in the orientation direction.
        //
        var totalStars = 0;
        
        var contentSize = self.intrinsicContentSize;
        
        for childView in self.subviews
        {
            if (childView.isHidden == true)
            {
                // Skip hidden children for layout purposes
                continue;
            }
        
            let childControlWrapper = _controlWrapper.getChildControlWrapper(childView)!;
            
            if (_orientation == Orientation.horizontal)
            {
                totalStars += childControlWrapper.frameProperties.starWidth;
            }
            else // Orientation.Vertical
            {
                totalStars += childControlWrapper.frameProperties.starHeight;
            }
        }
        
        // This is how much "extra" space we have in the orientation direction
        var totalStarSpace: Double = 0.0;
        
        if (_orientation == Orientation.horizontal)
        {
            if (_controlWrapper.frameProperties.widthSpec != SizeSpec.wrapContent)
            {
                totalStarSpace = max(0, Double(self.frame.width - contentSize.width - (_padding.left + _padding.right)));
            }
            
            if (_controlWrapper.frameProperties.heightSpec != SizeSpec.wrapContent)
            {
                contentSize.height = self.frame.height - (_padding.top + _padding.bottom);
            }
        }
        
        if (_orientation == Orientation.vertical)
        {
            if (_controlWrapper.frameProperties.heightSpec != SizeSpec.wrapContent)
            {
                totalStarSpace = max(0, Double(self.frame.height - contentSize.height - (_padding.top + _padding.bottom)));
            }
            
            if (_controlWrapper.frameProperties.widthSpec != SizeSpec.wrapContent)
            {
                contentSize.width = self.frame.width - (_padding.left + _padding.right);
            }
        }
        
        let starSpaceManager = StarSpaceManager(totalStars: totalStars, totalStarSpace: totalStarSpace);
        
        var _currTop = _padding.top;
        var _currLeft = _padding.left;
        
        var newPanelSize = CGSize(width: 0, height: 0);
        
        var lastMargin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
        
        // Arrange the subviews (align as appropriate)
        //
        for childView in self.subviews
        {
            if (childView.isHidden == true)
            {
                // Skip hidden children for layout purposes
                continue;
            }
            
            let childControlWrapper = _controlWrapper.getChildControlWrapper(childView)!;
            let margin = childControlWrapper.margin;
            
            var childFrame = childView.frame;
            
            if (_orientation == Orientation.horizontal)
            {
                if (childControlWrapper.frameProperties.starWidth > 0)
                {
                    childFrame.width = CGFloat(starSpaceManager.getStarSpace(childControlWrapper.frameProperties.starWidth));
                }
            
                // Set the horizontal position
                childFrame.x = _currLeft + lastMargin.right + margin.left;
                //
                // To collapse margins, instead do...
                // childFrame.x = _currLeft + max(lastMargin.right, margin.left);
                
                // Set the vertical position based on aligment (default Top)
                childFrame.y = _currTop + margin.top;
                
                if (childControlWrapper.frameProperties.heightSpec == SizeSpec.fillParent)
                {
                    // Filling to parent height (already top aligned, so set width relative to parent,
                    // accounting for margins.
                    //
                    childFrame.height = max(0, self.frame.height - (margin.top + _padding.top + margin.bottom + _padding.bottom));
                }
                else
                {
                    // Explicit height - align as needed.
                    //
                    if (childControlWrapper.verticalAlignment == VerticalAlignment.center)
                    {
                        // Should we consider margin when centering?  For now, we don't.
                        childFrame.y = _currTop + ((contentSize.height - childFrame.height) / 2);
                    }
                    else if (childControlWrapper.verticalAlignment == VerticalAlignment.bottom)
                    {
                        childFrame.y = _currTop + (contentSize.height - childFrame.height) - margin.bottom;
                    }
                }
            
                childView.frame = childFrame; // <== This is where we size child (the frame may or may not have actually changed)
                
                // We are going to explicitly call LayoutSubviews on the child here, as opposed to using SetNeedsLayout, because we want
                // the child to do the layout now so that we can accomodate size changes to the child (caused by its own LayoutSubviews)
                // in our own layout logic here...
                //
                childView.layoutSubviews();
                childFrame = childView.frame;
                
                _currLeft = childFrame.x + childFrame.width;
            }
            else // Orientation.Vertical
            {
                if (childControlWrapper.frameProperties.starHeight > 0)
                {
                    childFrame.height = CGFloat(starSpaceManager.getStarSpace(childControlWrapper.frameProperties.starHeight));
                }
                
                // Set the vertical position
                childFrame.y = _currTop + lastMargin.bottom + margin.top;
                //
                //x To collapse margins, instead do...
                // childFrame.y = _currTop + max(lastMargin.bottom, margin.top);
                
                // Set the horizontal position based on aligment (default Left)
                childFrame.x = _currLeft + margin.left;
                
                if (childControlWrapper.frameProperties.widthSpec == SizeSpec.fillParent)
                {
                    // Filling to parent width (already left aligned, so set width relative to parent,
                    // accounting for margins.
                    //
                    childFrame.width = max(0, self.frame.width - (margin.left + _padding.left + margin.right + _padding.right));
                }
                else
                {
                    // Explicit height - align as needed.
                    //
                    if (childControlWrapper.horizontalAlignment == HorizontalAlignment.center)
                    {
                        // Should we consider margin when centering?  For now, we don't.
                        childFrame.x = _currLeft + ((contentSize.width - childFrame.width) / 2);
                    }
                    else if (childControlWrapper.horizontalAlignment == HorizontalAlignment.right)
                    {
                        childFrame.x = _currLeft + (contentSize.width - childFrame.width) - margin.right;
                    }
                }
                
                childView.frame = childFrame; // <== This is where we size child (the frame may or may not have actually changed)
                
                // We are going to explicitly call LayoutSubviews on the child here, as opposed to using SetNeedsLayout, because we want
                // the child to do the layout now so that we can accomodate size changes to the child (caused by its own LayoutSubviews)
                // in our own layout logic here...
                //
                childView.layoutSubviews();
                childFrame = childView.frame;
                
                _currTop = childFrame.y + childFrame.height;
            }
        
            if ((childFrame.x + childFrame.width + margin.right) > newPanelSize.width)
            {
                newPanelSize.width = childFrame.x + childFrame.width + margin.right;
            }
            if ((childFrame.y + childFrame.height + margin.bottom) > newPanelSize.height)
            {
                newPanelSize.height = childFrame.y + childFrame.height + margin.bottom;
            }
            
            lastMargin = margin;
        }
        
        // Resize the stackpanel to contain the subview
        //
        newPanelSize.height += _padding.bottom;
        newPanelSize.width += _padding.right;
        
        // See if the stack panel might have changed size (based on content)
        //
        if ((_controlWrapper.frameProperties.widthSpec == SizeSpec.wrapContent) || (_controlWrapper.frameProperties.heightSpec == SizeSpec.wrapContent))
        {
            var panelSize = self.frame.size;
            if (_controlWrapper.frameProperties.heightSpec == SizeSpec.wrapContent)
            {
                panelSize.height = newPanelSize.height;
            }
            if (_controlWrapper.frameProperties.widthSpec == SizeSpec.wrapContent)
            {
                panelSize.width = newPanelSize.width;
            }
            
            // Only re-size and request superview layout if the size actually changes
            //
            if ((panelSize.width != self.frame.width) || (panelSize.height != self.frame.height))
            {
                var panelFrame = self.frame;
                panelFrame.size = panelSize;
                self.frame = panelFrame;
                if (self.superview != nil)
                {
                    self.superview!.setNeedsLayout();
                }
            }
        }
        
        logger.debug("Stackpanel size: \(self.frame.size.width), \(self.frame.size.height)");
    }
}

open class iOSStackPanelWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating stackpanel element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let stackPanel = StackPanelView(controlWrapper: self);
        self._control = stackPanel;
        
        processElementDimensions(controlSpec);
        applyFrameworkElementDefaults(stackPanel, applyMargins: false);
        
        processElementProperty(controlSpec, attributeName: "orientation", setValue: { (value) in stackPanel.orientation = self.toOrientation(value, defaultOrientation: Orientation.vertical) });
        
        processThicknessProperty(controlSpec, attributeName: "padding", thicknessSetter: PaddedViewThicknessSetter(paddedView: stackPanel));
        
        if let contentsArray = controlSpec["contents"] as? JArray
        {
            createControls(controlList: contentsArray, onCreateControl: { (childControlSpec, childControlWrapper) in
                if let childControl = childControlWrapper.control
                {
                    stackPanel.addSubview(childControl);
                }
            });
        }
        
        stackPanel.layoutSubviews();
        logger.debug("StackPanel created, size: \(stackPanel.frame.size)");
    }
}
