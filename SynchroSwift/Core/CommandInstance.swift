//
//  CommandInstance.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/12/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("CommandInstance");

// We can't have static (class) vars in Swift, but we can apparently have private global statics and public static
// (class) getters, so we'll make do with that.
//
private var staticCommandNames =
[
    "onClick": CommandName(attribute: "onClick"),
    "onItemClick": CommandName(attribute: "onItemClick"),
    "onSelectionChange":  CommandName(attribute: "onSelectionChange"),
    "onToggle":  CommandName(attribute: "onToggle"),
    "onUpdate": CommandName(attribute: "onUpdate"),
    "onTap": CommandName(attribute: "onTap")
]

open class CommandName
{
    fileprivate init(attribute: String) { _attribute = attribute; }
    
    fileprivate var _attribute: String;
    open var Attribute: String { get { return _attribute } }
    
    open var description: String { get { return Attribute; } } // ported from ToString
    
    open class var OnClick: CommandName { get { return staticCommandNames["onClick"]!; } }
    open class var OnItemClick: CommandName { get { return staticCommandNames["onItemClick"]!; } }
    open class var OnSelectionChange: CommandName { get { return staticCommandNames["onSelectionChange"]!; } }
    open class var OnToggle: CommandName { get { return staticCommandNames["onToggle"]!; } }
    open class var OnUpdate: CommandName { get { return staticCommandNames["onUpdate"]!; } }
    open class var OnTap: CommandName { get { return staticCommandNames["onTap"]!; } }
}

// This class corresponds to an instance of a command in a view
//
open class CommandInstance
{
    var _command: String;
    var _parameters = Dictionary<String, JToken>();
    
    public init(command: String)
    {
        _command = command;
    }
    
    open func setParameter(_ parameterName: String, parameterValue: JToken)
    {
        _parameters[parameterName] = parameterValue;
    }
    
    open var Command: String { get { return _command; } }
    
    // If a parameter is not a string type, then that parameter is passed directly.  This allows for parameters to
    // be boolean, numeric, or even objects.  If a parameter is a string, it will be evaluated to see if it has
    // any property bindings, and if so, those bindings will be expanded.  This allows for parameters that vary
    // based on the current context, for example, and also allows for complex values (such as property bindings
    // that refer to a single value of a type other than string, such as an object).
    //
    open func getResolvedParameters(_ bindingContext: BindingContext) -> JObject
    {
        let obj = JObject();
        for (parameterKey, parameterValue) in _parameters
        {
            var value: JToken? = parameterValue;
            if (parameterValue.TokenType == JTokenType.string)
            {
                value = PropertyValue.expand(parameterValue.asString()!, bindingContext: bindingContext);
            }
            
            if (value != nil)
            {
                obj[parameterKey] = value!.deepClone();
            }
            else
            {
                obj[parameterKey] = JValue();
            }
        }
        return obj;
    }
}
