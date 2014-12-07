//
//  TransportTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class TransportTests: XCTestCase
{
    func testTransport()
    {
        var expectation = self.expectationWithDescription("got definition")
        var expected = JObject(
        [
            "name": JValue("synchro-samples"),
            "version": JValue("0.0.0"),
            "description": JValue("Synchro API Samples"),
            "mainPage": JValue("menu"),
            "author": JValue("Bob Dickinson <bob@synchro.io> (http://synchro.io/)")
        ])
    
        var transport = TransportHttp(uri: NSURL(string: "http://192.168.1.134:1337/api/samples")!);
        
        transport.getAppDefinition(
        { (definition) in
            println("Got app definition for: \(definition)");
            XCTAssert(expected.deepEquals(definition));
            expectation.fulfill();
        });
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
