//
//  JsonParser.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/2/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


public extension Character
{
    public func isOneOf(_ chars: String) -> Bool
    {
        for char in chars.characters
        {
            if (self == char)
            {
                return true;
            }
        }
        
        return false;
    }
}

public extension String
{
    public func containsChars(_ chars: String) -> Bool
    {
        for strChar in self.characters
        {
            for searchChar in chars.characters
            {
                if (strChar == searchChar)
                {
                    return true;
                }
            }
        }
        return false;
    }
}

public protocol TextReader
{
    @discardableResult
    func peek() -> Character?
    @discardableResult
    func read() -> Character?
}

open class StringReader : TextReader
{
    fileprivate var _str: String;
    fileprivate var _currIndex: String.Index;
    
    public init(str: String)
    {
        _str = str;
        _currIndex = _str.startIndex;
    }
    
    @discardableResult
    open func peek() -> Character?
    {
        if (_currIndex >= _str.endIndex)
        {
            return nil;
        }
        return _str[_currIndex];
    }
    
    @discardableResult
    open func read() -> Character?
    {
        let chr = peek();
        if (chr != nil)
        {
            _currIndex = _str.index(_currIndex, offsetBy: 1);
        }
        return chr;
     }
}

open class StringBuilder
{
    fileprivate var stringValue: String
    
    public init(string: String = "")
    {
        self.stringValue = string
    }
    
    open func toString() -> String
    {
        return stringValue
    }
    
    @discardableResult
    open func append(_ string: String) -> StringBuilder
    {
        stringValue += string
        return self
    }

    @discardableResult
    open func append(_ char: Character) -> StringBuilder
    {
        stringValue.append(char);
        return self
    }
}

var whitespace = CharacterSet.whitespacesAndNewlines;

open class JsonParser
{
    class func isWhiteSpace(_ char: Character?) -> Bool
    {
        if (char == nil)
        {
            return false;
        }
        let uniStr = String(char!).unicodeScalars;
        let uniChar = uniStr[uniStr.startIndex];
        return whitespace.contains(UnicodeScalar(uniChar.value)!);
    }
    
