//
//  DeviceMetrics.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("DeviceMetrics");

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
    private var _clientName = NSBundle.mainBundle().infoDictionary?["CFBundleName"] as! String;
    private var _clientVersion = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String;
    
    private var _deviceClass = SynchroDeviceClass.Phone;
    
    private var _naturalOrientation = SynchroOrientation.Portrait;
    
    private var _os = "Unknown"; // Short name for filtering, ie: Windows, WinPhone, iOS, Android
    private var _osName = "Unknown";
    // !!! OS version would be nice
    
    private var _deviceName: String;// = "Unknown";
    
    private var _widthInches: Double = 0;
    private var _heightInches: Double = 0;
    
    private var _widthDeviceUnits: Double = 0;
    private var _heightDeviceUnits: Double = 0;
    private var _deviceScalingFactor: Double = 1;
    
    private var _scalingFactor: Double = 1;
    
    // Client details
    //
    public var ClientName: String { get { return _clientName; } }
    public var ClientVersion: String { get { return _clientVersion; } }
    
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
    
    private var _controller: UIViewController;
    
    public init (controller: UIViewController)
    {
        _controller = controller;
        _os = "iOS";
        _osName = "iOS";
        
        let currentDevice = UIDevice.currentDevice();
        let mainScreen = UIScreen.mainScreen();
        
        // The reason we use nativeBounds below is that it is not dependent on the current device orientation (it is always
        // based on "portrait up" orientation).  Because it is in pixels instead of points, we have to divide by scale.
        //
        if (_naturalOrientation == SynchroOrientation.Portrait)
        {
            _widthDeviceUnits = Double(mainScreen.nativeBounds.size.width/mainScreen.scale);
            _heightDeviceUnits = Double(mainScreen.nativeBounds.size.height/mainScreen.scale);
        }
        else
        {
            _heightDeviceUnits = Double(mainScreen.nativeBounds.size.width/mainScreen.scale);
            _widthDeviceUnits = Double(mainScreen.nativeBounds.size.height/mainScreen.scale);
        }
        
        // Device         Screen size  Logical resolution  Logical ppi  Width (in)  Height (in)
        // =============  ===========  ==================  ===========  ==========  ===========
        // iPhone / iPod     3.5"           320 x 480           163       1.963       2.944
        // iPhone / iPod     4.0"           320 x 568           163       1.963       3.485
        // iPhone / iPod     4.7"           375 x 667           164.25    2.283       4.094
        // iPhone / iPod     5.5"           414 x 736           153.56    2.696       4.794
        // iPad              9.7"           768 x 1024          132       5.818       7.758
        // iPad Mini         7.85"          768 x 1024          163       4.712       6.282
        
        // Screen size in inches is logical resolution divided by logical ppi
        // Physical ppi is logical ppi times scale
        
        if (currentDevice.userInterfaceIdiom == UIUserInterfaceIdiom.Phone)  // iPhone or iPod devices
        {
            _deviceName = currentDevice.modelName ?? "iPhone/iPod";
            _deviceClass = SynchroDeviceClass.Phone;
            _naturalOrientation = SynchroOrientation.Portrait;
            
            let pointsHeight = Int(round(_heightDeviceUnits));
            
            _widthInches = 1.963;
            _heightInches = 2.944;
            
            if (pointsHeight == 568)
            {
                _heightInches = 3.485;
            }
            else if (pointsHeight == 667)
            {
                _widthInches = 2.283;
                _heightInches = 4.094;
            }
            else if (pointsHeight == 736)
            {
                _widthInches = 2.696;
                _heightInches = 4.794;
            }
        }
        else // iPad devices (including mini)
        {
            _deviceName = currentDevice.modelName ?? "iPad";
            _naturalOrientation = SynchroOrientation.Landscape;
            
            if (_deviceName.hasPrefix("iPad Mini"))
            {
                _deviceClass = SynchroDeviceClass.MiniTablet;
                
                _widthInches = 6.282;
                _heightInches = 4.712;
            }
            else
            {
                _deviceClass = SynchroDeviceClass.Tablet;
                
                _widthInches = 7.758;
                _heightInches = 5.818;
            }
        }
        
        logger.info("Current device \(currentDevice.machine) - name: \(_deviceName)");

        _deviceScalingFactor = Double(mainScreen.scale);
        
        self.updateScalingFactor();
        
    }
    
    public var CurrentOrientation: SynchroOrientation
    {
        get
        {
            if (UIScreen.mainScreen().bounds.width < UIScreen.mainScreen().bounds.height)
            {
                return SynchroOrientation.Portrait;
            }
            else
            {
                return SynchroOrientation.Landscape;
            }
        }
    }
}

// Machine name is not really supported in Swift, so this is how you do it...
//
// http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift
// https://github.com/dennisweissmann/Basics/blob/master/Device.swift
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
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 where value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    var modelName: String?
    {
        get
        {
            switch machine
            {
                case "iPod5,1":                                  return "iPod Touch 5"
                case "iPod7,1":                                  return "iPod Touch 6"
                case "iPhone3,1", "iPhone3,2", "iPhone3,3":      return "iPhone 4"
                case "iPhone4,1":                                return "iPhone 4s"
                case "iPhone5,1", "iPhone5,2":                   return "iPhone 5"
                case "iPhone5,3", "iPhone5,4":                   return "iPhone 5c"
                case "iPhone6,1", "iPhone6,2":                   return "iPhone 5s"
                case "iPhone7,2":                                return "iPhone 6"
                case "iPhone7,1":                                return "iPhone 6 Plus"
                case "iPhone8,1":                                return "iPhone 6s"
                case "iPhone8,2":                                return "iPhone 6s Plus"
                case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
                case "iPad3,1", "iPad3,2", "iPad3,3":            return "iPad 3"
                case "iPad3,4", "iPad3,5", "iPad3,6":            return "iPad 4"
                case "iPad4,1", "iPad4,2", "iPad4,3":            return "iPad Air"
                case "iPad5,1", "iPad5,3", "iPad5,4":            return "iPad Air 2"
                case "iPad2,5", "iPad2,6", "iPad2,7":            return "iPad Mini"
                case "iPad4,4", "iPad4,5", "iPad4,6":            return "iPad Mini 2"
                case "iPad4,7", "iPad4,8", "iPad4,9":            return "iPad Mini 3"
                case "iPad5,1", "iPad5,2":                       return "iPad Mini 4"
                case "i386", "x86_64":                           return self.model.contains("Sim") ? self.model : self.model + " (Simulator)";
                default:                                         return nil
            }
        }
    }
}
