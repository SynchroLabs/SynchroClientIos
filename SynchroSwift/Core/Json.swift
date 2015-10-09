//
//  Json.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/2/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

public enum JTokenType
{
    case Undefined
    case Object
    case Array
    case Integer
    case Float
    case String
    case Boolean
    case Null
}

// At global scope (as required by Swift to overload the equlaity operator and fulfill the Equatable protocol
//
public func ==(first: JToken, second: JToken) -> Bool
{
    return first.deepEquals(second);
}

public class JToken: Equatable
{
    // Should be overrided by all derived classes...
    public var Type: JTokenType { get { return JTokenType.Undefined; } }
    
    private init()
    {
    }
    
    public func deepEquals(token: JToken?) -> Bool
    {
        fatalError("This method must be overridden by the subclass");
    }
    
    public func deepClone() -> JToken
    {
        fatalError("This method must be overridden by the subclass");
    }
    
    var _parent: JToken?;
    
    var Parent: JToken?
    {
        get { return _parent; }
        set
        {
            if ((_parent != nil) && (newValue != nil))
            {
                // This is sort of a safety check. Parent objects/arrays manage the parent
                // references of their children, and will null them out when removing them,
                // so it should never be the case that the parent is getting set to non-null
                // when it is already non-null (owned by another parent).
                //
                assert(false, "JToken parent value already set");
            }
    
            _parent = newValue;
        }
    }

    var Root: JToken
    {
        get
        {
            var parent = Parent;
            if (parent == nil)
            {
                return self as JToken;
            }

            while (parent?.Parent != nil)
            {
                parent = parent?.Parent;
            }

            return parent!;
        }
    }
    
    private func getPath(useDotNotation: Bool = false) -> String
    {
        var path = "";
        
        let parent = Parent;
        if (parent != nil)
        {
            path += Parent!.getPath(useDotNotation);
        
            if (parent is JObject)
            {
                let parentObject = parent as! JObject;
                for key in parentObject
                {
                    if (parentObject[key]! == self)
                    {
                        if (!path.isEmpty)
                        {
                            path += ".";
                        }
                        path += key;
                        break;
                    }
                }
            }
            else if (parent is JArray)
            {
                let parentArray = parent as! JArray;
                let pos = parentArray.findChildIndex(self);
                if (useDotNotation)
                {
                    if (!path.isEmpty)
                    {
                        path += ".";
                    }
                    path += String(pos!);
                }
                else
                {
                    path += "[" + String(pos!) + "]";
                }
            }
        }
        
        return path;
    }
    
    public var Path: String
    {
        get
        {
            return getPath();
        }
    }

    var pathRegex = try? NSRegularExpression(pattern: "\\[(\\d+)\\]", options: []);
    
    public func selectToken(path: String, errorWhenNoMatch: Bool = false) -> JToken?
    {
        let thePath = NSMutableString(string: path);
        pathRegex?.replaceMatchesInString(thePath, options: NSMatchingOptions(), range: NSMakeRange(0, thePath.length) , withTemplate: ".$1");

        let pathElements = String(thePath).componentsSeparatedByString(".");

        var currentToken: JToken? = self;
        for element in pathElements
        {
            if let currentArray = currentToken as? JArray
            {
                if let index = Int(element)
                {
                    if index < currentArray.count
                    {
                        currentToken = currentArray[index];
                    }
                    else
                    {
                        // Array index out of range
                        currentToken = nil;
                        break;
                    }
                }
                else
                {
                    // Array index not numeric
                    currentToken = nil;
                    break;
                }
                
            }
            else if let currentObject = currentToken as? JObject
            {
                currentToken = currentObject[element];
                if (currentToken == nil)
                {
                    // Object key not found
                    break;
                }
            }
            else
            {
                // If you try to go into anything other than an object or array looking for a
                // child element, you are barking up the wrong tree...
                //
                // "The provided path did not resolve to a token"
                currentToken = nil;
                break;
            }
        }

        return currentToken;
    }


    // Remove this token from its parent
    //
    public func remove() -> Bool
    {
        var bRemoved = false;
    
        if (Parent != nil)
        {
            if (Parent is JObject)
            {
                let parentObject = Parent as! JObject;
                let key = parentObject.keyForValue(self);
                if (key != nil)
                {
                    parentObject[key!] = nil;
                    bRemoved = true;
                }
            }
            else if (Parent is JArray)
            {
                let parentArray = Parent as! JArray;
                bRemoved = parentArray.remove(self);
            }
    
            if (bRemoved && (Parent != nil))
            {
                // Parent should handle nulling parent when this item removed...
                assert(false, "Item was removed, but parent was not cleared");
            }
        }
    
        return bRemoved;
    }
    
