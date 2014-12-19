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

// PropertyValue objects maintain a list of things that provide values to the expanded output.  Some of
// things things are binding contexts that will be evalutated each time the underlying value changes (one-way
// bindings), but some of them will be resolved based on the initial view model contents at the time of
// creation (one-time bindings).  This object accomodates both states and provides a convenient way to determine
// which type of binding it is, and to extract the resolved/expanded value without needing to know which type
// of binding it is.
//
public class BoundAndPossiblyResolvedToken
{
    var _bindingContext: BindingContext;
    var _resolvedValue: JToken?;
    
    // OK - The way negation is handled here is pretty crude.  The idea is that in the future we will support
    // complex value converters, perhaps even functions which themselves have more than one token as parameters.
    // So a more generalized concept of a value converter (delegate) passed in here from the parser and used
    // to produce the resolved value would be better.
    //
    var _negated = false;
    
    // !!! TODO
    //
    // At least on iOS, I think the best way to handle numeric formatting is the do it here (in token resolution below).
    // 
    //   Here is the list of .NET number format specifiers: http://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
    //   Here is the string format specifiers supported on iOS: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
    //
    //   In pratice I think D, F, P, N, and X are what we should support.
    //
    var _formatSpec: String?; // If present, this is the .NET format specifier (whatever came after the colon)
    
    public init(_ bindingContext: BindingContext, oneTime: Bool, negated: Bool, formatSpec: String? = nil)
    {
        _bindingContext = bindingContext;
        _negated = negated;
        _formatSpec = formatSpec;
    
        if (oneTime)
        {
            // Since we're potentially storing this over time and don't want any underlying view model changes
            // to impact this value, we need to clone it.
            //
            _resolvedValue = _bindingContext.getValue()!.deepClone();
            if (_negated)
            {
                _resolvedValue = JValue(!TokenConverter.toBoolean(_resolvedValue));
            }
        }
    }
    
    public var bindingContext: BindingContext { get { return _bindingContext; } }
    
    public var resolved: Bool { get { return _resolvedValue != nil; } }
    
    public var resolvedValue: JToken?
    {
        get
        {
            if (_resolvedValue != nil)
            {
                return _resolvedValue!;
            }
            else
            {
                var resolvedValue = _bindingContext.getValue();
                if (_negated)
                {
                    resolvedValue = JValue(!TokenConverter.toBoolean(resolvedValue));
                }
                return resolvedValue;
            }
        }
    }
    
    public var resolvedValueAsString: String
    {
        get
        {
            if let formatSpec = _formatSpec
            {
                // !!! Apply formatSpec to format numbers...
                //
                // This is what we have for formatting on iOS: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
                //
                // And we'll support some defined subset of: http://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
                //
                // If formatting succeeds, return formatted, else fall through to general (non-formatted) result
                //
            }
            
            return TokenConverter.toString(self.resolvedValue);
        }
    }
}

// Property values consist of a string containing one or more "tokens", where such tokens are surrounded by curly brackets.
// If the token is preceded with ^, then it is a "one-time" binding, otherwise it is a "one-way" (continuously updated)
// binding.  Tokens can be negated (meaning their value will be converted to a boolean, and that value inverted) when
// preceded with !.  If both one-time binding and negation are specified for a token, the one-time binding indicator must
// appear first.
//
// Tokens that will resolve to numeric values may be followed by a colon and subsequent format specifier, using the .NET
// Framework 4.5 format specifiers for numeric values.
//
// For example:
//
//    "The scaling factor is {^scalingFactor:P2}".
//
// The token is a one-time binding that will resolve to a number and then be formatted as a percentage with two decimal places:
//
//    "The scaling factor is 140.00 %"
//
private var _braceContentsRE = Regex("[{]([^}]*)[}]");

public class PropertyValue
{
    var _formatString = ""; // Initialize to empty string - Otherwise Swift gets confused and thinks we using it
                            // before initializing when try to assign a value to it in the constructore.
    
    var _boundTokens: [BoundAndPossiblyResolvedToken];
    
    // Construct and return the unresolved binding contexts (the one-way bindings, excluding the one-time bindings)
    //
    public var BindingContexts: [BindingContext]
    {
        get
        {
            var bindingContexts = [BindingContext]();
            for boundToken in _boundTokens
            {
                if (!boundToken.resolved)
                {
                    bindingContexts.append(boundToken.bindingContext);
                }
            }
            return bindingContexts;
        }
    }
    
