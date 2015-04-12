//
//  DeviceMetrics.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

public enum SynchroDeviceClass : Int
{
    case Phone      = 0;
    case Phablet    = 1;
    case MiniTablet = 2;
    case Tablet     = 3;
    
    var description : String
    {
        switch self
        {
            case .Phone:      return "Phone";
            case .Phablet:    return "Phablet";
            case .MiniTablet: return "MiniTablet";
            case .Tablet:     return "Tablet";
        }
    }
}

public enum SynchroDeviceType : Int
{
    case Phone  = 0; // SynchroDeviceClass.Phone
    case Tablet = 3; // SynchroDeviceClass.Tablet
    
    var description : String
    {
        switch self
        {
            case .Phone:  return "Phone";
            case .Tablet: return "Tablet";
        }
    }

}

public enum SynchroOrientation
{
    case Portrait;
    case Landscape;
    
    var description : String
    {
        switch self
        {
            case .Portrait:  return "Portrait";
            case .Landscape: return "Landscape";
        }
    }
}

public class DeviceMetrics
{
    private var _deviceClass = SynchroDeviceClass.Phone;
    
    private var _naturalOrientation = SynchroOrientation.Portrait;
    
    private var _os = "Unknown"; // Short name for filtering, ie: Windows, WinPhone, iOS, Android
    private var _osName = "Unknown";
    // !!! OS version would be nice
    
    private var _deviceName = "Unknown";
    
    private var _widthInches: Double = 0;
    private var _heightInches: Double = 0;
    
    private var _widthDeviceUnits: Double = 0;
    private var _heightDeviceUnits: Double = 0;
    private var _deviceScalingFactor: Double = 1;
    
    private var _scalingFactor: Double = 1;
    
    // Device details
    //
    public var OS: String { get { return _os; } }
    public var OSName: String { get { return _osName; } }
    public var DeviceName: String { get { return _deviceName; } }
    
    // Device type
    //
    public var DeviceClass: SynchroDeviceClass { get { return _deviceClass; } }
    public var DeviceType: SynchroDeviceType
    {
        get
        {
            return ((_deviceClass == SynchroDeviceClass.Phone) || (_deviceClass == SynchroDeviceClass.Phablet)) ? SynchroDeviceType.Phone : SynchroDeviceType.Tablet;
        }
    }
    
    public var NaturalOrientation: SynchroOrientation { get { return _naturalOrientation; } }
    
    // Physical dimensions of device
    //
    public var WidthInches: Double { get { return _widthInches; } }
    public var HeightInches: Double { get { return _heightInches; } }
    
    // Logical dimensions of device
    //
    // "Device Units" is a general term to describe whatever units are used to position and size objects in the target environment.
    // In iOS this unit is the "point" (a term Apple uses, not to be confused with a typographic point).  In Android, this unit is
    // actually the physical pixel value.  In WinPhone this is the "view pixels" value (a virtual coordinate space).
    //
    public var WidthDeviceUnits: Double { get { return _widthDeviceUnits; } }
    public var HeightDeviceUnits: Double { get { return _heightDeviceUnits; } }
    
    // Device scaling factor is the ratio of device units to physical pixels.  This can be used to determine an appropriately sized
    // image resource, for example.
    //
    public var DeviceScalingFactor: Double { get { return _deviceScalingFactor; } }
    
    // Dimensions of device
    //
    public var WidthUnits: Double { get { return _widthDeviceUnits / _scalingFactor; } }
    public var HeightUnits: Double { get { return _heightDeviceUnits / _scalingFactor; } }
    
    // Scaling factor is the ratio of logic units to device units.
    //
    public var ScalingFactor: Double { get { return _scalingFactor; } }
    