    // Replace this token in its parent
    //
    public func replace(token: JToken) -> Bool
    {
        var bReplaced = false;
    
        if ((Parent != nil) && (token != self))
        {
            // Find ourself in our parent, and replace...
            //
            if (Parent is JObject)
            {
                let parentObject = Parent as! JObject;
                let key = parentObject.keyForValue(self);
                if (key != nil)
                {
                    parentObject[key!] = token;
                    bReplaced = true;
                }
            }
            else if (Parent is JArray)
            {
                let parentArray = Parent as! JArray;
                let pos = parentArray.findChildIndex(self);
                parentArray[pos!] = token;
                bReplaced = true;
            }
    
            if (bReplaced && (Parent != nil))
            {
                // Parent should handle nulling parent when this item removed...
                assert(false, "Item was replaced, but parent was not cleared");
            }
        }
    
        return bReplaced;
    }
    
    // Update a token to a new value, attempting to preserve the object graph to the extent possible
    //
    public class func updateTokenValue(inout currentToken: JToken, newToken: JToken) -> Bool
    {
        if (currentToken != newToken)
        {
            if ((currentToken is JValue) && (newToken is JValue))
            {
                // If the current token and the new token are both primitive values, then we just do a
                // value assignment...
                //
                (currentToken as! JValue).copyValueFrom(newToken as! JValue);
            }
            else
            {
                // Otherwise we have to replace the current token with the new token in the current token's parent...
                //
                if (currentToken.replace(newToken))
                {
                    currentToken = newToken;
                    return true; // Token change
                }
            }
        }
        return false; // Value-only change, or no change
    }
    
    public class func deepEquals(token1: JToken?, token2: JToken?) -> Bool
    {
        if (token1 == nil)
        {
            return token2 == nil;
        }
        else
        {
            return ((token1 === token2) || token1!.deepEquals(token2));
        }
    }
    
    public func asBool() -> Bool?
    {
        if let value = self as? JValue
        {
            return value.asBool();
        }
        return nil;
    }
    
    public func asInt() -> Int?
    {
        if let value = self as? JValue
        {
            return value.asInt();
        }
        return nil;
    }
    
    public func asDouble() -> Double?
    {
        if let value = self as? JValue
        {
            return value.asDouble();
        }
        return nil;
    }
    
    public func asString() -> String?
    {
        if let value = self as? JValue
        {
            return value.asString();
        }
        return nil;
    }
    
    public class func parse(str: String) -> JToken
    {
        return JsonParser.ParseValue(StringReader(str: str));
    }
    
    public func toJson() -> String
    {
        let writer = StringBuilder();
        JsonWriter.WriteValue(writer, value: self);
        return writer.toString();
    }
}

public class JObject : JToken, SequenceType
{
    // Because we need this to be an ordered dictionary, we need to keep a key array and a key,value dictionary
    //
    var _keys = Array<String>();
    var _tokens = Dictionary<String, JToken>();
    
    public override var Type: JTokenType { get { return JTokenType.Object; } }

    public override init()
    {
        super.init();
    }
    
    public convenience init(_ attributes: Dictionary<String, JToken>)
    {
        self.init();
        for (key, value) in attributes
        {
            value.Parent = self;
            _keys.append(key);
            _tokens[key] = value;
        }
    }
    
    public override func deepEquals(token: JToken?) -> Bool
    {
        if let other = token as? JObject
        {
            if (other === self)
            {
                // Same object
                return true;
            }
            else if self.count != other.count
            {
                // Different number of elements
                return false;
            }
            else
            {
                // Compare elements
                for key in _keys
                {
                    if !_tokens[key]!.deepEquals(other[key])
                    {
                        return false;
                    }
                }
                return true;
            }
        }
        else
        {
            // Other token was not a JObject
            return false;
        }
    }
    
    public override func deepClone() -> JToken
    {
        let clone = JObject();
        for key in _keys
        {
            clone[key] = _tokens[key]!.deepClone();
        }
        return clone;
    }

    public var count: Int { get { return _keys.count; } }
    
    // Our generator will just produce the keys, unlike a dictionary generator, which would produce (key, value)
    //
    public func generate() -> IndexingGenerator<Array<String>>
    {
        return _keys.generate();
    }

    public subscript(key: String) -> JToken?
    {
        get
        {
            return _tokens[key];
        }
        set(newValue)
        {
            if (newValue == nil)
            {
                if let oldValue = _tokens[key]
                {
                    oldValue.Parent = nil;
                }
                _tokens.removeValueForKey(key);
                _keys = _keys.filter { $0 != key };
                return;
            }
            
            newValue!.Parent = self;
            
            if let oldValue = _tokens.updateValue(newValue!, forKey: key)
            {
                oldValue.Parent = nil;
            }
            else
            {
                _keys.append(key)
            }
        }
    }
    
    func keyForValue(value: JToken) -> String?
    {
        for (key, val) in _tokens
        {
            if (val === value)
            {
                return key;
            }
        }
        return nil;
    }
}

public class JArray : JToken, SequenceType, CollectionType
{
    var _tokens = Array<JToken>();

    public override var Type: JTokenType { get { return JTokenType.Array; } }

    public override init()
    {
        super.init();
    }
    
    public convenience init(_ values: Array<JToken>)
    {
        self.init();
        for value in values
        {
            value.Parent = self;
            _tokens.append(value);
        }
    }
    