    class func SkipWhitespace(_ reader: TextReader)
    {
        while (isWhiteSpace(reader.peek()) || (reader.peek() == "/"))
        {
            while (isWhiteSpace(reader.peek()))
            {
                reader.read();
            }
    
            if (reader.peek() == "/")
            {
                reader.read(); // Eat the initial /
                var nextChar = reader.read();
    
                if (nextChar == "/")
                {
                    while ((reader.peek() != "\r\n") && (reader.peek() != "\r") && (reader.peek() != "\n") && (reader.peek() != nil))
                    {
                        reader.read();
                    }
                }
                else /* nextChar assumed to be a * */
                {
                    while (true)
                    {
                        nextChar = reader.read();
        
                        if (nextChar == nil)
                        {
                            break;
                        }
                        else if (nextChar == "*")
                        {
                            // If the next character is a '/' eat it, otherwise keep going
            
                            if (reader.peek() == "/")
                            {
                                reader.read();
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    class func ParseString(_ reader: TextReader) -> String
    {
        var thisChar: Character?;
        let returnString = StringBuilder();
    
        SkipWhitespace(reader);
    
        // Skip the opening quotes
    
        reader.read();
    
        // Read until closing quotes
        
        while (reader.peek() != "\"")
        {
            thisChar = reader.read();
            if (thisChar == nil)
            {
                assert(false, "Unexpected end of stream");
            }
    
            if (thisChar == "\\")
            {
                thisChar = reader.read();
    
                switch (thisChar!)
                {
                    case "b":
                        thisChar = "\u{008}";
                    case "f":
                        thisChar = "\u{012}";
                    case "r":
                        thisChar = "\r";
                    case "n":
                        thisChar = "\n";
                    case "t":
                        thisChar = "\t";
                    case "u":
                        // Parse four hex digits
                        let hexBuilder = StringBuilder();
                        for _ in 0 ..< 4
                        {
                            hexBuilder.append(reader.read()!);
                        }
                        let scanner = Scanner(string: hexBuilder.toString());
                        var result: UInt32 = 0;
                        if (scanner.scanHexInt32(&result))
                        {
                            thisChar = Character(UnicodeScalar(result)!);
                        }
                    default: ()
                }
            }
    
            returnString.append(thisChar!);
        }
        
        // Skip closing quote
        
        reader.read();
    
        return returnString.toString();
    }

    class func ParseNumber(_ reader: TextReader) -> JValue
    {
        let numberBuilder = StringBuilder();
    
        SkipWhitespace(reader);
    
        while let chr = reader.peek()
        {
            if (!chr.isOneOf("0123456789Ee.-+"))
            {
                break;
            }
            numberBuilder.append(reader.read()!);
        }
    
        let numberData = numberBuilder.toString();
        
        if (numberData.containsChars("eE."))
        {
            let scanner = Scanner(string: numberData);
            var result: Double = 0;
            if (!scanner.scanDouble(&result))
            {
                assert(false, "Conversion to double failed");
            }
            return JValue(result);
        }
        else
        {
            return JValue(Int(numberData)!);
        }
    }

    class func ParseArray(_ reader: TextReader) -> JArray
    {
        let finalArray = JArray();
    
        SkipWhitespace(reader);
    
        // Skip the opening bracket
    
        reader.read();
    
        SkipWhitespace(reader);
    
        // Read until closing bracket
    
        while (reader.peek() != "]")
        {
            // Read a value
        
            finalArray.append(ParseValue(reader));
        
            SkipWhitespace(reader);
        
            // Skip the comma if any
        
            if (reader.peek() == ",")
            {
                reader.read();
            }
        
            SkipWhitespace(reader);
        }
    
        // Skip the closing bracket
    
        reader.read();
    
        return finalArray;
    }

    class func ParseObject(_ reader: TextReader) -> JObject
    {
        let finalObject = JObject();
    
        SkipWhitespace(reader);
    
        // Skip the opening brace
    
        reader.read();
    
        SkipWhitespace(reader);
    
        // Read until closing brace
    
        while (reader.peek() != "}")
        {
            var name: String;
            var value: JToken;
    
            // Read a string
    
            name = ParseString(reader);
    
            SkipWhitespace(reader);
    
            // Skip the colon
    
            reader.read();
    
            SkipWhitespace(reader);
    
            // Read the value
    
            value = ParseValue(reader);
    
            SkipWhitespace(reader);
    
            finalObject[name] = value;
    
            // Skip the comma if any
    
            if (reader.peek() == ",")
            {
                reader.read();
            }
    
            SkipWhitespace(reader);
        }

        // Skip the closing brace

        reader.read();

        return finalObject;
    }

    class func ParseTrue(_ reader: TextReader) -> Bool
    {
        // Skip 't', 'r', 'u', 'e'
    
        reader.read();
        reader.read();
        reader.read();
        reader.read();
    
        return true;
    }

    class func ParseFalse(_ reader: TextReader) -> Bool
    {
        // Skip 'f', 'a', 'l', 's', 'e'
    
        reader.read();
        reader.read();
        reader.read();
        reader.read();
        reader.read();
    
        return false;
    }

    class func ParseNull(_ reader: TextReader)
    {
        // Skip 'n', 'u', 'l', 'l'
    
        reader.read();
        reader.read();
        reader.read();
        reader.read();
    }

    class func ParseValue(_ reader: TextReader) -> JToken
    {
        SkipWhitespace(reader);
    
        let lookahead = reader.peek();
    
        if ((lookahead == "-") || ((lookahead >= "0") && (lookahead <= "9")))
        {
            return ParseNumber(reader);
        }
        else if (lookahead == "[")
        {
            return ParseArray(reader);
        }
        else if (lookahead == "{")
        {
            return ParseObject(reader);
        }
        else if (lookahead == "t")
        {
            return JValue(ParseTrue(reader));
        }
        else if (lookahead == "f")
        {
            return JValue(ParseFalse(reader));
        }
        else if (lookahead == "n")
        {
            ParseNull(reader)
            return JValue();
        }
        else
        {
            return JValue(ParseString(reader));
        }
    }
}
