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

// For parsing the NSError that comes back to the requestFailureHandler, this is the best resource
// I have found: http://nshipster.com/nserror/
//

var testEndpoint = "http://localhost:1337/api/samples";

class TransportTests: XCTestCase
{
    func testGetAppDefinition()
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
    
        var transport = TransportHttp(uri: NSURL(string: testEndpoint)!);
        
        transport.getAppDefinition(
        { (definition) in
            XCTAssert(expected.deepEquals(definition));
            expectation.fulfill();
        });
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testGetFirstPage()
    {
        var expectation = self.expectationWithDescription("got response")
        
        var transport = TransportHttp(uri: NSURL(string: testEndpoint)!);

        transport.sendMessage(
            nil,
            requestObject: JObject(
            [
                "Mode": JValue("Page"),
                "Path": JValue("menu"),
                "TransactionId": JValue(1)
            ]),
            responseHandler: { (response) in
                XCTAssert("menu" == response["Path"]?.asString());
                expectation.fulfill();
            },
            requestFailureHandler: { (request, error) in
                XCTAssert(false, "Unexpected error from sendMessage");
            }
        );
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testNavigateToPageViaCommand()
    {
        var expectation = self.expectationWithDescription("got response")
        
        var transport = TransportHttp(uri: NSURL(string: testEndpoint)!);
        
        transport.sendMessage(
            nil,
            requestObject: JObject(
                [
                    "Mode": JValue("Page"),
                    "Path": JValue("menu"),
                    "TransactionId": JValue(1)
                ]),
            responseHandler: { (response) in
                XCTAssert("menu" == response["Path"]?.asString());
                if let sessionId = response["NewSessionId"]?.asString()
                {
                    if let instanceId = response["InstanceId"]?.asInt()
                    {
                        if let instanceVersion = response["InstanceVersion"]?.asInt()
                        {
                            transport.sendMessage(
                                sessionId,
                                requestObject: JObject(
                                    [
                                        "Mode": JValue("Command"),
                                        "Path": JValue("menu"),
                                        "TransactionId": JValue(2),
                                        "InstanceId": JValue(instanceId),
                                        "InstanceVersion": JValue(instanceVersion),
                                        "Command": JValue("goToView"),
                                        "Parameters": JObject(
                                            [
                                                "view": JValue("hello")
                                            ])
                                    ]),
                                responseHandler: { (response2) in
                                    XCTAssert("hello" == response2["Path"]?.asString());
                                    expectation.fulfill();
                                },
                                requestFailureHandler: { (request, error) in
                                    XCTAssert(false, "Unexpected error from sendMessage");
                                }
                            );
                        }
                    }
                }
            },
            requestFailureHandler: { (request, error) in
                XCTAssert(false, "Unexpected error from sendMessage");
            }
        );
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testHttp404Failure()
    {
        var expectation = self.expectationWithDescription("got response")
        
        var transport = TransportHttp(uri: NSURL(string: "http://localhost:1337")!);
        
        transport.sendMessage(
            nil,
            requestObject: JObject(
                [
                    "Mode": JValue("Page"),
                    "Path": JValue("menu"),
                    "TransactionId": JValue(1)
                ]),
            responseHandler: { (response) in
                XCTAssert(false, "Unexpected response from sendMessage");
            },
            requestFailureHandler: { (request, error) in
                XCTAssertEqual(404, error.code);
                expectation.fulfill();
            }
        );
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testNetworkFailure()
    {
        var expectation = self.expectationWithDescription("got response")
        
        var transport = TransportHttp(uri: NSURL(string: "http://nohostcanbefoundhere")!);
        
        transport.sendMessage(
            nil,
            requestObject: JObject(
                [
                    "Mode": JValue("Page"),
                    "Path": JValue("menu"),
                    "TransactionId": JValue(1)
                ]),
            responseHandler: { (response) in
                XCTAssert(false, "Unexpected response from sendMessage");
            },
            requestFailureHandler: { (request, error) in
                XCTAssertEqual(-1003, error.code);
                expectation.fulfill();
            }
        );
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}
