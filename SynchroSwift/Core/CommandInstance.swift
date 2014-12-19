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
    "onUpdate": CommandName(attribute: "onUpdate")
]

public class CommandName
{
    private init(attribute: String) { _attribute = attribute; }
    
    private var _attribute: String;
    public var Attribute: String { get { return _attribute } }
    
    public var description: String { get { return Attribute; } } // ported from ToString
    
    public class var OnClick: CommandName { get { return staticCommandNames["onClick"]!; } }
    public class var OnItemClick: CommandName { get { return staticCommandNames["onItemClick"]!; } }
    public class var OnSelectionChange: CommandName { get { return staticCommandNames["onSelectionChange"]!; } }
    public class var OnToggle: CommandName { get { return staticCommandNames["onToggle"]!; } }
    public class var OnUpdate: CommandName { get { return staticCommandNames["onUpdate"]!; } }
}

// This class corresponds to an instance of a command in a view
//
public class CommandInstance
{
    var _command: String;
    var _parameters = Dictionary<String, JToken>();
    
    public init(command: String)
    {
        _command = command;
    }
    
    public func setParameter(parameterName: String, parameterValue: JToken)
    {
        _parameters[parameterName] = parameterValue;
    }
    
    public var Command: String { get { return _command; } }
    
    // If a parameter is not a string type, then that parameter is passed directly.  This allows for parameters to
    // be boolean, numeric, or even objects.  If a parameter is a string, it will be evaluated to see if it has
    // any property bindings, and if so, those bindings will be expanded.  This allows for parameters that vary
    // based on the current context, for example, and also allows for complex values (such as property bindings
    // that refer to a single value of a type other than string, such as an object).
    //
    public func getResolvedParameters(bindingContext: BindingContext) -> JObject
    {
        var obj = JObject();
        for (parameterKey, parameterValue) in _parameters
        {
            var value: JToken? = parameterValue;
            if (parameterValue.Type == JTokenType.String)
            {
                value = PropertyValue.expand(parameterValue.asString()!, bindingContext: bindingContext);
            }
            
            if let theValue = value
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