    // Coordinate space mapping
    //
    // Note: In the explanations below, all units attributed to a device or OS are "device units" (meaning whatever unit
    // coordinate/size metric is used on the device).  These are typically scaled or transformed in some way by the device
    // operating system to map to the underlying display pixels (and will in fact be scaled on most contemporary devices,
    // which will have displays with significantly higher actual native pixel resolutions).
    //
    // For "phone-like" (portrait-first) devices we will scale the display to be 480 Maaas units wide, and maintain the device
    // aspect ratio - meaning that the height in Maaas units will vary from 720 (3.5" iPhone/iPod) to 853 (16:9 Win/Android
    // phone).  This will work well as the Windows phones are already 480 logical units wide, and the iOS devices are
    // 320 (so it's a simple 1.5x transform).  The Android devices will use pixel widths, but will typically be a pretty
    // clean transform (the screens will tend to be 480, 720, or 1080 pixels).
    //
    // For "tablet-like" (landscape-first) devices we will scale the display to be 768 Maaas units tall, and maintain the device
    // aspect ratio - meaning that the width in Maaas units will vary from 1024 (iPad/iPad Mini) to 1368 (Surface), with other
    // tablets falling somewhere in this range.  This means we will not need to do any scaling on iOS or Windows, and that the
    // android transforms will be fairly clean.
    //
    // Note: Every device currently in existence has square pixels, so we don't need to track h/v scale independently.
    //
    private func updateScalingFactor() // Call from constructor after device units set
    {
        if (DeviceType == SynchroDeviceType.Phone)
        {
            _scalingFactor = _widthDeviceUnits / 480;
        }
        else
        {
            _scalingFactor = _heightDeviceUnits / 768;
        }
    }
    
    public func SynchroUnitsToDeviceUnits(synchroUnits: Double) -> Double
    {
        return synchroUnits * _scalingFactor;
    }
    
    // Font scaling - to convert font points (typographic points) to Maaas units, we need to normalize for all "phone" types
    // using a theoritical model phone with "average" dimensions.  The idea is that on all phone devices, fonts of a given
    // size should take up about the same relative amount of screen real estate (so that layouts will scale).
    //
    //     Model phone
    //     ===============================
    //     Screen size: 4.25"
    //     Aspect: 480x800 units (assume these are Maaas units)
    //     Diagnonal units (932.95) / Screen size in inches (4.25") = 219.52 units/inch
    //
    //     Since 72 (typographic points per inch) times 3 = 216, which is very close to the computed value above,
    //     we're just going to use a factor of 3x to convert from typographic points to Maaas units (this will also
    //     make it easy for Maaas UX designers to understand the relationship of typographic points to Maaas units).
    //
    public func TypographicPointsToMaaasUnits(points: Double) -> Double
    {
        // Convert typographic point values (72pt/inch) to Maaas units (219.52units/inch on model phone)
        //
        return points * 3;
    }
    
    // iOS - Specific logic
    
    private class func iPadMini(device: UIDevice) -> Bool
    {
        // http://theiphonewiki.com/wiki/Models
        //
        let iPadMiniNames =
        [
            "iPad2,5", // Mini
            "iPad2,6", //
            "iPad2,7", //
            "iPad4,4", // Retina Mini
            "iPad4,5"  //
        ];
        
        return contains(iPadMiniNames, device.machine);
    }
    
    private var _controller: UIViewController;
    
    public init (controller: UIViewController)
    {
        _controller = controller;
        _os = "iOS";
        _osName = "iOS";
        
        // Device         Screen size  Logical resolution  Logical ppi  Width (in)  Height (in)
        // =============  ===========  ==================  ===========  ==========  ===========
        // iPhone / iPod     3.5"           320 x 480           163       1.963       2.944
        // iPhone / iPod     4.0"           320 x 568           163       1.963       3.485
        // iPad              9.7"           768 x 1024          132       5.818       7.758
        // iPad Mini         7.85"          768 x 1024          163       4.712       6.282
        
        // Screen size in inches is logical resolution divided by logical ppi
        // Physical ppi is logical ppi times scale
        
        var currentDevice = UIDevice.currentDevice();
        
        var mainScreen = UIScreen.mainScreen();
        
        if (currentDevice.userInterfaceIdiom == UIUserInterfaceIdiom.Phone)
        {
            _deviceName = "iPhone/iPod";
            _deviceClass = SynchroDeviceClass.Phone;
            _naturalOrientation = SynchroOrientation.Portrait;
            
            _widthInches = 1.963;
            if (mainScreen.bounds.size.height == 568)
            {
                _heightInches = 3.485;
            }
            else
            {
                _heightInches = 2.944;
            }
        }
        else if (DeviceMetrics.iPadMini(currentDevice))
        {
            _deviceName = "iPad Mini";
            _deviceClass = SynchroDeviceClass.MiniTablet;
            _naturalOrientation = SynchroOrientation.Landscape;
            
            _widthInches = 6.282;
            _heightInches = 4.712;
        }
        else
        {
            _deviceName = "iPad";
            _deviceClass = SynchroDeviceClass.Tablet;
            _naturalOrientation = SynchroOrientation.Landscape;
            
            _widthInches = 7.758;
            _heightInches = 5.818;
        }
        
        if (_naturalOrientation == SynchroOrientation.Portrait)
        {
            // MainScreen.Bounds assumes portrait layout
            _widthDeviceUnits = Double(mainScreen.bounds.size.width);
            _heightDeviceUnits = Double(mainScreen.bounds.size.height);
        }
        else
        {
            _heightDeviceUnits = Double(mainScreen.bounds.size.width);
            _widthDeviceUnits = Double(mainScreen.bounds.size.height);
        }
        
        _deviceScalingFactor = Double(mainScreen.scale);
        
        self.updateScalingFactor();
        
    }
    
