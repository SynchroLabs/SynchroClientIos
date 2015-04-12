//
//  iOSToolBarToggleWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSToolBarToggleWrapper");

private var commands = [CommandName.OnToggle.Attribute];

public class iOSToolBarToggleWrapper : iOSControlWrapper
{
    var _buttonItem: UIBarButtonItem!;
    
    var _isChecked = false;
    var _uncheckedText: String?;
    var _checkedText: String?;
    var _uncheckedIcon: String?;
    var _checkedIcon: String?;
    
    func setText(value: String?)
    {
        if (value != nil)
        {
            _buttonItem.title = value!;
        }
    }
    
    func setImage(value: String?)
    {
        if (value != nil)
        {
            _buttonItem.image = iOSToolBarWrapper.loadIconImage(value!);
            self._pageView.setNavBarButton(_buttonItem);
        }
    }
    
    var isChecked: Bool
    {
        get { return _isChecked; }
        set(value)
        {
            if (_isChecked != value)
            {
                _isChecked = value;
                if (_isChecked)
                {
                    setText(_checkedText);
                    setImage(_checkedIcon);
                }
                else
                {
                    setText(_uncheckedText);
                    setImage(_uncheckedIcon);
                }
            }
        }
    }
    
    var uncheckedText: String?
    {
        get { return _uncheckedText; }
        set(value)
        {
            _uncheckedText = value;
            if (!_isChecked)
            {
                setText(_uncheckedText);
            }
        }
    }
    
    var checkedText: String?
    {
        get { return _checkedText; }
        set(value)
        {
            _checkedText = value;
            if (_isChecked)
            {
                setText(_checkedText);
            }
        }
    }
    
    var uncheckedIcon: String?
    {
        get { return _uncheckedIcon; }
        set(value)
        {
            _uncheckedIcon = value;
            if (!_isChecked)
            {
                setImage(_uncheckedIcon);
            }
        }
    }
    
    var checkedIcon: String?
    {
        get { return _checkedIcon; }
        set(value)
        {
            _checkedIcon = value;
            if (_isChecked)
            {
                setImage(_checkedIcon);
            }
        }
    }

    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating toolbar toggle element");
        super.init(parent: parent, bindingContext: bindingContext);
     
        // Custom items, can specify text, icon, or both
        //
        _buttonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "barButtonItemClicked:");

        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnClick.Attribute, commandAttributes: commands)
        {
            if (!processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(self.isChecked); }, setValue: { (value) in self.isChecked = self.toBoolean(value) }))
            {
                processElementProperty(controlSpec["value"], setValue: { (value) in self.isChecked = self.toBoolean(value) });
            }

            processCommands(bindingSpec, commands: commands);
        }
        
        processElementProperty(controlSpec["text"], setValue: { (value) in self._buttonItem.title = self.toString(value) });
        processElementProperty(controlSpec["icon"], setValue: { (value) in self._buttonItem.image = iOSToolBarWrapper.loadIconImage(self.toString(value)) });
        
        processElementProperty(controlSpec["uncheckedtext"], setValue: { (value) in self.uncheckedText = self.toString(value) });
        processElementProperty(controlSpec["checkedtext"], setValue: { (value) in self.checkedText = self.toString(value) });
        processElementProperty(controlSpec["uncheckedicon"], setValue: { (value) in self.uncheckedIcon = self.toString(value) });
        processElementProperty(controlSpec["checkedicon"], setValue: { (value) in self.checkedIcon = self.toString(value) });
        
        processElementProperty(controlSpec["enabled"], setValue: { (value) in self._buttonItem.enabled = self.toBoolean(value) });
        
        if (controlSpec["control"]?.asString() == "navBar.toggle")
        {
            // When image and text specified, uses image.  Image is placed on button surface verbatim (no color coersion).
            //
            _pageView.setNavBarButton(_buttonItem);
        }
        else // toolBar.toggle
        {
            // Can use image, text, or both, and toolbar shows what was provided (including image+text).  Toolbar coerces colors
            // and handles disabled state (for example, on iOS 6, icons/text show up as white when enabled and gray when disabled).
            //
            _pageView.addToolbarButton(_buttonItem);
        }
        
        _isVisualElement = false;
    }
    
    func barButtonItemClicked(barButtonItem: UIBarButtonItem)
    {
        self.isChecked = !self.isChecked;
        
        updateValueBindingForAttribute("value");
                
        if let command = getCommand(CommandName.OnToggle)
        {
            logger.debug("Button toggle with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(bindingContext));
        }
    }
}
