//
//  BindingContext.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("BindingContext");

private var _bindingTokensRE = Regex("[$]([^.]*)[.]?"); // Token starts with $, separated by dot

// Corresponds to a specific location in a JSON oject (which may or may not exist at the time the BindingContext is created).
//
public class BindingContext
{
    var _bindingRoot: JObject;
    
    var _bindingPath = "";
    var _boundToken: JToken?;
    var _isIndex = false;
    
    public var BindingRoot: JObject
    {
        get { return _bindingRoot; }
        set (value)
        {
            if (value !== _bindingRoot)
            {
                _bindingRoot = value;
                self.rebind();
            }
        }
    }
    
    // Creates the root binding context, from which all other binding contexts will be created
    //
    public init(_ bindingRoot: JObject)
    {
        _bindingRoot = bindingRoot;
        _boundToken = _bindingRoot;
    }
    
    private func attemptToBindTokenIfNeeded()
    {
        if (_boundToken == nil)
        {
            _boundToken = _bindingRoot.selectToken(_bindingPath);
        }
    }
    
    private func resolveBinding(var parentPath: String, bindingPath: String) -> String
    {
        // Process path elements:
        //
        //  $root
        //  $parent
        //  $data
        //  $index
        //
        //  The processing below might be overkill.  In practice, any $root path element should be at the beginning
        //  of the token string.  Any $parent element (including more than one) should be at the beginning of the token
        //  string.  Since these strings are literal and never programmatically constructed, it would be nonsensical to
        //  navigate explicilty down some desendant path and then back up to the root or a parent.  Also, since $index
        //  is just a flag (and will cause the bindingContext to find its most immediate array index), it will appear
        //  by itself.  Likewise, $data is nonsensical other than when appearing by itself.
        //
        //  So realistically, the cases of bindingPath that need to be handled are:
        //
        //  $root.some.path ($root at beginning of binding path, no further specials in path)
        //  $parent.$parent.some.path (one or more $parent elements at beginning of binding path, no further specials in path)
        //  $index
        //  $data
        //
        let processedBindingPath = _bindingTokensRE.substituteMatches(bindingPath, substitution:
        {
            (match: String, matchGroups: [String]) -> String in

            let pathElement = matchGroups[1];
            logger.debug("Found binding path element: \(pathElement)");
            
            if (pathElement == "root")
            {
                parentPath = "";
            }
            else if (pathElement == "parent")
            {
                if (!parentPath.isEmpty)
                {
                    var pathComponents = parentPath.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "."));
                    
                    if (pathComponents.count == 1)
                    {
                        // Remove the only remaining path segment
                        parentPath = "";
                    }
                    else if (pathComponents.count > 1)
                    {
                        // Remove the last (rightmost) path segment
                        pathComponents.removeLast();
                        parentPath = pathComponents.joinWithSeparator(".");
                    }
                }
            }
            else if (pathElement == "data")
            {
                // We're going to treat $data as a noop
            }
            else if (pathElement == "index")
            {
                self._isIndex = true;
            }
            
            return ""; // Removing the path elements as they are processed
        });
        
        var finalBindingPath = processedBindingPath;
        if ((!parentPath.isEmpty) && (!processedBindingPath.isEmpty))
        {
            finalBindingPath = parentPath + "." + processedBindingPath;
        }
        else if (!parentPath.isEmpty)
        {
            finalBindingPath = parentPath;
        }
        
        logger.debug("Resolved binding path is: \(finalBindingPath)");
        
        return finalBindingPath;
    }
    
    private init(_ context: BindingContext, bindingPath: String)
    {
        _bindingRoot = context._bindingRoot;
        _bindingPath = resolveBinding(context._bindingPath, bindingPath: bindingPath);
        self.attemptToBindTokenIfNeeded();
    }
    
    private init(_ context: BindingContext, index: Int, bindingPath: String)
    {
        _bindingRoot = context._bindingRoot;
        _bindingPath = resolveBinding("\(context._bindingPath)[\(index)]", bindingPath: bindingPath);
        self.attemptToBindTokenIfNeeded();
    }
    
    //
    // Public interface starts here...
    //
    
    // Given a path to a changed element, determine if the binding is impacted.
    //
    public func isBindingUpdated(updatedElementPath: String, objectChange: Bool) -> Bool
    {
        if (objectChange && (_bindingPath.hasPrefix(updatedElementPath)))
        {
            // If this is an object change (meaning the object/array itself changed), then a binding
            // update is required if the path matches or is an ancestor of the binging path.
            //
            return true;
        }
        else if (_bindingPath == updatedElementPath)
        {
            // If this is a primitive value change, or an object/array contents change (meaning
            // that the object itself did not change), then a binding update is only required if
            // the path matches exactly.
            //
            return true;
        }
    
        return false;
    }
    
    public func select(bindingPath: String) -> BindingContext
    {
        return BindingContext(self, bindingPath: bindingPath);
    }
    
    public func selectEach(bindingPath: String) -> Array<BindingContext>
    {
        var bindingContexts = Array<BindingContext>();
    
        if (JTokenType.Array == _boundToken?.Type)
        {
            var index = 0;
            for _ in _boundToken as! JArray
            {
                bindingContexts.append(BindingContext(self, index: index, bindingPath: bindingPath));
                index++;
            }
        }
    
        return bindingContexts;
    }
    
    public var BindingPath: String { get { return _bindingPath; } }
    
    public func getValue() -> JToken?
    {
        self.attemptToBindTokenIfNeeded();
        if (_boundToken != nil)
        {
            if (_isIndex)
            {
                // Find first ancestor that is an array and get the position of that ancestor's child
                //
                var child = _boundToken;
                var parent = child?.Parent;
    
                while (parent != nil)
                {
                    if let parentArray = parent as? JArray
                    {
                        let pos = parentArray.indexOf(child!);
                        return JValue(pos! as Int);
                    }
                    else
                    {
                        child = parent;
                        parent = child?.Parent;
                    }
                }
            }
            else
            {
                return _boundToken;
            }
        }
    
        // Token could not be bound at this time (no corresponding token) - no value returned!
        return nil;
    }
    
    // Return boolean indicating whether the bound token was changed (and rebinding needs to be triggered)
    //
    public func setValue(value: JToken) -> Bool
    {
        self.attemptToBindTokenIfNeeded();
        if (_boundToken != nil)
        {
            if (!_isIndex)
            {
                return JToken.updateTokenValue(&_boundToken!, newToken: value);
            }
        }
    
        // Token could not be bound at this time (no corresponding token) - value not set!
        return false;
    }
    
    public func rebind()
    {
        _boundToken = _bindingRoot.selectToken(_bindingPath);
    }
}
