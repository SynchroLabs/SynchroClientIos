//
//  iOSBorderWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSBorderWrapper");

private var commands = [CommandName.OnTap.Attribute];

public class PaddedView : UIView
{
    var _padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
    
    public init()
    {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    public var padding: UIEdgeInsets
    {
        get { return _padding; }
        set(value)
        {
            _padding = value;
            self.setNeedsLayout();
        }
    }
    
    public var paddingLeft: CGFloat
    {
        get { return _padding.left; }
        set(value)
        {
            _padding.left = value;
            self.setNeedsLayout();
        }
    }
    
    public var paddingTop: CGFloat
    {
        get { return _padding.top; }
        set(value)
        {
            _padding.top = value;
            self.setNeedsLayout();
        }
    }
    
    public var paddingRight: CGFloat
    {
        get { return _padding.right; }
        set(value)
        {
            _padding.right = value;
            self.setNeedsLayout();
        }
    }
    
    public var paddingBottom: CGFloat
    {
        get { return _padding.bottom; }
        set(value)
        {
            _padding.bottom = value;
            self.setNeedsLayout();
        }
    }
}

public class PaddedViewThicknessSetter : ThicknessSetter
{
    var _paddedView: PaddedView;
    
    public init(paddedView: PaddedView)
    {
        _paddedView = paddedView;
    }
    
    public func setThickness(thickness: Double)
    {
        self.setThicknessTop(thickness);
        self.setThicknessLeft(thickness);
        self.setThicknessBottom(thickness);
        self.setThicknessRight(thickness);
    }
    
    public func setThicknessLeft(thickness: Double)
    {
        _paddedView.paddingLeft = CGFloat(thickness);
    }
    
    public func setThicknessTop(thickness: Double)
    {
        _paddedView.paddingTop = CGFloat(thickness);
    }
    
    public func setThicknessRight(thickness: Double)
    {
        _paddedView.paddingRight = CGFloat(thickness);
    }
    
    public func setThicknessBottom(thickness: Double)
    {
        _paddedView.paddingBottom = CGFloat(thickness);
    }
}

class BorderView : PaddedView
{
    var _controlWrapper: iOSControlWrapper;
    var _childView: UIView?;
    
    internal init(controlWrapper: iOSControlWrapper)
    {
        _controlWrapper = controlWrapper;
        super.init();
    }

    required internal init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    internal var borderWidth: CGFloat
    {
        get { return self.layer.borderWidth; }
        set(value)
        {
            self.layer.borderWidth = value;
            self.setNeedsLayout();
        }
    }
    
    internal override func addSubview(view: UIView)
    {
        _childView = view;
        super.addSubview(view);
    }
    