    public var CurrentOrientation: SynchroOrientation
    {
        get
        {
            if ((_controller.interfaceOrientation == UIInterfaceOrientation.LandscapeLeft) ||
                (_controller.interfaceOrientation == UIInterfaceOrientation.LandscapeRight))
            {
                return SynchroOrientation.Landscape;
            }
            else
            {
                return SynchroOrientation.Portrait;
            }
        }
    }
}

// Did I mention no class/static vars in Swift?
//
private let _deviceList =
[
    "i386":         "Simulator",
    "x86_64":       "Simulator",
    "iPod1,1":      "iPod Touch",       // (Original)
    "iPod2,1":      "iPod Touch 2",     // (Second Generation)
    "iPod3,1":      "iPod Touch 3",     // (Third Generation)
    "iPod4,1":      "iPod Touch 4",     // (Fourth Generation)
    "iPhone1,1":    "iPhone 1",         // (Original)
    "iPhone1,2":    "iPhone 3G",        // (3G)
    "iPhone2,1":    "iPhone 3GS",       // (3GS)
    "iPad1,1":      "iPad 1",           // (Original)
    "iPad2,1":      "iPad 2",           //
    "iPad3,1":      "iPad 3",           // (3rd Generation)
    "iPhone3,1":    "iPhone 4",         //
    "iPhone4,1":    "iPhone 4S",        //
    "iPhone5,1":    "iPhone 5",         // (model A1428, AT&T/Canada)
    "iPhone5,2":    "iPhone 5",         // (model A1429, everything else)
    "iPad3,4":      "iPad 4",           // (4th Generation)
    "iPad2,5":      "iPad Mini 1",      // (Original)
    "iPhone5,3":    "iPhone 5c",        // (model A1456, A1532 | GSM)
    "iPhone5,4":    "iPhone 5c",        // (model A1507, A1516, A1526 (China), A1529 | Global)
    "iPhone6,1":    "iPhone 5s",        // (model A1433, A1533 | GSM)
    "iPhone6,2":    "iPhone 5s",        // (model A1457, A1518, A1528 (China), A1530 | Global)
    "iPad4,1":      "iPad Air 1",       // 5th Generation iPad (iPad Air) - Wifi
    "iPad4,2":      "iPad Air 2",       // 5th Generation iPad (iPad Air) - Cellular
    "iPad4,4":      "iPad Mini 2",      // (2nd Generation iPad Mini - Wifi)
    "iPad4,5":      "iPad Mini 2",      // (2nd Generation iPad Mini - Cellular)
    "iPhone7,1":    "iPhone 6 Plus",    // All iPhone 6 Plus's
    "iPhone7,2":    "iPhone 6"          // All iPhone 6's
]

// Machine name is not really supported in Swift, so this is how you do it...
//
public extension UIDevice {
    var machine: String {
        var systemInfo: utsname = utsname(sysname: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            nodename: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            release: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            version: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            machine: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        var identifier = ""
        let mirror = reflect(machine)
        for i in 0..<reflect(machine).count {
            if mirror[i].1.value as! Int8 == 0 {
                break
            }
            identifier.append(UnicodeScalar(UInt8(mirror[i].1.value as! Int8)))
        }
        return identifier
    }
    
    var modelName: String? { get { return _deviceList[machine] } };
}
