//
//  SynchroAppTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class SynchroAppTests: XCTestCase
{
    func testLoadBundledState()
    {
        // Force fresh load from the bundled seed...
        //
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("seed.json");
        userDefaults.synchronize()

        var appManager = SynchroAppManager();
        
        appManager.loadState();
        
        XCTAssertNil(appManager.appSeed);
        XCTAssertEqual(1, appManager.apps.count);
        
        var app = appManager.apps[0];
                
        XCTAssertEqual("synchro-samples", app.name);
        XCTAssertEqual("Synchro API Samples", app.description);
        XCTAssertEqual("api.synchro.io/api/samples", app.endpoint);
        
        var expected = JObject(
        [
            "name": JValue("synchro-samples"),
            "description": JValue("Synchro API Samples")
        ]);
                
        XCTAssert(app.appDefinition.deepEquals(expected));
    }
}