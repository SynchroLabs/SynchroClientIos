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
    case undefined
    case object
    case array
    case integer
    case float
    case string
    case boolean
    case null
}

// At global scope (as required by Swift to overload the equlaity operator and fulfill the Equatable protocol
//
public func ==(first: JToken, second: JToken) -> Bool
{
    return first.deepEquals(second);
}

open class JToken: Equatable
{
    // Should be overrided by all derived classes...
    open var TokenType: JTokenType { get { return JTokenType.undefined; } }
    
    fileprivate init()
    {
    }
    
    open func deepEquals(_ token: JToken?) -> Bool
    {
        fatalError("This method must be overridden by the subclass");
    }
    
    open func deepClone() -> JToken
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
    
    fileprivate func getPath(_ useDotNotation: Bool = false) -> String
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
    
    open var Path: String
    {
        get
        {
            return getPath();
        }
    }

    var pathRegex = try? NSRegularExpression(pattern: "\\[(\\d+)\\]", options: []);
    
    open func selectToken(_ path: String, errorWhenNoMatch: Bool = false) -> JToken?
    {
        let thePath = NSMutableString(string: path);
        pathRegex?.replaceMatches(in: thePath, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, thePath.length) , withTemplate: ".$1");

        let pathElements = String(thePath).components(separatedBy: ".");

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
    open func remove() -> Bool
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
    open func replace(_ token: JToken) -> Bool
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
    open class func updateTokenValue(_ currentToken: inout JToken, newToken: JToken) -> Bool
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
    
    open class func deepEquals(_ token1: JToken?, token2: JToken?) -> Bool
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
    
    open func asBool() -> Bool?
    {
        if let value = self as? JValue
        {
            return value.asBool();
        }
        return nil;
    }
    
    open func asInt() -> Int?
    {
        if let value = self as? JValue
        {
            return value.asInt();
        }
        return nil;
    }
    
    open func asDouble() -> Double?
    {
        if let value = self as? JValue
        {
            return value.asDouble();
        }
        return nil;
    }
    
    open func asString() -> String?
    {
        if let value = self as? JValue
        {
            return value.asString();
        }
        return nil;
    }
    
    open class func parse(_ str: String) -> JToken
    {
        return JsonParser.ParseValue(StringReader(str: str));
    }
    
    open func toJson() -> String
    {
        let writer = StringBuilder();
        JsonWriter.WriteValue(writer, value: self);
        return writer.toString();
    }
}

open class JObject : JToken, Sequence
{
    // Because we need this to be an ordered dictionary, we need to keep a key array and a key,value dictionary
    //
    var _keys = Array<String>();
    var _tokens = Dictionary<String, JToken>();
    
    open override var TokenType: JTokenType { get { return JTokenType.object; } }

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
    
    open override func deepEquals(_ token: JToken?) -> Bool
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
    
    open override func deepClone() -> JToken
    {
        let clone = JObject();
        for key in _keys
        {
            clone[key] = _tokens[key]!.deepClone();
        }
        return clone;
    }

    open var count: Int { get { return _keys.count; } }
    
    // Our generator will just produce the keys, unlike a dictionary generator, which would produce (key, value)
    //
    open func makeIterator() -> IndexingIterator<Array<String>>
    {
        return _keys.makeIterator();
    }

    open subscript(key: String) -> JToken?
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
                _tokens.removeValue(forKey: key);
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
    
    func keyForValue(_ value: JToken) -> String?
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

open class JArray : JToken, Sequence, Collection
{
    var _tokens = Array<JToken>();

    open override var TokenType: JTokenType { get { return JTokenType.array; } }

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
    
    open override func deepEquals(_ token: JToken?) -> Bool
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
                for (index, token) in _tokens.enumerated()
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
    
    open override func deepClone() -> JToken
    {
        let clone = JArray();
        for element in _tokens
        {
            clone.append(element.deepClone());
        }
        return clone;
    }
    
    public typealias Index = Int
    open var startIndex: Int { get { return _tokens.startIndex } }
    open var endIndex: Int { get { return _tokens.endIndex } }
    
    open var count: Int { get { return _tokens.count; } }
    
    open func findChildIndex(_ child: JToken) -> Int?
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

    open func makeIterator() -> IndexingIterator<Array<JToken>>
    {
        return _tokens.makeIterator()
    }
    
    open subscript(index: Int) -> JToken
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

    open func append(_ object: JToken)
    {
        object.Parent = self;
        _tokens.append(object);
    }
    
    open func remove(_ object: JToken) -> Bool
    {
        if let index = findChildIndex(object)
        {
            let oldValue = _tokens.remove(at: index)
            oldValue.Parent = nil;
            return true
        }
        return false
    }

    open func index(after: Int) -> Int
    {
        return _tokens.index(after: after);
    }
}

// This is how we do a union in Swift...
//
private enum ValueType: Equatable
{
    case valueNull
    case valueBool(Bool)
    case valueInt(Int)
    case valueFloat(Double)
    case valueString(String)
}

private func ==(a: ValueType, b: ValueType) -> Bool
{
    switch (a, b)
    {
        case (.valueNull, .valueNull): return true
        case (.valueBool(let a), .valueBool(let b)) where a == b: return true
        case (.valueInt(let a), .valueInt(let b)) where a == b: return true
        case (.valueFloat(let a), .valueFloat(let b)) where a == b: return true
        case (.valueString(let a), .valueString(let b)) where a == b: return true
        default: return false
    }
}

open class JValue : JToken
{
    fileprivate var valueOfType = ValueType.valueNull;
    
    open override var TokenType: JTokenType
    {
        get
        {
            switch self.valueOfType
            {
                case .valueNull:
                    return JTokenType.null;
                case .valueBool:
                    return JTokenType.boolean;
                case .valueInt:
                    return JTokenType.integer;
                case .valueFloat:
                    return JTokenType.float;
                case .valueString:
                    return JTokenType.string;
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
        self.valueOfType = ValueType.valueBool(value);
    }
    
    public convenience init(_ value: Int)
    {
        self.init();
        self.valueOfType = ValueType.valueInt(value);
    }

    public convenience init(_ value: Double)
    {
        self.init();
        self.valueOfType = ValueType.valueFloat(value);
    }
    
    public convenience init(_ value: String)
    {
        self.init();
        self.valueOfType = ValueType.valueString(value);
    }
    
    open func copyValueFrom(_ value: JValue)
    {
        self.valueOfType = value.valueOfType;
    }
    
    open override func deepEquals(_ token: JToken?) -> Bool
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
    
    open override func deepClone() -> JToken
    {
        return JValue(self);
    }

    open override func asBool() -> Bool?
    {
        switch valueOfType
        {
            case .valueBool(let boolValue):
                return boolValue;
            default:
                return nil;
        }
    }

    open override func asInt() -> Int?
    {
        switch valueOfType
        {
            case .valueInt(let intValue):
                return intValue;
            default:
                return nil;
        }
    }

    open override func asDouble() -> Double?
    {
        switch valueOfType
        {
            case .valueFloat(let doubleValue):
                return doubleValue;
            case .valueInt(let intValue):
                return Double(intValue);
            default:
                return nil;
        }
    }

    open override func asString() -> String?
    {
        switch valueOfType
        {
            case .valueString(let strValue):
                return strValue;
            default:
                return nil;
        }
    }
}
