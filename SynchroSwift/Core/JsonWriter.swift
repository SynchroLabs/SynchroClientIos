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

public class JsonWriter
{
    private class func WriteString(writer: StringBuilder, str: String)
    {
        writer.append("\"");
        for _codePoint in str.unicodeScalars
        {
            var _char = Character(_codePoint);
            if let subString = charSubstitutions[_char]
            {
                writer.append(subString);
            }
            else if ((_char < " ") || (!_codePoint.isASCII()))
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

    private class func WriteNumber(writer: StringBuilder, i: Int)
    {
        writer.append(String(i));
    }

    private class func WriteNumber(writer: StringBuilder, d: Double)
    {
        writer.append(String(format: "%G", d)); // !!! Find correct format
    }

    private class func WriteArray(writer: StringBuilder, array: JArray)
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

    private class func WriteBoolean(writer: StringBuilder, b: Bool)
    {
        writer.append(b ? "true" : "false");
    }

    private class func WriteNull(writer: StringBuilder)
    {
        writer.append("null");
    }
    
    public class func WriteValue(writer: StringBuilder, value: JToken)
    {
        switch value.Type
        {
            case JTokenType.Null:
                WriteNull(writer);
            case JTokenType.Object:
                WriteObject(writer, obj: value as! JObject);
            case JTokenType.Array:
                WriteArray(writer, array: value as! JArray);
            case JTokenType.String:
                WriteString(writer, str: value.asString()!);
            case JTokenType.Integer:
                WriteNumber(writer, i: value.asInt()!);
            case JTokenType.Float:
                WriteNumber(writer, d: value.asDouble()!);
            case JTokenType.Boolean:
                WriteBoolean(writer, b: value.asBool()!);
            default:
                fatalError("Unknown object type \(value.Type)");
        }
    }

    private class func WriteObject(writer: StringBuilder, obj: JObject)
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
