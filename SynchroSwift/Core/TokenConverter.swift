//
//  TokenConverter.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

// The TokenConverter is typically used by controls that require a value of a specific type when binding to a token, and 
// have a promise that they will coerce other types to the required type.  These supported conversions will be documented
// and supported for use by end-user developers.
//
//  Note: The point is not necessarily to convert "literally" (where, say, you would interpret the string "true" as the
//        boolean true), but to convert logically, at least in the realm of how we use tokens in Synchro. See below...
//
// An example of how token conversion works:  Suppose you have an edit control to enter search text, which has a two-way
// (value) binding to a token.  Suppose you have a search button that you only want to be enabled when there is text in
// the edit control.  By binding the "enabled" attribute of the button to the same token (which contains a string value),
// the token conversion means that the button will be disabled if the string is empty and enabled if not.
//
// Another example would be a in display a list of items.  Say you had a stackpanel containing a list caption, a list view,
// and some buttons that operated on the list contents.  The list contents themselves come from a token containing an array.
// By binding the "visibility" attribute of the containing stackpanel to the token containing the list, the entire group
// will be hidden if the list is empty, and it will be shown if the list is not empty.
//
// Finally, lets say in the example above, you wanted to display the number of items in the list.  You could use a property
// binding containing the binding token that references the list token, that when rendered as a string would get converted
// to the number of items in the list (in the underlying array).
//
public class TokenConverter
{
    public class func toString(token: JToken?, defaultValue: String = "") -> String
    {
        var result = defaultValue;
    
        if let theToken = token
        {
            switch (theToken.Type)
            {
                case JTokenType.Array:
                    let array = theToken as! JArray;
                    result = "\(array.count)";
                case JTokenType.String:
                    result = theToken.asString()!;
                case JTokenType.Integer:
                    result = "\(theToken.asInt()!)";
                case JTokenType.Float:
                    result = "\(theToken.asDouble()!)";
                case JTokenType.Boolean:
                    result = theToken.asBool()! ? "true" : "false";
                default:
                    result = theToken.asString() ?? defaultValue;
            }
        }
    
        return result;
    }
    
    public class func toBoolean(token: JToken?, defaultValue: Bool = false) -> Bool
    {
        var result = defaultValue;
    
        if let theToken = token
        {
            switch (theToken.Type)
            {
                case JTokenType.Boolean:
                    result = theToken.asBool()!;
                case JTokenType.String:
                    let str = theToken.asString()!;
                    result = str.characters.count > 0;
                case JTokenType.Float:
                    result = theToken.asDouble()! != 0;
                case JTokenType.Integer:
                    result = theToken.asInt() != 0;
                case JTokenType.Array:
                    let array = theToken as! JArray;
                    result = array.count > 0;
                case JTokenType.Object:
                    result = true;
                default: ()
            }
        }
    
        return result;
    }
    
    public class func toDouble(token: JToken?, defaultValue: Double? = nil) -> Double?
    {
        var result = defaultValue;
    
        if let theToken = token
        {
            switch (theToken.Type)
            {
                case JTokenType.String:
                    var scannedResult: Double = 0;
                    let scanner = NSScanner(string: theToken.asString()!);
                    if (scanner.scanDouble(&scannedResult))
                    {
                        result = scannedResult;
                    }
                
                case JTokenType.Float, JTokenType.Integer:
                    result = theToken.asDouble()!;
                case JTokenType.Array:
                    let array = theToken as! JArray
                    result = Double(array.count);
                default: ()
            }
        }
    
        return result;
    }
}
