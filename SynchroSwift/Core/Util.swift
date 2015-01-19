//
//  Util.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

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

    subscript (i: Int) -> String
    {
        return String(Array(self)[i])
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

extension CGRect
{
    // These property adapters are all to make porting easier (Xamarin provides these properties in this way, and that's
    // how we use them in the Xamarin iOS project).  They're also just a little cleaner.
    //
    var x: CGFloat
    {
        get { return self.origin.x }
        set(value) { self.origin.x = value }
    }
    var y: CGFloat
    {
        get { return self.origin.y }
        set(value) { self.origin.y = value }
    }
    var width: CGFloat
    {
        get { return self.size.width }
        set(value) { self.size.width = value }
    }
    var height: CGFloat
    {
        get { return self.size.height }
        set(value) { self.size.height = value }
    }
    var left: CGFloat
    {
        get { return self.origin.x }
    }
    var top: CGFloat
    {
        get { return self.origin.y }
    }
    var right: CGFloat
    {
        get { return self.origin.x + self.size.width }
    }
    var bottom: CGFloat
    {
        get { return self.origin.y + self.size.height }
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
    
    public func isMatch(string: String) -> Bool
    {
        if let matches = _regex?.matchesInString(string, options: nil, range: NSRange(location: 0, length: countElements(string)))
        {
            if countElements(matches) > 0
            {
                return true;
            }
        }
        return false;
    }
}

extension Array
{
    func contains<T:AnyObject>(item:T) -> Bool
    {
        for element in self
        {
            if item === element as? T
            {
                return true
            }
        }
        return false
    }
    
    mutating func removeObject<T:AnyObject>(item:T) -> Bool
    {
        var index: Int?;
        
        for (idx, currApp) in enumerate(self)
        {
            if (item === currApp as? T)
            {
                index = idx;
            }
        }
        
        if (index != nil)
        {
            self.removeAtIndex(index!)
            return true
        }
        return false;
    }

}

public class Util
{
    public class func isIOS7() -> Bool
    {
        let os = NSProcessInfo().operatingSystemVersion;
        return os.majorVersion >= 7;
    }
}


