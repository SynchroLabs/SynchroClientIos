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
        let expectation = self.expectationWithDescription("got definition")
        let expected = JObject(
        [
            "name": JValue("synchro-samples"),
            "version": JValue("0.1.0"),
            "description": JValue("Synchro API Samples"),
            "main": JValue("menu"),
            "author": JValue("Bob Dickinson <bob@synchro.io> (http://synchro.io/)")
        ])
    
        // Apparently having SIX dictionary entries in an initializer blows up the Swift compiler
        //
        // http://stackoverflow.com/questions/26550775/if-condition-failing-with-expression-too-complex
        // http://stackoverflow.com/questions/25810625/xcode-beta-6-1-and-xcode-6-gm-stuck-indexing-for-weird-reason/25813625#25813625
        //
        // So we work around by adding these values after the initializer...
        //
        expected["private"] = JValue(true);
        expected["engines"] = JObject(
            [
                "synchro": JValue("*")
            ]);

        let transport = TransportHttp(uri: NSURL(string: testEndpoint)!);
        
        transport.getAppDefinition(
        { (definition) in
            XCTAssert(expected.deepEquals(definition));
            expectation.fulfill();
        });
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testGetFirstPage()
    {
        let expectation = self.expectationWithDescription("got response")
        
        let transport = TransportHttp(uri: NSURL(string: testEndpoint)!);

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
        let expectation = self.expectationWithDescription("got response")
        
        let transport = TransportHttp(uri: NSURL(string: testEndpoint)!);
        
        transport.sendMessage(
            nil,
            requestObject: JObject(
                [
                    "Mode": JValue("Page"),
                    "Path": JValue("menu"),
                    "TransactionId": JValue(1),
                    "DeviceMetrics": JObject(["clientVersion": JValue("1.1.0")])
                ]),
            responseHandler: { (response) in
                XCTAssert("menu" == response["Path"]?.asString());
                if (response["Error"] != nil)
                {
                    XCTAssertNil(response["Error"], "Unexpected Error: " + response["Error"]!.toJson());
                }
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
        let expectation = self.expectationWithDescription("got response")
        
        let transport = TransportHttp(uri: NSURL(string: "http://localhost:1337")!);
        
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
        let expectation = self.expectationWithDescription("got response")
        
        let transport = TransportHttp(uri: NSURL(string: "http://nohostcanbefoundhere")!);
        
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
                XCTAssert(error.code < -1000); // Typically -1003 (NSURLErrorCannotFindHost) or -1004 (NSURLErrorCannotConnectToHost)
                expectation.fulfill();
            }
        );
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testUriFromHostString()
    {
        XCTAssertEqual(TransportHttp.uriFromHostString("foo/app")!.absoluteString, "http://foo/app");
        XCTAssertEqual(TransportHttp.uriFromHostString("http://foo/app")!.absoluteString, "http://foo/app");
        XCTAssertEqual(TransportHttp.uriFromHostString("https://foo/app")!.absoluteString, "https://foo/app");
    }
}
