//
//  iOSLocationWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import CoreLocation

private var logger = Logger.getLogger("iOSLocationWrapper");

private var commands = [CommandName.OnUpdate.Attribute];

open class iOSLocationWrapper : iOSControlWrapper, CLLocationManagerDelegate
{
    
    var _updateOnChange = false;
    
    var _locMgr: CLLocationManager?;
    
    var _status: LocationStatus = LocationStatus.unknown;
    var _location: CLLocation?;

    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating location element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);

        self._isVisualElement = false;
        
        let threshold = toDouble(controlSpec["movementThreshold"], defaultValue: 100);
        
        _locMgr = CLLocationManager();
        if let locMgr = _locMgr
        {
            locMgr.delegate = self;
            _status = fromNativeStatus(CLLocationManager.authorizationStatus());
            logger.info("Native status: \(CLLocationManager.authorizationStatus()), Synchro status: \(_status)");
            
            if (CLLocationManager.locationServicesEnabled())
            {
                
                if (locMgr.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)))
                {
                    // RequestWhenInUseAuthorization is only present in iOS 8.0 and later.  If available, we need
                    // to call it to get authorized (using our custom message defined in Info.plist under the key:
                    // NSLocationWhenInUseUsageDescription).  If not present, we don't call it (prior to iOS 8.0,
                    // the operating system just pops up a generic permission dialog automatically when the below
                    // location services are accessed).
                    //
                    locMgr.requestWhenInUseAuthorization();
                }
                
                locMgr.desiredAccuracy = 100; //desired accuracy, in meters
                locMgr.distanceFilter = threshold;
                locMgr.startUpdatingLocation();
                logger.info("Status: \(CLLocationManager.authorizationStatus()) after");
                logger.info("Location services started");
            }
            else
            {
                logger.info("Location services not enabled");
                _status = LocationStatus.notAvailable;
            }
        }
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value", commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
            
            processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in
                let obj = JObject(
                [
                    "available": JValue((self._status == LocationStatus.available) || (self._status == LocationStatus.active)),
                    "status": JValue(self._status.description)
                ]);
                
                if let location = self._location
                {
                    obj["coordinate"] = JObject(
                    [
                        "latitude": JValue(location.coordinate.latitude),
                        "longitude": JValue(location.coordinate.longitude)
                    ]);
                    
                    obj["accuracy"] = JValue(location.horizontalAccuracy);
                    
                    /*
                    * Altitude is kind of a train wreck on Windows and Android, so we are supressing it here
                    * also.  Docs claim it to be meters above/below sea level (could not confirm).
                    *
                    if (_location.VerticalAccuracy >= 0)
                    {
                        obj["altitude"] = JValue(location.Altitude);
                        obj["altitudeAccuracy"] = JValue(location.VerticalAccuracy);
                    }
                    */
                    
                    if (location.course >= 0)
                    {
                        obj["heading"] = JValue(location.course);
                    }
                    
                    if (location.speed >= 0)
                    {
                        obj["speed"] = JValue(location.speed);
                    }
                    
                    // _location.Timestamp // NSDate
                }
                
                return obj;
            });
            
            if (bindingSpec["sync"]?.asString() == "change")
            {
                _updateOnChange = true;
            }
        }
        
        // This triggers the viewModel update so the initial status gets back to the server
        //
        updateValueBindingForAttribute("value");
    }
    
    func stopLocationServices()
    {
        if (_locMgr != nil)
        {
            _locMgr!.stopUpdatingLocation();
            _locMgr = nil;
        }
    }
    
    open override func unregister()
    {
        stopLocationServices();
        super.unregister();
    }
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        _location = nil;
        
        if CLError.Code.locationUnknown == CLError.Code(rawValue: error.code)
        {
            // "Location unknown" is not really an error.  It just indicates that the location couldn't be determined
            // immediately (it's going to keep trying), per...
            //
            // https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManagerDelegate_Protocol/index.html#//apple_ref/occ/intfm/CLLocationManagerDelegate/locationManager:didFailWithError:
            //
            logger.info("Location manager could not immediately determine location, still trying");
            _status = LocationStatus.available;
        }
        else
        {
            logger.info("Location manager failed: \(error)");
            _status = LocationStatus.failed;
            
        }
        
        // Update the viewModel, and the server (if update on change specified)
        //
        updateValueBindingForAttribute("value");
        if (_updateOnChange)
        {
            self.stateManager.sendUpdateRequestAsync();
        }
    }
    
    func fromNativeStatus(_ status: CLAuthorizationStatus) -> LocationStatus
    {
        if (status == CLAuthorizationStatus.denied)
        {
            // The user explicitly denied the use of location services for this app or location
            // services are currently disabled in Settings.
            //
            return LocationStatus.notApproved;
        }
        else if (status == CLAuthorizationStatus.restricted)
        {
            // This app is not authorized to use location services. The user cannot change this app’s
            // status, possibly due to active restrictions such as parental controls being in place.
            //
            return LocationStatus.notAvailable;
        }
        else if (status == CLAuthorizationStatus.notDetermined)
        {
            // The user has not yet made a choice regarding whether this app can use location services.
            //
            return LocationStatus.pendingApproval;
        }
        else if ((status == CLAuthorizationStatus.authorizedAlways) || (status == CLAuthorizationStatus.authorizedWhenInUse))
        {
            return LocationStatus.available;
        }
        
        return LocationStatus.unknown;
    }
    
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        logger.info("Location manager authorization change: \(status)");
        _status = fromNativeStatus(status);
        
        // Update the viewModel, and the server (if update on change specified)
        //
        updateValueBindingForAttribute("value");
        if (_updateOnChange)
        {
            self.stateManager.sendUpdateRequestAsync();
        }
    }
    
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        _status = LocationStatus.active;
        _location = locations[locations.count - 1];
        logger.info("Location: \(_location)");
        
        updateValueBindingForAttribute("value");
        
        if let command = getCommand(CommandName.OnUpdate)
        {
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(bindingContext));
        }
        else if (_updateOnChange)
        {
            self.stateManager.sendUpdateRequestAsync();
        }
    }
}
