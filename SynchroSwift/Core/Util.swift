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
    func contains(_ find: String) -> Bool
    {
        return self.range(of: find) != nil;
    }
    
    func substring(_ startCharIndex: Int) -> String
    {
        return self[characters.index(startIndex, offsetBy: startCharIndex) ..< endIndex];
    }
    
    func lastIndexOf(_ find: Character) -> String.Index?
    {
        let findStr = String(find);
        let nsRange = self.range(of: findStr, options: NSString.CompareOptions.backwards);
        if let theRange = nsRange
        {
            return theRange.lowerBound;
        }
        return nil;
    }

    subscript (i: Int) -> String
    {
        return String(Array(self.characters)[i])
    }
    
    var length: Int { get { return self.characters.count; } }
}

extension UInt32
{
    func getBytes() -> [UInt8]
    {
        return[UInt8((self & 0xFF000000) >> 24), UInt8((self & 0x00FF0000) >> 16), UInt8((self & 0x0000FF00) >> 8), UInt8(self & 0x000000FF)];
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

open class Regex
{
    var _regex: NSRegularExpression?;
    
    public init(_ pattern: String)
    {
        do {
            _regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            _regex = nil
        };
        if (_regex == nil)
        {
            // parseError that can be caught is pretty useless (NSCocoaDomainError with a single kvp - "NSInvalidValue": pattern
            //
            assert(false, "Failed to create regular expression"); // !!! Handle this in production somehow (this is only for internal use / static regexes in code)
        }
    }

    public init(_ pattern: NSRegularExpression)
    {
        _regex = pattern;
    }

    open func substituteMatches(_ string: String, substitution: ((String, [String]) -> String), options: NSRegularExpression.MatchingOptions = NSRegularExpression.MatchingOptions(rawValue: 0)) -> String
    {
        let out = NSMutableString();
        var pos = 0;
        let target = string as NSString;
        let targetRange = NSRange(location: 0, length: target.length);
        
        _regex!.enumerateMatches(in: string, options: options, range: targetRange)
        {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            
            let matchRange = match!.range
            let matchString = String(target.substring(with: matchRange));
            var matchStrings = Array<String>();
            for index in 0...match!.numberOfRanges-1
            {
                matchStrings.append(String(target.substring(with: match!.rangeAt(index))));
            }
            out.append(target.substring(with: NSRange(location: pos, length: matchRange.location-pos)));
            out.append(substitution(matchString!, matchStrings));
            pos = matchRange.location + matchRange.length;
        }
        
        out.append(target.substring(with: NSRange(location: pos, length: targetRange.length-pos)))
        
        return String(out);
    }
    
    open func isMatch(_ string: String) -> Bool
    {
        if let matches = _regex?.matches(in: string, options: [], range: NSRange(location: 0, length: string.characters.count))
        {
            if matches.count > 0
            {
                return true;
            }
        }
        return false;
    }
}

extension Array
{
    func contains<T:AnyObject>(_ item:T) -> Bool
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
    
    mutating func removeObject<T:AnyObject>(_ item:T) -> Bool
    {
        var index: Int?;
        
        for (idx, currApp) in self.enumerated()
        {
            if (item === currApp as? T)
            {
                index = idx;
            }
        }
        
        if (index != nil)
        {
            self.remove(at: index!)
            return true
        }
        return false;
    }

}

open class Util
{
    open class func isIOS7() -> Bool
    {
        let os = ProcessInfo().operatingSystemVersion;
        return os.majorVersion >= 7;
    }
}


