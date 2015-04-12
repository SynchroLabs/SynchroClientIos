//
//  JsonTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/3/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class JsonTests: XCTestCase
{    
    func testInteger()
    {
        var stuff = JObject();
    
        stuff["foo"] = JValue(7);
        
        XCTAssertEqual(7, stuff["foo"]!.asInt()!);
    }

    func testString()
    {
        var stuff = JObject();
    
        stuff["bar"] = JValue("kitty");
    
        XCTAssertEqual("kitty", stuff["bar"]!.asString()!);
    }
    
    func testArray()
    {
        var stuff = JObject();
    
        stuff["baz"] = JArray([ JValue(8), JValue("dog") ]);
    
        XCTAssertEqual(8, ((stuff["baz"] as! JArray)[0] as! JValue).asInt()!);
        XCTAssertEqual("dog", ((stuff["baz"] as! JArray)[1] as! JValue).asString()!);
    }
    
    func testDeepClone()
    {
        var stuff = JObject(
        [
            "a": JObject(
            [
                "b": JObject(
                [
                    "c": JValue("d")
                ])
            ]),
            "e": JArray(
            [
                JObject(["f": JValue("g")]), JValue("h")
            ])
        ]);

        var duplicateStuff = JObject(
        [
            "a": JObject(
            [
                "b": JObject(
                [
                    "c": JValue("d")
                ])
            ]),
            "e": JArray(
            [
                JObject(["f": JValue("g")]), JValue("h")
            ])
        ]);

        var cloneStuff = stuff.deepClone();
        
        XCTAssert(stuff.deepEquals(duplicateStuff));
        XCTAssert(stuff.deepEquals(cloneStuff));

        stuff["foo"] = JValue("bar");

        XCTAssertFalse(stuff.deepEquals(duplicateStuff));
        XCTAssertFalse(stuff.deepEquals(cloneStuff));
        XCTAssert(duplicateStuff.deepEquals(cloneStuff));

        duplicateStuff["foo"] = JValue("bar");

        XCTAssert(stuff.deepEquals(duplicateStuff));
        XCTAssertFalse(duplicateStuff.deepEquals(cloneStuff));
    }
    
    func testPath()
    {
        var stuff = JObject(
        [
            "a": JObject(
            [
                "b": JObject(
                [
                    "c": JValue("d")
                ])
            ]),
            "e": JArray(
            [
                JObject(["f": JValue("g")]), JValue("h")
            ])
        ]);
        
        XCTAssert(((stuff["e"] as! JArray)[0] as! JObject)["f"] === stuff.selectToken("e[0].f"));
    }
    
    func testUpdate()
    {
        // This test reproduced a crashing (internal assert) failure, so just not crashing is considered a success...
        //
        var stuff = JObject();
        
        stuff["a"] = JValue();
        stuff["b"] = JValue();

        var vmItemValue = stuff.selectToken("a");
        var rebindRequired = JToken.updateTokenValue(&vmItemValue!, newToken: JObject(["baz": JValue("Fraz")]));
        
        var expected = JObject(
        [
            "a": JObject(["baz": JValue("Fraz")]),
            "b": JValue()
        ]);
        
        XCTAssert(rebindRequired);
        XCTAssert(expected.deepEquals(stuff));
    }
    
    func testArrayRemoveByObjectNotValue()
    {
        var red = JValue("Red");
        var green1 = JValue("Green");
        var green2 = JValue("Green");
        
        var arr = JArray([red, green1, green2]);
        
        arr.remove(green2);
        
        XCTAssertEqual(2, arr.count);
        XCTAssert(red === arr[0]);
        XCTAssert(green1 === arr[1]);
    }
}