    internal override func layoutSubviews()
    {
        // logger.debug("BorderView - Layout subviews");
    
        if let childView = _childView
        {
            let insets = UIEdgeInsets(
                top: self.layer.borderWidth + _padding.top,
                left: self.layer.borderWidth + _padding.left,
                bottom: self.layer.borderWidth + _padding.bottom,
                right: self.layer.borderWidth + _padding.right
            );
    
            var childFrame = childView.frame;
            var panelSize = self.frame.size;
            
            var margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);
            if let childControlWrapper = _controlWrapper.getChildControlWrapper(childView)
            {
                margin = childControlWrapper.margin;
            
                if (_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent)
                {
                    // Panel width will size to content
                    //
                    childFrame.x = insets.left + margin.left;
                    panelSize.width = childFrame.x + childFrame.width + insets.right + margin.right;
                }
                else
                {
                    // Panel width is explicit, so align content using the content horizontal alignment (along with padding and margin)
                    //
                    childFrame.x = insets.left + margin.left;
                    
                    if (childControlWrapper.frameProperties.widthSpec == SizeSpec.FillParent)
                    {
                        // Child will fill parent (less margins/padding)
                        //
                        childFrame.width = panelSize.width - (insets.left + margin.left + insets.right + margin.right);
                    }
                    else
                    {
                        // Align child in parent
                        //
                        if (childControlWrapper.horizontalAlignment == HorizontalAlignment.Center)
                        {
                            // Ignoring margins on center for now.
                            childFrame.x = (panelSize.width - childFrame.width) / 2;
                        }
                        else if (childControlWrapper.horizontalAlignment == HorizontalAlignment.Right)
                        {
                            childFrame.x = (panelSize.width - childFrame.width - insets.right - margin.right);
                        }
                    }
                }
                
                if (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent)
                {
                    // Panel height will size to content
                    //
                    childFrame.y = insets.top + margin.top;
                    panelSize.height = childFrame.y + childFrame.height + insets.bottom + margin.bottom;
                }
                else
                {
                    // Panel height is explicit, so align content using the content vertical alignment (along with padding and margin)
                    //
                    childFrame.y = insets.top + margin.top;
                    
                    if (childControlWrapper.frameProperties.heightSpec == SizeSpec.FillParent)
                    {
                        // Child will fill parent (less margins/padding)
                        //
                        childFrame.height = panelSize.height - (insets.top + margin.top + insets.bottom + margin.bottom);
                    }
                    else
                    {
                        // Align child in parent
                        //
                        if (childControlWrapper.verticalAlignment == VerticalAlignment.Center)
                        {
                            // Ignoring margins on center for now.
                            childFrame.y = (panelSize.height - childFrame.height) / 2;
                        }
                        else if (childControlWrapper.verticalAlignment == VerticalAlignment.Bottom)
                        {
                            childFrame.y = (panelSize.height - childFrame.height - insets.bottom - margin.bottom);
                        }
                    }
                }
            }
            
            // Update the content position
            //
            childView.frame = childFrame; // !!! Size child
            
            // See if the border panel might have changed size (based on content)
            //
            if ((_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent) || (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent))
            {
                // See if the border panel actually did change size
                //
                if ((self.frame.width != panelSize.width) || (self.frame.height != panelSize.height))
                {
                    // Resize the border panel to contain the control...
                    //
                    var panelFrame = self.frame;
                    panelFrame.size = panelSize;
                    self.frame = panelFrame;
                    
                    if (self.superview != nil)
                    {
                        self.superview!.setNeedsLayout();
                    }
                }
            }
        }
        
        logger.debug("Border sized to: \(self.frame.size.width), \(self.frame.size.height)");
        
        super.layoutSubviews();
    }
}

public class iOSBorderWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating border element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let border = BorderView(controlWrapper: self);
        self._control = border;
        
        processElementDimensions(controlSpec, defaultWidth: 128, defaultHeight: 128);
        applyFrameworkElementDefaults(border);
        
        // If border thickness or padding change, need to resize view to child...
        //
        processElementProperty(controlSpec, attributeName: "border", setValue: { (value) in border.layer.borderColor = self.toColor(value)?.CGColor });
        processElementProperty(controlSpec, attributeName: "borderThickness", setValue: { (value) in
            if let theValue = value
            {
                border.borderWidth = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: "cornerRadius", setValue: { (value) in
            if let theValue = value
            {
                border.layer.cornerRadius = CGFloat(self.toDeviceUnits(theValue));
            }
        });
        processThicknessProperty(controlSpec, attributeName: "padding", thicknessSetter: PaddedViewThicknessSetter(paddedView: border));
        
        // "background" color handled by base class
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnTap.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
        
        if (getCommand(CommandName.OnTap) != nil)
        {
            let tapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(borderTapped))
            border.userInteractionEnabled = true
            border.addGestureRecognizer(tapGestureRecognizer)
        }
        
        if let contentsArray = controlSpec["contents"] as? JArray
        {
            createControls(controlList: contentsArray, onCreateControl: { (childControlSpec, childControlWrapper) in
                if let control = childControlWrapper.control
                {
                    border.addSubview(control);
                }
            });
        }
        
        logger.debug("Border created, size: \(border.frame.size)");
        border.layoutSubviews();
    }
    
    func borderTapped(img: AnyObject)
    {
        if let command = getCommand(CommandName.OnTap)
        {
            logger.debug("Image tap with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(self.bindingContext));
        }
    }
}