    public override func deepEquals(token: JToken?) -> Bool
    {
        if let other = token as? JArray
        {
            if other === self
            {
                // Same object
                return true;
            }
            else if self.count != other.count
            {
                // Different number of elements
                return false;
            }
            else
            {
                // Compare elements
                for (index, token) in _tokens.enumerate()
                {
                    if !token.deepEquals(other[index])
                    {
                        return false;
                    }
                }
                return true;
            }
        }
        else
        {
            // Other token was not a JArray
            return false;
        }
    }
    
    public override func deepClone() -> JToken
    {
        let clone = JArray();
        for element in _tokens
        {
            clone.append(element.deepClone());
        }
        return clone;
    }
    
    public typealias Index = Int
    public var startIndex: Int { get { return _tokens.startIndex } }
    public var endIndex: Int { get { return _tokens.endIndex } }
    
    public var count: Int { get { return _tokens.count; } }
    
    public func findChildIndex(child: JToken) -> Int?
    {
        for i in 0..._tokens.count
        {
            if (_tokens[i] === child)
            {
                return i
            }
        }
        
        return nil;
    }

    public func generate() -> IndexingGenerator<Array<JToken>>
    {
        return _tokens.generate()
    }
    
    public subscript(index: Int) -> JToken
    {
        get
        {
            return _tokens[index];
        }
        set(newValue)
        {
            _tokens[index].Parent = nil
            newValue.Parent = self;
            _tokens[index] = newValue;
            
        }
    }

    public func append(object: JToken)
    {
        object.Parent = self;
        _tokens.append(object);
    }
    
    public func remove(object: JToken) -> Bool
    {
        if let index = findChildIndex(object)
        {
            let oldValue = _tokens.removeAtIndex(index)
            oldValue.Parent = nil;
            return true
        }
        return false
    }
}

// This is how we do a union in Swift...
//
private enum ValueType: Equatable
{
    case ValueNull
    case ValueBool(Bool)
    case ValueInt(Int)
    case ValueFloat(Double)
    case ValueString(String)
}

private func ==(a: ValueType, b: ValueType) -> Bool
{
    switch (a, b)
    {
        case (.ValueNull, .ValueNull): return true
        case (.ValueBool(let a), .ValueBool(let b)) where a == b: return true
        case (.ValueInt(let a), .ValueInt(let b)) where a == b: return true
        case (.ValueFloat(let a), .ValueFloat(let b)) where a == b: return true
        case (.ValueString(let a), .ValueString(let b)) where a == b: return true
        default: return false
    }
}

public class JValue : JToken
{
    private var valueOfType = ValueType.ValueNull;
    
    public override var Type: JTokenType
    {
        get
        {
            switch self.valueOfType
            {
                case .ValueNull:
                    return JTokenType.Null;
                case .ValueBool:
                    return JTokenType.Boolean;
                case .ValueInt:
                    return JTokenType.Integer;
                case .ValueFloat:
                    return JTokenType.Float;
                case .ValueString:
                    return JTokenType.String;
            }
        }
    }

    public override init() // If called directly, creates default/Null value
    {
        super.init();
    }
    
    // Copy constructor
    public convenience init(_ value: JValue)
    {
        self.init();
        self.valueOfType = value.valueOfType;
    }
    
    public convenience init(_ value: Bool)
    {
        self.init();
        self.valueOfType = ValueType.ValueBool(value);
    }
    
    public convenience init(_ value: Int)
    {
        self.init();
        self.valueOfType = ValueType.ValueInt(value);
    }

    public convenience init(_ value: Double)
    {
        self.init();
        self.valueOfType = ValueType.ValueFloat(value);
    }
    
    public convenience init(_ value: String)
    {
        self.init();
        self.valueOfType = ValueType.ValueString(value);
    }
    
    public func copyValueFrom(value: JValue)
    {
        self.valueOfType = value.valueOfType;
    }
    
    public override func deepEquals(token: JToken?) -> Bool
    {
        if let other = token as? JValue
        {
            if other === self
            {
                // Same object
                return true;
            }
            return self.valueOfType == other.valueOfType;
        }
        else
        {
            // Other token was not a JValue
            return false;
        }
    }
    
    public override func deepClone() -> JToken
    {
        return JValue(self);
    }

    public override func asBool() -> Bool?
    {
        switch valueOfType
        {
            case .ValueBool(let boolValue):
                return boolValue;
            default:
                return nil;
        }
    }

    public override func asInt() -> Int?
    {
        switch valueOfType
        {
            case .ValueInt(let intValue):
                return intValue;
            default:
                return nil;
        }
    }

    public override func asDouble() -> Double?
    {
        switch valueOfType
        {
            case .ValueFloat(let doubleValue):
                return doubleValue;
            case .ValueInt(let intValue):
                return Double(intValue);
            default:
                return nil;
        }
    }

    public override func asString() -> String?
    {
        switch valueOfType
        {
            case .ValueString(let strValue):
                return strValue;
            default:
                return nil;
        }
    }
}