    public init(_ tokenString: String, bindingContext: BindingContext)
    {
        self._boundTokens = [BoundAndPossiblyResolvedToken]();
        var tokenIndex = 0;
        
        // !!! Escape any %
        
        _formatString = _braceContentsRE.substituteMatches(tokenString, substitution:
        {
            (match: String, matchGroups: [String]) -> String in
            
            logger.debug("Found bound token: \(matchGroups[1])");
    
            // Parse out any format specifier...
            //
            var token = matchGroups[1];
            var format: String?;
            if (token.contains(":"))
            {
                var result = token.componentsSeparatedByString(":");
                token = result[0];
                format = result[1];
            }

            // Parse out and record any one-time binding indicator
            //
            var oneTimeBinding = false;
            if (token.hasPrefix("^"))
            {
                token = token.substring(1);
                oneTimeBinding = true;
            }

            // Parse out and record negation indicator
            //
            var negated = false;
            if (token.hasPrefix("!"))
            {
                token = token.substring(1);
                negated = true;
            }

            var boundToken = BoundAndPossiblyResolvedToken(bindingContext.select(token), oneTime: oneTimeBinding, negated: negated, formatSpec: format);
            self._boundTokens.append(boundToken);

            return "%\(++tokenIndex)$@";
        });
    }

    public func expand() -> JToken?
    {
        if (_formatString == "%1$@")
        {
            // If there is a binding containing exactly a single token, then that token may resolve to
            // a value of any type (not just string), and we want to preserve that type, so we process
            // that special case here...
            //
            var token = _boundTokens[0];
            return token.resolvedValue;
        }
        else
        {
            // Otherwise we replace all tokens with the string representations of the values.
            //
            var resolvedTokens = [CVarArgType]();
            for boundToken in _boundTokens
            {
                resolvedTokens.append(boundToken.resolvedValueAsString);
            }
            
            return JValue(NSString(format: _formatString, arguments: getVaList(resolvedTokens)) as String);
        }
    }

    public class func containsBindingTokens(value: String) -> Bool
    {
        return value.contains("{");
    }

    public class func expand(tokenString: String, bindingContext: BindingContext) -> JToken?
    {
        var propertyValue = PropertyValue(tokenString, bindingContext: bindingContext);
        return propertyValue.expand();
    }

    public class func expandAsString(tokenString: String, bindingContext: BindingContext) -> String
    {
        var expandedToken = PropertyValue.expand(tokenString, bindingContext: bindingContext);
        return TokenConverter.toString(expandedToken);
    }
}

//
// Actual bindings: Property (one-way, composite) and Value (two-way, single value)
//

public typealias SetViewValue = (JToken?) -> (Void);
public typealias GetViewValue = () -> (JToken);

// For one-way binding of any property (binding to a pattern string than can incorporate multiple bound values)
//
public class PropertyBinding
{
    var _propertyValue: PropertyValue;
    var _setViewValue: SetViewValue;
    
    public init(bindingContext: BindingContext, value: String, setViewValue: SetViewValue)
    {
        _propertyValue = PropertyValue(value, bindingContext: bindingContext);
        _setViewValue = setViewValue;
    }
    
    public func updateViewFromViewModel()
    {
        self._setViewValue(_propertyValue.expand());
    }
    
    public var BindingContexts: [BindingContext] { get { return _propertyValue.BindingContexts; } }
}

// For two-way binding (typically of primary "value" property) - binding to a single value only
//
public class ValueBinding
{
    var _viewModel: ViewModel;
    var _bindingContext: BindingContext;
    var _getViewValue: GetViewValue;
    var _setViewValue: SetViewValue?;
    
    public var isDirty: Bool;
    
    public init(viewModel: ViewModel, bindingContext: BindingContext, getViewValue: GetViewValue, setViewValue: SetViewValue? = nil)
    {
        _viewModel = viewModel;
        _bindingContext = bindingContext;
        _getViewValue = getViewValue;
        _setViewValue = setViewValue;
        isDirty = false;
    }
    
    public func updateViewModelFromView()
    {
        _viewModel.updateViewModelFromView(_bindingContext, _getViewValue);
    }
    
    public func updateViewFromViewModel()
    {
        if (_setViewValue != nil)
        {
            _setViewValue!(_bindingContext.getValue()!);
        }
    }
    
    public var bindingContext: BindingContext { get { return _bindingContext; } }
}


