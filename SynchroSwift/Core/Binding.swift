//
//  Binding.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import JavaScriptCore

private var logger = Logger.getLogger("Binding");

open class BindingHelper
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
    open class func getCanonicalBindingSpec(_ controlSpec: JObject, defaultBindingAttribute: String, commandAttributes: [String]? = nil) -> JObject?
    {
        var bindingObject: JObject? = nil;
    
        var defaultAttributeIsCommand = false;
        if (commandAttributes != nil)
        {
            defaultAttributeIsCommand = (commandAttributes!).contains(defaultBindingAttribute);
        }
        
        if let bindingSpec = controlSpec["binding"]
        {
            if (bindingSpec.TokenType == JTokenType.object)
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
                        bindingObject![commandAttribute] = JObject(["command": JValue(bindingObject![commandAttribute] as! JValue)]);
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
open class BoundAndPossiblyResolvedToken
{
    var _bindingContext: BindingContext;
    var _resolvedValue: JToken?;
    
    // OK - The way negation is handled here is pretty crude.  The idea is that in the future we will support
    // complex value converters, perhaps even functions which themselves have more than one token as parameters.
    // So a more generalized concept of a value converter (delegate) passed in here from the parser and used
    // to produce the resolved value would be better.
    //
    var _negated = false;
    
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
    
    open var bindingContext: BindingContext { get { return _bindingContext; } }
    
    open var resolved: Bool { get { return _resolvedValue != nil; } }
    
    open var resolvedValue: JToken?
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
    
    open var resolvedValueAsString: String
    {
        get
        {
            if let formatSpec = _formatSpec
            {
                // This is where we apply formatSpec to format numbers...
                //
                // This is what we have for formatting on iOS: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
                //
                // And we support some defined subset of: http://msdn.microsoft.com/en-us/library/dwhawy9k(v=vs.110).aspx
                //
                // If formatting succeeds, return formatted, else fall through to general (non-formatted) result
                //
                if let numericValue = TokenConverter.toDouble(resolvedValue)
                {
                    let formatSpecifier = formatSpec[0];
                    var formatPrecision: Int? = nil;
                    if formatSpec.length > 1
                    {
                        formatPrecision = Int(formatSpec.substring(1));
                        if (formatPrecision == nil)
                        {
                            logger.error("Format precision was provided, but was not an integer, was: \"\(formatSpec.substring(1))\"");
                        }
                    }
                    
                    switch formatSpecifier
                    {
                        case "C", "c": // Currency
                            logger.error("Currency formatting not supported");
                        
                        case "D", "d": // Decimal
                            let intVal = Int(numericValue);
                            let formatter = NumberFormatter();
                            formatter.numberStyle = NumberFormatter.Style.decimal;
                            formatter.usesGroupingSeparator = false;
                            formatter.roundingMode = NumberFormatter.RoundingMode.halfUp;
                            formatter.roundingIncrement = 0;
                            if (formatPrecision != nil)
                            {
                                formatter.minimumIntegerDigits = formatPrecision!
                            }
                            if let result = formatter.string(from: intVal as NSNumber)
                            {
                                return result;
                            }
                            else
                            {
                                logger.error("Decimal formatting failed");
                            }
                        
                        case "E", "e": // Exponential
                            let formatter = NumberFormatter();
                            formatter.numberStyle = NumberFormatter.Style.scientific;
                            formatter.maximumSignificantDigits = formatPrecision ?? 6; // 6 is the default on .NET (all locales)
                            formatter.maximumSignificantDigits += 1; // Apparently, on .NET this is the number of digits after the decimal point, so we correct for that
                            formatter.minimumSignificantDigits = formatter.maximumSignificantDigits;
                            formatter.exponentSymbol = formatSpecifier;
                            if let result = formatter.string(from: numericValue as NSNumber)
                            {
                                return result;
                            }
                            else
                            {
                                logger.error("Fixed-point formatting failed");
                        }
                        
                        case "F", "f": // Fixed-point
                            let decimalPlaces = formatPrecision ?? 2;  // 2 digits is the en_US locale default on .NET
                            let formatter = NumberFormatter();
                            formatter.numberStyle = NumberFormatter.Style.decimal;
                            formatter.usesGroupingSeparator = false;
                            formatter.roundingMode = NumberFormatter.RoundingMode.halfUp;
                            formatter.minimumFractionDigits = decimalPlaces;
                            formatter.maximumFractionDigits = decimalPlaces;
                            if let result = formatter.string(from: numericValue as NSNumber)
                            {
                                return result;
                            }
                            else
                            {
                                logger.error("Fixed-point formatting failed");
                            }
                        
                        case "G", "g": // General
                            logger.error("General formatting not supported");
                        
                        case "N", "n": // Number
                            let decimalPlaces = formatPrecision ?? 2;  // 2 digits is the en_US locale default on .NET
                            let formatter = NumberFormatter();
                            formatter.numberStyle = NumberFormatter.Style.decimal;
                            formatter.roundingMode = NumberFormatter.RoundingMode.halfUp;
                            formatter.minimumFractionDigits = decimalPlaces;
                            formatter.maximumFractionDigits = decimalPlaces;
                            if let result = formatter.string(from: numericValue as NSNumber)
                            {
                                return result;
                            }
                            else
                            {
                                logger.error("Number formatting failed");
                            }
                        
                        case "P", "p": // Percent
                            let decimalPlaces = formatPrecision ?? 2; // 2 digits is the en_US locale default on .NET
                            let formatter = NumberFormatter();
                            formatter.numberStyle = NumberFormatter.Style.percent;
                            formatter.roundingMode = NumberFormatter.RoundingMode.halfUp;
                            formatter.maximumFractionDigits = decimalPlaces;
                            formatter.minimumFractionDigits = decimalPlaces;
                            if let result = formatter.string(from: numericValue as NSNumber)
                            {
                                return result;
                            }
                            else
                            {
                                logger.error("Percentage formatting failed");
                            }

                        case "R", "r": // Round-trip
                            logger.error("Round-trip formatting not supported");

                        case "X":
                            if  (numericValue >= 0)
                            {
                                if formatPrecision != nil
                                {
                                    return String(format: "%0*X", formatPrecision!, UInt(numericValue));
                                }
                                else
                                {
                                    return String(format: "%X", UInt(numericValue));
                                }
                            }
                            else
                            {
                                logger.error("Hex formatting not support on negative values like: \(numericValue)");
                            }
                        
                        case "x": // Hex
                            if  (numericValue >= 0)
                            {
                                if formatPrecision != nil
                                {
                                    return String(format: "%0*x", formatPrecision!, UInt(numericValue));
                                }
                                else
                                {
                                    return String(format: "%x", UInt(numericValue));
                                }
                            }
                            else
                            {
                                logger.error("Hex formatting not support on negative values like: \(numericValue)");
                            }
                        
                        default:
                            logger.error("Unknown numeric format specification: \"\(formatSpecifier)\"");
                    }
                }
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
//    "The scaling factor is 140.00%"
//

// To deal with "escaped" braces (double open braces), our brace contents regex checks around our potential open brace
// to see if another one precedes or follows is using:
//
//     Negative lookbehind (zero length assertion to make sure brace not preceded by brace) = (?!<[}])
//     Negative lookahead (zero length assertion to make sure brace not followed by brace) = {?![}])
//
private var _braceContentsRE = Regex("(?<![{])[{](?![{])([^}]*)[}]");

open class PropertyValue
{
    var _formatString = ""; // Initialize to empty string - Otherwise Swift gets confused and thinks we using it
                            // before initializing when try to assign a value to it in the constructore.
    var _isExpression = false;
    
    var _boundTokens: [BoundAndPossiblyResolvedToken];
    
    // Construct and return the unresolved binding contexts (the one-way bindings, excluding the one-time bindings)
    //
    open var BindingContexts: [BindingContext]
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
        
        var theTokenString = tokenString;
        
        let prefix = "eval(";
        let suffix = ")";
        if (theTokenString.hasPrefix(prefix) && theTokenString.hasSuffix(suffix))
        {
            _isExpression = true;
            let newStartIndex = theTokenString.characters.index(theTokenString.startIndex, offsetBy: prefix.length);
            let newEndIndex = theTokenString.characters.index(theTokenString.endIndex, offsetBy: -suffix.length);
            theTokenString = theTokenString.substring(with: newStartIndex..<newEndIndex);
            logger.debug("Propery value string is expresion: \(theTokenString)");
        }
        else
        {
            // Escape any % to %% (format string will unescape them for us when called later)
            //
            theTokenString = tokenString.replacingOccurrences(of: "%", with: "%%", options: NSString.CompareOptions.literal, range: nil)
        }
        
        _formatString = _braceContentsRE.substituteMatches(theTokenString, substitution:
        {
            (match: String, matchGroups: [String]) -> String in
            
            logger.debug("Found bound token: \(matchGroups[1])");
    
            // Parse out any format specifier...
            //
            var token = matchGroups[1];
            var format: String?;
            if (token.contains(":"))
            {
                var result = token.components(separatedBy: ":");
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

            let boundToken = BoundAndPossiblyResolvedToken(bindingContext.select(token), oneTime: oneTimeBinding, negated: negated, formatSpec: format);
            self._boundTokens.append(boundToken);

            // Expressions get var0, var1, etc, whereas format string gets %1$@, %2$@, etc
            //
            let replacementToken = self._isExpression ? "var\(tokenIndex)" : "%\(tokenIndex + 1)$@";
            tokenIndex += 1;
            
            return replacementToken;
        });
        
        // De-escape any escaped braces...
        //
        _formatString = _formatString.replacingOccurrences(of: "{{", with: "{", options: NSString.CompareOptions.literal, range: nil)
        _formatString = _formatString.replacingOccurrences(of: "}}", with: "}", options: NSString.CompareOptions.literal, range: nil)
        
        logger.debug("PropertValue - isExpression: \(_isExpression), formatString: \(_formatString)");
    }

    open func expand() -> JToken?
    {
        if (_isExpression)
        {
            let context = JSContext();
            
            // Set up our bound tokens as JS variables
            //
            var index = 0;
            for boundToken in _boundTokens
            {
                let resolvedValue = boundToken.resolvedValue;
                if (resolvedValue?.TokenType == JTokenType.boolean)
                {
                    context?.setObject(resolvedValue?.asBool(), forKeyedSubscript: "var\(index)" as (NSCopying & NSObjectProtocol)!);
                }
                else if (resolvedValue?.TokenType == JTokenType.integer)
                {
                    context?.setObject(resolvedValue?.asInt(), forKeyedSubscript: "var\(index)" as (NSCopying & NSObjectProtocol)!);
                }
                else if (resolvedValue?.TokenType == JTokenType.float)
                {
                    context?.setObject(resolvedValue?.asDouble(), forKeyedSubscript: "var\(index)" as (NSCopying & NSObjectProtocol)!);
                }
                else if (resolvedValue?.TokenType == JTokenType.null)
                {
                    context?.setObject(JSValue.init(nullIn: context), forKeyedSubscript: "var\(index)" as (NSCopying & NSObjectProtocol)!);
                }
                else
                {
                    context?.setObject(boundToken.resolvedValueAsString, forKeyedSubscript: "var\(index)" as (NSCopying & NSObjectProtocol)!);
                }
                index += 1;
            }
            
            let result: JSValue = context!.evaluateScript(_formatString);
            
            if (result.isBoolean)
            {
                return JValue(result.toBool());
            }
            else if (result.isNumber)
            {
                let doubleVal = result.toNumber().doubleValue;
                if (floor(doubleVal) == doubleVal)
                {
                    // Int
                    return JValue(Int(doubleVal));
                }
                else
                {
                    // Double
                    return JValue(doubleVal);
                }
            }
            else if (result.isNull)
            {
                return JValue();
            }
            else
            {
                return JValue(result.toString());
            }
        }
        else if (_formatString == "%1$@")
        {
            // If there is a binding containing exactly a single token, then that token may resolve to
            // a value of any type (not just string), and we want to preserve that type, so we process
            // that special case here...
            //
            let token = _boundTokens[0];
            return token.resolvedValue;
        }
        else
        {
            // Otherwise we replace all tokens with the string representations of the values.
            //
            var resolvedTokens = [CVarArg]();
            for boundToken in _boundTokens
            {
                resolvedTokens.append(boundToken.resolvedValueAsString);
            }
            
            return JValue(NSString(format: _formatString, arguments: getVaList(resolvedTokens)) as String);
        }
    }

    open class func containsBindingTokens(_ value: String) -> Bool
    {
        return _braceContentsRE.isMatch(value);
    }

    open class func expand(_ tokenString: String, bindingContext: BindingContext) -> JToken?
    {
        let propertyValue = PropertyValue(tokenString, bindingContext: bindingContext);
        return propertyValue.expand();
    }

    open class func expandAsString(_ tokenString: String, bindingContext: BindingContext) -> String
    {
        let expandedToken = PropertyValue.expand(tokenString, bindingContext: bindingContext);
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
open class PropertyBinding
{
    var _propertyValue: PropertyValue;
    var _setViewValue: SetViewValue?;
    
    public init(bindingContext: BindingContext, value: String, setViewValue: SetViewValue?)
    {
        _propertyValue = PropertyValue(value, bindingContext: bindingContext);
        _setViewValue = setViewValue;
    }
    
    @discardableResult
    open func updateViewFromViewModel() -> JToken?
    {
        let value = _propertyValue.expand();
        if (_setViewValue != nil)
        {
            self._setViewValue!(value);
        }
        return value;
    }
    
    open var BindingContexts: [BindingContext] { get { return _propertyValue.BindingContexts; } }
}

// For two-way binding (typically of primary "value" property) - binding to a single value only
//
open class ValueBinding
{
    var _viewModel: ViewModel;
    var _bindingContext: BindingContext;
    var _getViewValue: GetViewValue;
    var _setViewValue: SetViewValue?;
    
    open var isDirty: Bool;
    
    public init(viewModel: ViewModel, bindingContext: BindingContext, getViewValue: @escaping GetViewValue, setViewValue: SetViewValue? = nil)
    {
        _viewModel = viewModel;
        _bindingContext = bindingContext;
        _getViewValue = getViewValue;
        _setViewValue = setViewValue;
        isDirty = false;
    }
    
    open func updateViewModelFromView()
    {
        _viewModel.updateViewModelFromView(_bindingContext, getValue: _getViewValue);
    }
    
    open func updateViewFromViewModel()
    {
        if (_setViewValue != nil)
        {
            _setViewValue!(_bindingContext.getValue());
        }
    }
    
    open var bindingContext: BindingContext { get { return _bindingContext; } }
}


