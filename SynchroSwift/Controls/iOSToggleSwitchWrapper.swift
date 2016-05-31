//
//  iOSToggleSwitchWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSToggleSwitchWrapper");

class ToggleSwitchView : PaddedView
{
    var _controlWrapper: iOSControlWrapper;
    var _label: UILabel?;
    var _switch: UISwitch?;
    var _spacing: CGFloat = 10;
    
    init(controlWrapper: iOSControlWrapper)
    {
        _controlWrapper = controlWrapper;
        super.init();
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    override func intrinsicContentSize() -> CGSize
    {
        // Compute the "wrap contents" (minimum) size for our contents.
        //
        var intrinsicSize = CGSize(width: 0, height: 0);
        
        if (_label != nil)
        {
            _label!.sizeToFit();
            logger.debug("Sized label to fit, label text is: \(_label!.text), font is: \(_label!.font) and size is \(_label!.frame.height) x \(_label!.frame.width)");
            intrinsicSize.height = _label!.frame.height;
            intrinsicSize.width = _label!.frame.width;
        }
        
        if (_switch != nil)
        {
            intrinsicSize.height = max(intrinsicSize.height, _switch!.frame.height);
            intrinsicSize.width += _switch!.frame.width;
            if (_label != nil)
            {
                intrinsicSize.width += _spacing;
            }
        }
        return intrinsicSize;
    }
    
    override func addSubview(view: UIView)
    {
        if (view is UILabel)
        {
            _label = view as? UILabel;
        }
        else if (view is UISwitch)
        {
            _switch = view as? UISwitch;
        }
        else
        {
            // We're the only ones who call this, so this should never happen...
            fatalError("Can only add UILabel or UISwitch");
        }
        
        super.addSubview(view);
    }
    
    override func layoutSubviews()
    {
        logger.debug("ToggleSwitchView - Layout subviews");
    
        super.layoutSubviews();
    
        if (((_controlWrapper.frameProperties.heightSpec == SizeSpec.FillParent) && (self.frame.height == 0)) ||
            ((_controlWrapper.frameProperties.widthSpec == SizeSpec.FillParent) && (self.frame.width == 0)))
        {
            // If either dimension is star sized, and the current size in that dimension is zero, then we
            // can't layout our children (we have no space to lay them out in anyway).  So this is a noop.
            //
            return;
        }
        
        var contentSize = self.intrinsicContentSize();
        if (_controlWrapper.frameProperties.heightSpec != SizeSpec.WrapContent)
        {
            contentSize.height = self.frame.height;
        }
        if (_controlWrapper.frameProperties.widthSpec != SizeSpec.WrapContent)
        {
            contentSize.width = self.frame.width;
        }
        
        // Arrange the subviews (align as appropriate)
        //
        if (_label != nil)
        {
            // !!! If the container is not wrap width, then we need to make sure the switch has the
            //     room it needs and the label formats itself into whatever width is left over.  Not
            //     sure if it would be better to wrap or ellipsize the label if it overflows.  See
            //     iOSTextBlockWrapper for examples of size management.
            //
            
            // Left aligned, verticaly centered
            _label!.sizeToFit();
            var labelFrame = _label!.frame;
            labelFrame.x = _padding.left;
            labelFrame.y = ((contentSize.height - labelFrame.height) / 2);
            _label!.frame = labelFrame;
        }
        
        if (_switch != nil)
        {
            // Left aligned, vertically centered
            var switchFrame = _switch!.frame;
            switchFrame.x = _padding.left;
            switchFrame.y = ((contentSize.height - switchFrame.height) / 2);
            if (_label != nil)
            {
                // Right aligned
                switchFrame.x = contentSize.width - switchFrame.width - _padding.right;
            }
            _switch!.frame = switchFrame;
        }
        
        var newPanelSize = CGSize(width: 0, height: 0);
        
        if (_switch != nil)
        {
            newPanelSize.height += _switch!.frame.bottom + _padding.bottom;
            newPanelSize.width += _switch!.frame.right + _padding.right;
        }
        
        // Resize the containing panel to contain the subview, as needed
        //
        
        // See if the panel might have changed size (based on content)
        //
        if ((_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent) || (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent))
        {
            var panelSize = self.frame.size;
            if (_controlWrapper.frameProperties.heightSpec == SizeSpec.WrapContent)
            {
                panelSize.height = newPanelSize.height;
            }
            if (_controlWrapper.frameProperties.widthSpec == SizeSpec.WrapContent)
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
    }
}

class ToggleLabelFontSetter : iOSFontSetter
{
    var _label: UILabel;
    
    init(label: UILabel)
    {
        _label = label;
        super.init(font: label.font);
    }
    
    override func setFont(font: UIFont)
    {
        _label.font = font;
        if (_label.superview != nil)
        {
            _label.superview!.setNeedsLayout();
        }
    }
}

private var commands = [CommandName.OnToggle.Attribute];

public class iOSToggleSwitchWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating toggleswitch element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let label = UILabel();
        let toggleSwitch = UISwitch();
        
        let view = ToggleSwitchView(controlWrapper: self);
        view.clipsToBounds = true;
        view.addSubview(label);
        view.addSubview(toggleSwitch);
        
        self._control = view;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(view);
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
            
            // Switch
            //
            if (!processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(toggleSwitch.on); }, setValue: { (value) in toggleSwitch.on = self.toBoolean(value) }))
            {
                processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in toggleSwitch.on = self.toBoolean(value) });
            }
        }
        
        // There  is no straighforward way to change the labels on the switch itself (you can use custom images,
        // and people have tried hacking in to the view heirarchy to find the labels, but that changes between
        // iOS versions and is not considered a viable approach).  For now, we don't support this on iOS.
        //
        // !!! processElementProperty(controlSpec["onLabel"], value => toggleSwitch.TextOn = ToString(value));
        // !!! processElementProperty(controlSpec["offLabel"], value => toggleSwitch.TextOff = ToString(value));
        
        // Label
        //
        processElementProperty(controlSpec, attributeName: "caption", setValue: { (value) in label.text = self.toString(value) });
        
        processElementProperty(controlSpec, attributeName: "color", altAttributeName: "foreground", setValue: { (value) in
            label.textColor = self.toColor(value);
        });
        
        processFontAttribute(controlSpec, fontSetter: ToggleLabelFontSetter(label: label));
        
        toggleSwitch.addTarget(self, action: #selector(stateChanged), forControlEvents: .ValueChanged);
        
        view.layoutSubviews();
    }
    
    func stateChanged(switchState: UISwitch)
    {
        updateValueBindingForAttribute("value");
        
        let command = getCommand(CommandName.OnToggle);
        if (command != nil)
        {
            logger.debug("ToggleSwitch toggled with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command!.Command, parameters: command!.getResolvedParameters(bindingContext));
        }
    }
}
