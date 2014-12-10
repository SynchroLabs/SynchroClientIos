//
//  Binding.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("Binding");

public class BindingHelper
{
    // Binding is specified in the "binding" attribute of an element.  For example, binding: { value: "foo" } will bind the "value"
    // property of the control to the "foo" value in the current binding context.  For controls that can call commands, the command
    // handlers are bound similarly, for example, binding: { onClick: "someCommand" } will bind the onClick action of the control to
    // the "someCommand" command.
    //
    // A control type may have a default binding attribute, so that a simplified syntax may be used, where the binding contains a
    // simple value to be bound to the default binding attribute of the control.  For example, an edit control might use binding: "username"
    // to bind the default attribute ("value") to username.  A button might use binding: "someCommand" to bind the default attribute ("onClick")
    // to someCommand.
    //
    // This function extracts the binding value, and if the default/shorthand notation is used, expands it to a fully specified binding object.
    //
    //     For example, for an edit control with a default binding attribute of "value" a binding of:
    //
    //       binding: "username"
    //
    //         becomes
    //
    //       binding: {value: "username"}
    //
    //     For commands:
    //
    //       binding: "doSomething"
    //
    //         becomes
    //
    //       binding: { onClick: "doSomething" }
    //
    //         becomes
    //
    //       binding: { onClick: { command: "doSomething" } }
    //
    //     Also (default binding atttribute is 'onClick', which is also in command attributes list):
    //
    //       binding: { command: "doSomething" value: "theValue" }
    //
    //         becomes
    //
    //       binding: { onClick: { command: "doSomething", value: "theValue" } }
    //
    public class func getCanonicalBindingSpec(controlSpec: JObject, defaultBindingAttribute: String, commandAttributes: [String]? = nil) -> JObject?
    {
        var bindingObject: JObject? = nil;
    
        var defaultAttributeIsCommand = false;
        if (commandAttributes != nil)
        {
            defaultAttributeIsCommand = contains(commandAttributes!, defaultBindingAttribute);
        }
    
        var bindingSpec = controlSpec["binding"];
    
        if let bindingSpec = controlSpec["binding"]
        {
            if (bindingSpec.Type == JTokenType.Object)
            {
                // Encountered an object spec, return that (subject to further processing below)
                //
                bindingObject = bindingSpec.deepClone() as? JObject
    
                if (defaultAttributeIsCommand && (bindingObject!["command"] != nil))
                {
                    // Top-level binding spec object contains "command", and the default binding attribute is a command, so
                    // promote { command: "doSomething" } to { defaultBindingAttribute: { command: "doSomething" } }
                    //
                    bindingObject = JObject([defaultBindingAttribute: bindingObject!]);
                }
            }
            else
            {
                // Top level binding spec was not an object (was an array or value), so promote that value to be the value
                // of the default binding attribute
                //
                bindingObject = JObject([defaultBindingAttribute: bindingSpec.deepClone()]);
            }
    
            // Now that we've handled the default binding attribute cases, let's look for commands that need promotion...
            //
            if (commandAttributes != nil)
            {
                /* Not used?
                List<string> commandKeys = new List<string>();
                foreach (var attribute in bindingObject)
                {
                    if (commandAttributes.Contains(attribute.Key))
                    {
                        commandKeys.Add(attribute.Key);
                    }
                }
                */
    
                for commandAttribute in commandAttributes!
                {
                    // Processing a command (attribute name corresponds to a command)
                    //
                    if (bindingObject![commandAttribute] is JValue)
                    {
                        // If attribute value is simple value type, promote "attributeValue" to { command: "attributeValue" }
                        //
                        bindingObject![commandAttribute] = JObject(["command": JValue(bindingObject![commandAttribute] as JValue)]);
                    }
                }
            }
    
            logger.debug("Found binding object: \(bindingObject)");
        }
        else
        {
            // No binding spec
            bindingObject = JObject();
        }
    
        return bindingObject;
    }
    
}
