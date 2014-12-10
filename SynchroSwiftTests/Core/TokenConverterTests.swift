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
        var objVal = JObject(["foo": JValue("bar"), "baz": JValue("fraz")]);
        var arrayVal = JArray([JValue("foo"), JValue("bar")]);
        var stringVal = JValue("foo");
        var intVal = JValue(13);
        var floatVal = JValue(13.69);
        var boolVal = JValue(true);
        
        XCTAssertEqual("", TokenConverter.toString(objVal));
        XCTAssertEqual("2", TokenConverter.toString(arrayVal));
        XCTAssertEqual("foo", TokenConverter.toString(stringVal));
        XCTAssertEqual("", TokenConverter.toString(intVal));
        XCTAssertEqual("", TokenConverter.toString(floatVal));
        XCTAssertEqual("", TokenConverter.toString(boolVal));
    }
    
    func testToBoolean()
    {
        var objVal = JObject(["foo": JValue("bar"), "baz": JValue("fraz")]);
        var objValEmpty = JObject();
        var arrayVal = JArray([JValue("foo"), JValue("bar")]);
        var arrayValEmpty = JArray();
        var stringVal = JValue("foo");
        var stringValEmpty = JValue("");
        var intVal = JValue(13);
        var intValZero = JValue(0);
        var floatVal = JValue(13.69);
        var floatValZero = JValue(0.0);
        var boolValTrue = JValue(true);
        var boolValFalse = JValue(false);
        
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
        var arrayVal = JArray([JValue("foo"), JValue("bar")]);
        var arrayValEmpty = JArray();
        var stringVal = JValue("12.34");
        var intVal = JValue(13);
        var floatVal = JValue(13.69);
    
        XCTAssertEqual(2, TokenConverter.toDouble(arrayVal));
        XCTAssertEqual(0, TokenConverter.toDouble(arrayValEmpty));
        XCTAssertEqual(12.34, TokenConverter.toDouble(stringVal));
        XCTAssertEqual(13, TokenConverter.toDouble(intVal));
        XCTAssertEqual(13.69, TokenConverter.toDouble(floatVal));
    }

}
