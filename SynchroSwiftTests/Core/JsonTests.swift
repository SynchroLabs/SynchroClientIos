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
        let stuff = JObject();
    
        stuff["foo"] = JValue(7);
        
        XCTAssertEqual(7, stuff["foo"]!.asInt()!);
    }

    func testString()
    {
        let stuff = JObject();
    
        stuff["bar"] = JValue("kitty");
    
        XCTAssertEqual("kitty", stuff["bar"]!.asString()!);
    }
    
    func testArray()
    {
        let stuff = JObject();
    
        stuff["baz"] = JArray([ JValue(8), JValue("dog") ]);
    
        XCTAssertEqual(8, ((stuff["baz"] as! JArray)[0] as! JValue).asInt()!);
        XCTAssertEqual("dog", ((stuff["baz"] as! JArray)[1] as! JValue).asString()!);
    }
    
    func testDeepClone()
    {
        let stuff = JObject(
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

        let duplicateStuff = JObject(
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

        let cloneStuff = stuff.deepClone();
        
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
        let stuff = JObject(
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
        let stuff = JObject();
        
        stuff["a"] = JValue();
        stuff["b"] = JValue();

        var vmItemValue = stuff.selectToken("a");
        let rebindRequired = JToken.updateTokenValue(&vmItemValue!, newToken: JObject(["baz": JValue("Fraz")]));
        
        let expected = JObject(
        [
            "a": JObject(["baz": JValue("Fraz")]),
            "b": JValue()
        ]);
        
        XCTAssert(rebindRequired);
        XCTAssert(expected.deepEquals(stuff));
    }
    
    func testArrayRemoveByObjectNotValue()
    {
        let red = JValue("Red");
        let green1 = JValue("Green");
        let green2 = JValue("Green");
        
        let arr = JArray([red, green1, green2]);
        
        arr.remove(green2);
        
        XCTAssertEqual(2, arr.count);
        XCTAssert(red === arr[0]);
        XCTAssert(green1 === arr[1]);
    }
}
