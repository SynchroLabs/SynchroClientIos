//
//  iOSTextBoxWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSTextBoxWrapper");

public class iOSTextBoxWrapper : iOSControlWrapper
{
    var _textBox: UITextField;
    var _updateOnChange = false;
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating textbox element");
        _textBox = UITextField();
        
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);

        self._control = _textBox;
        
        if (controlSpec["control"]?.asString() == "password")
        {
            _textBox.secureTextEntry = true;
        }
        
        _textBox.borderStyle = UITextBorderStyle.RoundedRect;
        
        processElementDimensions(controlSpec, defaultWidth: 100); // Default width of 100
        
        applyFrameworkElementDefaults(_textBox);
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value")
        {
            if (!self.processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(self._textBox.text!) }, setValue: { (value) in self._textBox.text = self.toString(value) }))
            {
                processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in self._textBox.text = self.toString(value) });
                _textBox.sizeToFit();
            }
            
            if (bindingSpec["sync"]?.asString() == "change")
            {
                _updateOnChange = true;
            }
        }
        
        processElementProperty(controlSpec, attributeName: "placeholder", setValue: { (value) in self._textBox.placeholder = self.toString(value) });
        
        _textBox.addTarget(self, action: "editingChanged:", forControlEvents: .EditingChanged);
    }
    
    public func editingChanged(sender: AnyObject)
    {
        // This is basically the "onChange" event...
        //
        // Edit controls have a bad habit of posting a text changed event, and there are cases where
        // this event is generated based on programmatic setting of text and comes in asynchronously
        // after that programmatic action, making it difficult to distinguish actual user changes.
        // This shortcut will help a lot of the time, but there are still cases where this will be
        // signalled incorrectly (such as in the case where a control with focus is the target of
        // an update from the server), so we'll do some downstream delta checking as well, but this
        // check will cut down most of the chatter.
        //
        if (_textBox.isFirstResponder())
        {
            updateValueBindingForAttribute("value");
            if (_updateOnChange)
            {
                self.stateManager.sendUpdateRequestAsync();
            }
        }
    }
}
