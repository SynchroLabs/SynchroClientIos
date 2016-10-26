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

var testEndpoint = "https://api.synchro.io/api/samples";

class TransportTests: XCTestCase
{
    func testGetAppDefinition()
    {
        let expectation = self.expectation(description: "got definition")
        let expected = JObject(
        [
            "name": JValue("synchro-samples"),
            "version": JValue("1.5.0"),
            "description": JValue("Synchro API Samples"),
            "main": JValue("menu"),
            "author": JValue("Bob Dickinson <bob@synchro.io> (http://synchro.io/)"),
            "private": JValue(true),
            "engines": JObject(["synchro" : JValue(">= 1.5.0")]),
            "synchroArchiveUrl": JValue("https://github.com/SynchroLabs/SynchroSamples/archive/master.zip"),
            "synchro": JObject(["clientVersion" : JValue(">= 1.4.0")])
        ])

        let transport = TransportHttp(uri: URL(string: testEndpoint)!);
        
        transport.getAppDefinition(
        { (definition) in
            XCTAssert(expected.deepEquals(definition));
            expectation.fulfill();
        });
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testGetFirstPage()
    {
        let expectation = self.expectation(description: "got response")
        
        let transport = TransportHttp(uri: URL(string: testEndpoint)!);

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
                expectation.fulfill();
            },
            requestFailureHandler: { (request, error) in
                XCTAssert(false, "Unexpected error from sendMessage");
            }
        );
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testNavigateToPageViaCommand()
    {
        let expectation = self.expectation(description: "got response")
        
        let transport = TransportHttp(uri: URL(string: testEndpoint)!);
        
        transport.sendMessage(
            nil,
            requestObject: JObject(
                [
                    "Mode": JValue("Page"),
                    "Path": JValue("menu"),
                    "TransactionId": JValue(1),
                    "DeviceMetrics": JObject(["clientVersion": JValue("1.4.0")])
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testHttp404Failure()
    {
        let expectation = self.expectation(description: "got response")
        
        let transport = TransportHttp(uri: URL(string: "https://api.synchro.io")!);
        
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testNetworkFailure()
    {
        let expectation = self.expectation(description: "got response")
        
        let transport = TransportHttp(uri: URL(string: "http://nohostcanbefoundhere")!);
        
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testUriFromHostString()
    {
        XCTAssertEqual(TransportHttp.uriFromHostString("foo/app")!.absoluteString, "http://foo/app");
        XCTAssertEqual(TransportHttp.uriFromHostString("http://foo/app")!.absoluteString, "http://foo/app");
        XCTAssertEqual(TransportHttp.uriFromHostString("https://foo/app")!.absoluteString, "https://foo/app");
    }
}
