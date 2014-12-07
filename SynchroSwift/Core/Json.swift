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
    public var Type: JTokenType = JTokenType.Undefined;
    
    private init(_ type: JTokenType)
    {
        Type = type;
    }
    
    public func deepEquals(token: JToken?) -> Bool
    {
        assert(false, "This method must be overridden by the subclass");
    }
    
    public func deepClone() -> JToken
    {
        assert(false, "This method must be overridden by the subclass");
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
    
    public var Path: String
    {
        get
        {
            var useDotNotation = false;
            var path = "";
    
            var parent = Parent;
            if (parent != nil)
            {
                path += Parent!.Path;
    
                if (parent is JObject)
                {
                    var parentObject = parent as JObject;
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
                    var parentArray = parent as JArray;
                    var pos = find(parentArray, self);
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
    }

    var pathRegex = NSRegularExpression(pattern: "\\[(\\d+)\\]", options: nil, error: nil);
    
    public func selectToken(path: String, errorWhenNoMatch: Bool = false) -> JToken?
    {
        var thePath = NSMutableString(string: path);
        pathRegex?.replaceMatchesInString(thePath, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, thePath.length) , withTemplate: ".$1");

        var pathElements = String(thePath).componentsSeparatedByString(".");

        var currentToken: JToken? = self;
        for element in pathElements
        {
            if let currentArray = currentToken as? JArray
            {
                if let index = element.toInt()
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
                var parentObject = Parent as JObject;
                var key = parentObject.keyForValue(self);
                if (key != nil)
                {
                    parentObject[key!] = nil;
                    bRemoved = true;
                }
            }
            else if (Parent is JArray)
            {
                var parentArray = Parent as JArray;
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
    
        if (Parent != nil)
        {
            if (Parent is JObject)
            {
                var parentObject = Parent as JObject;
                var key = parentObject.keyForValue(self);
                if (key != nil)
                {
                    parentObject[key!] = token;
                    bReplaced = true;
                }
            }
            else if (Parent is JArray)
            {
                var parentArray = Parent as JArray;
                var pos = find(parentArray, self);
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
    
    public class func deepEquals(token1: JToken, token2: JToken) -> Bool
    {
        return ((token1 === token2) || token1.deepEquals(token2));
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
        var writer = StringBuilder();
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
    
    public init()
    {
        super.init(JTokenType.Object);
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
        var clone = JObject();
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
                _keys.filter { $0 != key };
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
            if (val == value)
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

    public init()
    {
        super.init(JTokenType.Array);
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
                for (index, token) in enumerate(_tokens)
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
        var clone = JArray();
        for element in _tokens
        {
            clone.append(element.deepClone());
        }
        return clone;
    }
    
    typealias Index = Int
    public var startIndex: Int { get { return _tokens.startIndex } }
    public var endIndex: Int { get { return _tokens.endIndex } }
    
    public var count: Int { get { return _tokens.count; } }
    
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
        if let index = find(_tokens, object)
        {
            var oldValue = _tokens.removeAtIndex(index)
            oldValue.Parent = nil;
            return true
        }
        return false
    }
}

public class JValue : JToken
{
    public var boolValue: Bool?;
    public var intValue: Int?;
    public var floatValue: Double?;
    public var stringValue: String?;
    
    private override init(_ type: JTokenType)
    {
        super.init(type);
    }
    
    // Copy constructor
    public convenience init(_ value: JValue)
    {
        self.init(value.Type);
        switch (Type)
        {
            case JTokenType.Boolean:
                boolValue = value.asBool()
            case JTokenType.Integer:
                intValue = value.asInt()
            case JTokenType.Float:
                floatValue = value.asDouble()
            case JTokenType.String:
                stringValue = value.asString()
            default: ()
        }
    }
    
    // nil value only
    public convenience init()
    {
        self.init(JTokenType.Null);
    }
    
    public convenience init(_ value: Bool)
    {
        self.init(JTokenType.Boolean);
        boolValue = value;
    }
    
    public convenience init(_ value: Int)
    {
        self.init(JTokenType.Integer);
        intValue = value;
    }

    public convenience init(_ value: Double)
    {
        self.init(JTokenType.Float);
        floatValue = value;
    }
    
    public convenience init(_ value: String)
    {
        self.init(JTokenType.String);
        stringValue = value;
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
            
            if (self.Type == other.Type)
            {
                switch (Type)
                {
                    case JTokenType.Null:
                        return true;
                    case JTokenType.Boolean:
                        return self.asBool() == other.asBool()
                    case JTokenType.Integer:
                        return self.asInt() == other.asInt()
                    case JTokenType.Float:
                        return self.asDouble() == other.asDouble()
                    case JTokenType.String:
                        return self.asString() == other.asString()
                    case JTokenType.Undefined:
                        return false;
                    default:
                        return false;
                }
            }
            else
            {
                // JToken Types do not match
                return false;
            }
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
        if (Type == JTokenType.Boolean)
        {
            return boolValue;
        }
        
        return nil;
    }

    public override func asInt() -> Int?
    {
        if (Type == JTokenType.Integer)
        {
            return intValue;
        }
        
        return nil;
    }

    public override func asDouble() -> Double?
    {
        if (Type == JTokenType.Float)
        {
            return floatValue;
        }
        else if (Type == JTokenType.Integer)
        {
            return Double(intValue!);
        }
        
        return nil;
    }

    public override func asString() -> String?
    {
        if (Type == JTokenType.String)
        {
            return stringValue;
        }
        
        return nil;
    }

}
