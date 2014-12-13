//
//  Util.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

extension String
{
    func contains(find: String) -> Bool
    {
        return self.rangeOfString(find) != nil;
    }
    
    func substring(startCharIndex: Int) -> String
    {
        return self[Range(start: advance(startIndex, startCharIndex), end: endIndex)];
    }
    
    func lastIndexOf(find: Character) -> String.Index?
    {
        let findStr = String(find);
        var nsRange = self.rangeOfString(findStr, options: NSStringCompareOptions.BackwardsSearch);
        if let theRange = nsRange
        {
            return theRange.startIndex;
        }
        return nil;
    }

    var length: Int { get { return countElements(self); } }
}

extension UInt32
{
    func getBytes() -> [Byte]
    {
        return[Byte((self & 0xFF000000) >> 24), Byte((self & 0x00FF0000) >> 16), Byte((self & 0x0000FF00) >> 8), Byte(self & 0x000000FF)];
    }
}

public class Regex
{
    var _regex: NSRegularExpression?;
    
    public init(_ pattern: String)
    {
        var parseError: NSError?
        _regex = NSRegularExpression(pattern: pattern, options: nil, error: &parseError);
        if (_regex == nil)
        {
            // parseError is pretty useless (NSCocoaDomainError with a single kvp - "NSInvalidValue": pattern
            //
            assert(false, "Failed to create regular expression"); // !!! Handle this in production somehow (this is only for internal use / static regexes in code)
        }
    }

    public init(_ pattern: NSRegularExpression)
    {
        _regex = pattern;
    }

    public func substituteMatches(string: String, substitution: (String, [String]) -> String, options: NSMatchingOptions = nil) -> String
    {
        let out = NSMutableString();
        var pos = 0;
        let target = string as NSString;
        let targetRange = NSRange(location: 0, length: target.length);
        
        _regex!.enumerateMatchesInString(string, options: options, range: targetRange)
        {
            (match: NSTextCheckingResult!, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            
            let matchRange = match.range
            let matchString = String(target.substringWithRange(matchRange));
            var matchStrings = Array<String>();
            for index in 0...match.numberOfRanges-1
            {
                matchStrings.append(String(target.substringWithRange(match.rangeAtIndex(index))));
            }
            out.appendString(target.substringWithRange(NSRange(location: pos, length: matchRange.location-pos)));
            out.appendString(substitution(matchString, matchStrings));
            pos = matchRange.location + matchRange.length;
        }
        
        out.appendString(target.substringWithRange(NSRange(location: pos, length: targetRange.length-pos)))
        
        return String(out);
    }
}

