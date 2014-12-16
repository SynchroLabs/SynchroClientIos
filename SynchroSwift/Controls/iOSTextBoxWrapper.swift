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

public class iOSTextBoxWrapper : iOSControlWrapper, UITextFieldDelegate
{
    var _updateOnChange = false;
    
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating textbox element");
        super.init(parent: parent, bindingContext: bindingContext);

        var textBox = UITextField();
        self._control = textBox;
        
        if (controlSpec["control"]?.asString() == "password")
        {
            textBox.secureTextEntry = true;
        }
        
        textBox.borderStyle = UITextBorderStyle.RoundedRect;
        
        processElementDimensions(controlSpec, defaultWidth: 100); // Default width of 100
        
        applyFrameworkElementDefaults(textBox);
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value")
        {
            if (!self.processElementBoundValue("value", attributeValue: bindingSpec["value"], { () in return JValue(textBox.text) }, { (value) in textBox.text = self.toString(value) }))
            {
                processElementProperty(controlSpec["value"], { (value) in textBox.text = self.toString(value) });
                textBox.sizeToFit();
            }
            
            if (bindingSpec["sync"]?.asString() == "change")
            {
                _updateOnChange = true;
            }
        }
        
        processElementProperty(controlSpec["placeholder"], { (value) in textBox.placeholder = self.toString(value) });
    }
    
    func textFieldDidChange(textField: UITextField!)
    {
        // Edit controls have a bad habit of posting a text changed event, and there are cases where
        // this event is generated based on programmatic setting of text and comes in asynchronously
        // after that programmatic action, making it difficult to distinguish actual user changes.
        // This shortcut will help a lot of the time, but there are still cases where this will be
        // signalled incorrectly (such as in the case where a control with focus is the target of
        // an update from the server), so we'll do some downstream delta checking as well, but this
        // check will cut down most of the chatter.
        //
        if (textField.isFirstResponder())
        {
            updateValueBindingForAttribute("value");
            if (_updateOnChange)
            {
                self.stateManager.sendUpdateRequestAsync();
            }
        }
    }
}
