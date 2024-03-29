//
//  JsonParserTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/3/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class JsonParserTests: XCTestCase
{
    func validateRoundTrip(_ jsonInput: String, expected: JToken)
    {
        let token = JToken.parse(jsonInput);
        let jsonOutput = token.toJson();
        XCTAssertEqual(jsonInput, jsonOutput);
        
        XCTAssert(token.deepEquals(expected));
    }

    func testStringReader()
    {
        let reader = StringReader(str: "$\u{20ac}%\u{2665}X"); // dollar-sign, Euro, percent, heart
        XCTAssert("$" == reader.peek());
        XCTAssert("$" == reader.peek());
        XCTAssert("$" == reader.read());
        XCTAssert("\u{20ac}" == reader.read());
        XCTAssert("%" == reader.peek());
        XCTAssert("%" == reader.read());
        XCTAssert("\u{2665}" == reader.peek());
        XCTAssert("\u{2665}" == reader.peek());
        XCTAssert("\u{2665}" == reader.read());
        XCTAssert("X" == reader.read());
        XCTAssert(nil == reader.peek());
        XCTAssert(nil == reader.read());
        XCTAssert(nil == reader.read());
        XCTAssert(nil == reader.peek());
    }
    
    func testParseSimple()
    {
        let jsonStr = "{\"foo\":true}";
        
        let token = JToken.parse(jsonStr) as! JObject;
        
        if let foo = token["foo"]
        {
            XCTAssert(foo.asBool()!);
        }
        else
        {
            XCTAssert(false, "foo was not token");
        }
        
        let out = token.toJson();
        
        XCTAssertEqual(jsonStr, out);
    }

    func testParseString()
    {
        validateRoundTrip("\"abc\"", expected: JValue("abc"));
    }

    func testParseStringEscapes()
    {
        validateRoundTrip("\"\\\"\\\\\\b\\f\\n\\r\\t\\u20ac\"", expected: JValue("\"\\\u{008}\u{012}\n\r\t\u{20ac}"));
    }

    func testParseInteger()
    {
        XCTAssert(JValue(Int.max).deepEquals(JValue(Int.max)));
        XCTAssert(JValue(Int.min).deepEquals(JValue(Int.min)));
        
        validateRoundTrip("0", expected: JValue(0));
        validateRoundTrip(String(format: "%ld", Int.max), expected: JValue(Int.max));
        validateRoundTrip(String(format: "%ld", Int.min), expected: JValue(Int.min));
    }

    func testParseArray()
    {
        validateRoundTrip("[]", expected: JArray());
        validateRoundTrip("[0]", expected: JArray([JValue(0)]));
        validateRoundTrip("[\"abc\"]", expected: JArray([JValue("abc")]));
        validateRoundTrip("[0,\"abc\"]", expected: JArray([JValue(0), JValue("abc")]));
        validateRoundTrip("[0,\"abc\",[1,\"def\"]]", expected: JArray([JValue(0), JValue("abc"), JArray([JValue(1), JValue("def")])]));
    }

    func testParseObject()
    {
        validateRoundTrip(
            "{\"foo\":0,\"bar\":\"kitty\",\"baz\":[8,\"dog\"]}",
            expected: JObject(
                [
                    "foo": JValue(0),
                    "bar": JValue("kitty"),
                    "baz": JArray(
                        [
                            JValue(8),
                            JValue("dog")
                        ])
                ])
        );
    }

    func testParseBoolean()
    {
        validateRoundTrip("true", expected: JValue(true));
        validateRoundTrip("false", expected: JValue(false));
    }
    
    func testParseNull()
    {
        validateRoundTrip("null", expected: JValue());
    }
    
    func testParseEmptyObject()
    {
        validateRoundTrip("{}", expected: JObject());
    }

    func testParseEmptyArray()
    {
        validateRoundTrip("[]", expected: JArray());
    }

    func testParseObjectWithWhitespace()
    {
        let token = JToken.parse("  {  \"foo\"  :  0  ,  \"bar\"  :  \"kitty\"  ,  \"baz\"  :  [8  ,  \"dog\"  ]  }  ");
        XCTAssert(token.deepEquals(JObject(
        [
            "foo": JValue(0),
            "bar": JValue("kitty"),
            "baz": JArray(
            [
                JValue(8),
                JValue("dog")
            ])
        ])));
    }

    func testComments()
    {
        let jsonWithComments = [
            "// This is a comment",
            "{",
            "// The foo element is my favorite",
            "\"foo\"  :  0,",
            "\"bar\"  :  \"kitty\",",
            "// The baz element, he's OK also",
            "\"baz\"  :  [  8  ,  \"dog\"  ]",
            "}",
            ""
        ].joined(
        separator: "\r\n");
        
        let token = JToken.parse(jsonWithComments);
        XCTAssert(token.deepEquals(JObject(
        [
            "foo": JValue(0),
            "bar": JValue("kitty"),
            "baz": JArray(
            [
                JValue(8),
                JValue("dog")
            ])
        ])));
    }

    func testMultilineComments()
    {
        let jsonWithComments = [
                "// This is a comment",
                "{",
                "// The foo element is my favorite.  But comment him out for now.",
                "/*",
                "\"foo\"  :  0,",
                "*/",
                "\"bar\"  :  \"kitty\",",
                "// The baz element, he's OK also",
                "\"baz\"  :  [  8  ,  \"dog\"  ]",
                "}",
                ""
            ].joined(
            separator: "\r\n");
        
        let token = JToken.parse(jsonWithComments);
        XCTAssert(token.deepEquals(JObject(
        [
            "bar": JValue("kitty"),
            "baz": JArray(
            [
                JValue(8),
                JValue("dog")
            ])
        ])));
    }
    
    func testParseDouble()
    {
        validateRoundTrip("0.001", expected: JValue(0.001));
        validateRoundTrip("6.02E+23", expected: JValue(6.02E+23));
    }

    /*
     * !!! Not implemented yet...
     *
    [Test()]
    [ExpectedException(typeof(IOException))]
    public void TestUnterminatedString()
    {
        Parser.ParseValue(new StringReader("\"abc"));
    }
    
    [Test()]
    public void TestParseDoubleCrazyLocale()
    {
        var crazyCulture = new CultureInfo("en-US");
        var oldCulture = Thread.CurrentThread.CurrentCulture;
    
        crazyCulture.NumberFormat.NumberDecimalSeparator = "Z";
    
        Thread.CurrentThread.CurrentCulture = crazyCulture;
        try
        {
            TestRoundtrip("0.001", .001);
            TestRoundtrip("6.02E+23", 6.02E+23);
        }
        finally
        {
            Thread.CurrentThread.CurrentCulture = oldCulture;
        }
    }
    */
    
}
