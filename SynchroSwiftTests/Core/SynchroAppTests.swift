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
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("seed.json");
        userDefaults.synchronize()

        let appManager = SynchroAppManager();
        
        appManager.loadState();
        
        XCTAssertNil(appManager.appSeed);
        XCTAssertEqual(2, appManager.apps.count);
        
        let app = appManager.apps[0];
                
        XCTAssertEqual("synchro-samples", app.name);
        XCTAssertEqual("Synchro API Samples", app.description);
        XCTAssertEqual("https://api.synchro.io/api/samples", app.endpoint);
        
        let expected = JObject(
        [
            "name": JValue("synchro-samples"),
            "description": JValue("Synchro API Samples")
        ]);
                
        XCTAssert(app.appDefinition.deepEquals(expected));
        
        let app2 = appManager.apps[1];
        
        XCTAssertEqual("synchro-civics", app2.name);
        XCTAssertEqual("Synchro Civics Sample", app2.description);
        XCTAssertEqual("https://api.synchro.io/api/civics", app2.endpoint);
        
        let expected2 = JObject(
            [
                "name": JValue("synchro-civics"),
                "description": JValue("Synchro Civics Sample")
            ]);
        
        XCTAssert(app2.appDefinition.deepEquals(expected2));

    }
}