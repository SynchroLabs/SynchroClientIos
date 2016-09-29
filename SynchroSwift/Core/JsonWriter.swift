//
//  JsonWriter.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/4/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation


private var charSubstitutions: Dictionary<Character, String> =
[
    "\"": "\\\"",
    "\\": "\\\\",
    "/": "\\/",
    "\u{008}": "\\b",
    "\u{012}": "\\f",
    "\n": "\\n",
    "\r": "\\r",
    "\t": "\\t",
    "\r\n": "\\r\\n"
]

open class JsonWriter
{
    fileprivate class func WriteString(_ writer: StringBuilder, str: String)
    {
        writer.append("\"");
        for _codePoint in str.unicodeScalars
        {
            let _char = Character(_codePoint);
            if let subString = charSubstitutions[_char]
            {
                writer.append(subString);
            }
            else if ((_char < " ") || (!_codePoint.isASCII))
            {
                writer.append(String(format: "\\u%04x", _codePoint.value));
            }
            else
            {
                writer.append(_char);
            }
        }
        writer.append("\"");
    }

    fileprivate class func WriteNumber(_ writer: StringBuilder, i: Int)
    {
        writer.append(String(i));
    }

    fileprivate class func WriteNumber(_ writer: StringBuilder, d: Double)
    {
        writer.append(String(format: "%G", d)); // !!! Find correct format
    }

    fileprivate class func WriteArray(_ writer: StringBuilder, array: JArray)
    {
        var firstElement = true;
        
        writer.append("[");
        for value in array
        {
            if (!firstElement)
            {
                writer.append(",");
            }
            else
            {
                firstElement = false;
            }

            WriteValue(writer, value: value);
        }
        writer.append("]");
    }

    fileprivate class func WriteBoolean(_ writer: StringBuilder, b: Bool)
    {
        writer.append(b ? "true" : "false");
    }

    fileprivate class func WriteNull(_ writer: StringBuilder)
    {
        writer.append("null");
    }
    
    open class func WriteValue(_ writer: StringBuilder, value: JToken)
    {
        switch value.TokenType
        {
            case JTokenType.null:
                WriteNull(writer);
            case JTokenType.object:
                WriteObject(writer, obj: value as! JObject);
            case JTokenType.array:
                WriteArray(writer, array: value as! JArray);
            case JTokenType.string:
                WriteString(writer, str: value.asString()!);
            case JTokenType.integer:
                WriteNumber(writer, i: value.asInt()!);
            case JTokenType.float:
                WriteNumber(writer, d: value.asDouble()!);
            case JTokenType.boolean:
                WriteBoolean(writer, b: value.asBool()!);
            default:
                fatalError("Unknown object type \(value.TokenType)");
        }
    }

    fileprivate class func WriteObject(_ writer: StringBuilder, obj: JObject)
    {
        var firstKey = true;
        
        writer.append("{");
        for key in obj
        {
            if (!firstKey)
            {
                writer.append(",");
            }
            else
            {
                firstKey = false;
            }
            
            WriteString(writer, str: key);
            
            writer.append(":");
            
            WriteValue(writer, value: obj[key]!);
        }
        writer.append("}");
    }
}
