//
//  iOSToggleButtonWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 5/31/16.
//  Copyright © 2016 Robert Dickinson. All rights reserved.
//
import Foundation
import UIKit

private var logger = Logger.getLogger("iOSToggleButtonWrapper");

private var commands = [CommandName.OnToggle.Attribute];

class ToggleButtonFontSetter : iOSFontSetter
{
    var _controlWrapper: iOSToggleButtonWrapper;
    var _button: UIButton;
    
    internal init(controlWrapper: iOSToggleButtonWrapper, button: UIButton)
    {
        _controlWrapper = controlWrapper;
        _button = button;
        super.init(font: button.titleLabel!.font);
    }
    
    internal override func setFont(font: UIFont)
    {
        _button.titleLabel!.font = font;
        _controlWrapper.sizeToFit();
    }
}

public class iOSToggleButtonWrapper : iOSControlWrapper
{
    var _isChecked = false;
    
    var isChecked: Bool
    {
        get { return _isChecked; }
        set(value)
        {
            if (_isChecked != value)
            {
                _isChecked = value;
                self.updateVisualState();
            }
        }
    }

    var _hasCaption = false;
    
    var _caption: String?;
    var _checkedCaption: String?;
    var _uncheckedCaption: String?;
    
    var _icon: UIImage?;
    var _checkedIcon: UIImage?;
    var _uncheckedIcon: UIImage?;
    
    var _color: UIColor?;
    var _checkedColor: UIColor?;
    var _uncheckedColor: UIColor?;
    
    func setCaption(caption: String)
    {
        let button = _control as! UIButton;
        UIView.performWithoutAnimation { () -> Void in
            button.setTitle(caption, forState: .Normal);
            button.layoutIfNeeded();
            self.sizeToFit();
        }
    }
    
    func setIcon(image: UIImage)
    {
        let button = _control as! UIButton;
        button.setImage(image, forState: .Normal);
        button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        button.setImageInsets(self._hasCaption);
        self.sizeToFit();
    }

    func setColor(color: UIColor)
    {
        let button = _control as! UIButton;
        button.tintColor = color;
    }
    
    func updateVisualState()
    {
        // If the user specified configuration that visually communicates the state change, then we will use only those
        // configuration elements to show the state change.  If they do not include any such elements, then we will gray
        // the toggle button out to show the unchecked state.
        //
        let isVisualStateExplicit = ((self._checkedCaption != nil) || (self._checkedIcon != nil) || (self._checkedColor != nil));
        
        if (isChecked)
        {
            if (isVisualStateExplicit)
            {
                // One or more of the explicit checked items will be set below...
                //
                if let caption = self._checkedCaption
                {
                    setCaption(caption);
                }
                if let icon = self._checkedIcon
                {
                    setIcon(icon);
                }
                if let color = self._checkedColor
                {
                    setColor(color);
                }
            }
            else
            {
                // There was no explicit visual state specified, so we will use default color for checked
                //
                setColor(self._color!);
                
            }
        }
        else
        {
            if (isVisualStateExplicit)
            {
                // One or more of the explicit unchecked items will be set below...
                //
                if let caption = self._uncheckedCaption
                {
                    setCaption(caption);
                }
                if let icon = self._uncheckedIcon
                {
                    setIcon(icon);
                }
                if let color = self._uncheckedColor
                {
                    setColor(color);
                }
            }
            else
            {
                // There was no explicit visual state specified, so we will use "gray" for unchecked
                //
                setColor(UIColor.lightGrayColor());
            }
        }
        
    }
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating toggle button element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let button = UIButton(type: UIButtonType.System);
        self._control = button;
        
        processElementDimensions(controlSpec);
        applyFrameworkElementDefaults(button);
        
        button.setInsets();
        self.sizeToFit();

        self._hasCaption = ((controlSpec["caption"] != nil) || (controlSpec["checkedcaption"] != nil));
        self._color = button.tintColor;
        
        processElementProperty(controlSpec, attributeName: "caption", setValue: { (value) in
            self._caption = self.toString(value);
            self.setCaption(self._caption!);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "checkedcaption", setValue: { (value) in
            self._checkedCaption = self.toString(value);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "uncheckedcaption", setValue: { (value) in
            self._uncheckedCaption = self.toString(value);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "icon", setValue: { (value) in
            self._icon = iOSControlWrapper.loadImageFromIcon(self.toString(value));
            self.setIcon(self._icon!);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "checkedicon", setValue: { (value) in
            self._checkedIcon = iOSControlWrapper.loadImageFromIcon(self.toString(value));
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "uncheckedicon", setValue: { (value) in
            self._uncheckedIcon = iOSControlWrapper.loadImageFromIcon(self.toString(value));
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "color", altAttributeName: "foreground", setValue: { (value) in
            self._color = self.toColor(value);
            self.setColor(self._color!);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "checkedcolor", setValue: { (value) in
            self._checkedColor = self.toColor(value);
            self.updateVisualState();
        });

        processElementProperty(controlSpec, attributeName: "uncheckedcolor", setValue: { (value) in
            self._uncheckedColor = self.toColor(value);
            self.updateVisualState();
        });

        processFontAttribute(controlSpec, fontSetter: ToggleButtonFontSetter(controlWrapper: self, button: button));
        
        processElementProperty(controlSpec, attributeName: "cornerRadius", setValue: { (value) in
            button.layer.cornerRadius = CGFloat(self.toDeviceUnits(value!));
        });
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value", commandAttributes: commands)
        {
            if (!processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(self.isChecked); }, setValue: { (value) in self.isChecked = self.toBoolean(value) }))
            {
                processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in self.isChecked = self.toBoolean(value) });
            }
            
            processCommands(bindingSpec, commands: commands);
        }
        
        button.addTarget(self, action: #selector(pressed), forControlEvents: .TouchUpInside);
    }
    
    func pressed(sender: UIButton!)
    {
        self.isChecked = !self.isChecked;
        
        updateValueBindingForAttribute("value");
        
        let command = getCommand(CommandName.OnToggle);
        if (command != nil)
        {
            logger.debug("ToggleButton toggled with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command!.Command, parameters: command!.getResolvedParameters(bindingContext));
        }

    }
}
