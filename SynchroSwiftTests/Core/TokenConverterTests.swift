//
//  TokenConverterTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class TokenConverterTests: XCTestCase
{
    func testToString()
    {
        let objVal = JObject(["foo": JValue("bar"), "baz": JValue("fraz")]);
        let arrayVal = JArray([JValue("foo"), JValue("bar")]);
        let stringVal = JValue("foo");
        let intVal = JValue(13);
        let floatVal = JValue(13.69);
        let boolVal = JValue(true);
        
        XCTAssertEqual("", TokenConverter.toString(objVal));
        XCTAssertEqual("2", TokenConverter.toString(arrayVal));
        XCTAssertEqual("foo", TokenConverter.toString(stringVal));
        XCTAssertEqual("13", TokenConverter.toString(intVal));
        XCTAssertEqual("13.69", TokenConverter.toString(floatVal));
        XCTAssertEqual("true", TokenConverter.toString(boolVal));
    }
    
    func testToBoolean()
    {
        let objVal = JObject(["foo": JValue("bar"), "baz": JValue("fraz")]);
        let objValEmpty = JObject();
        let arrayVal = JArray([JValue("foo"), JValue("bar")]);
        let arrayValEmpty = JArray();
        let stringVal = JValue("foo");
        let stringValEmpty = JValue("");
        let intVal = JValue(13);
        let intValZero = JValue(0);
        let floatVal = JValue(13.69);
        let floatValZero = JValue(0.0);
        let boolValTrue = JValue(true);
        let boolValFalse = JValue(false);
        
        XCTAssertEqual(true, TokenConverter.toBoolean(objVal));
        XCTAssertEqual(true, TokenConverter.toBoolean(objValEmpty));
        XCTAssertEqual(true, TokenConverter.toBoolean(arrayVal));
        XCTAssertEqual(false, TokenConverter.toBoolean(arrayValEmpty));
        XCTAssertEqual(true, TokenConverter.toBoolean(stringVal));
        XCTAssertEqual(false, TokenConverter.toBoolean(stringValEmpty));
        XCTAssertEqual(true, TokenConverter.toBoolean(intVal));
        XCTAssertEqual(false, TokenConverter.toBoolean(intValZero));
        XCTAssertEqual(true, TokenConverter.toBoolean(floatVal));
        XCTAssertEqual(false, TokenConverter.toBoolean(floatValZero));
        XCTAssertEqual(true, TokenConverter.toBoolean(boolValTrue));
        XCTAssertEqual(false, TokenConverter.toBoolean(boolValFalse));
    }
    
    func testToDouble()
    {
        let arrayVal = JArray([JValue("foo"), JValue("bar")]);
        let arrayValEmpty = JArray();
        let stringVal = JValue("12.34");
        let stringNotNum = JValue("threeve");
        let intVal = JValue(13);
        let floatVal = JValue(13.69);
    
        XCTAssertEqual(2, TokenConverter.toDouble(arrayVal)!);
        XCTAssertEqual(0, TokenConverter.toDouble(arrayValEmpty)!);
        XCTAssertEqual(12.34, TokenConverter.toDouble(stringVal)!);
        XCTAssert(nil == TokenConverter.toDouble(stringNotNum));
        XCTAssertEqual(13, TokenConverter.toDouble(intVal)!);
        XCTAssertEqual(13.69, TokenConverter.toDouble(floatVal)!);
    }

}
