//
//  CommandInstanceTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 2/15/16.
//  Copyright © 2016 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class CommandInstanceTests: XCTestCase
{
    let viewModel = JObject(
    [
        "serial": JValue(69),
        "title": JValue("The Title"),
        "board": JArray(
        [
            JArray(
            [
                JObject(["name": JValue("s00")]),
                JObject(["name": JValue("s01")])
            ]),
            JArray(
            [
                JObject(["name": JValue("s10")]),
                JObject(["name": JValue("s11")])
            ])
        ])
    ]);
    
    func testResolveParameters()
    {
        let cmdInst = CommandInstance(command: "TestCmd");
        let bindingCtx = BindingContext(viewModel);
        
        cmdInst.setParameter("Literal", parameterValue: JValue("literal"));
        cmdInst.setParameter("Serial", parameterValue: JValue("{serial}"));
        cmdInst.setParameter("Title", parameterValue: JValue("{title}"));
        cmdInst.setParameter("Empty", parameterValue: JValue(""));
        cmdInst.setParameter("Obj", parameterValue: JValue("{board[0][1]}"));
        cmdInst.setParameter("NULL", parameterValue: JValue());              // This can't happen in nature, but just for fun...
        cmdInst.setParameter("Parent", parameterValue: JValue("{$parent}")); // Token that can't be resolved ($parent from root)
        cmdInst.setParameter("Nonsense", parameterValue: JValue("{foo}"));   // Token that can't be resolved
        
        let resolvedParams = cmdInst.getResolvedParameters(bindingCtx);
        
        XCTAssertEqual("literal", resolvedParams["Literal"]?.asString());
        XCTAssertEqual(69, resolvedParams["Serial"]?.asInt());
        XCTAssertEqual("The Title", resolvedParams["Title"]?.asString());
        XCTAssertEqual("", resolvedParams["Empty"]?.asString());
        XCTAssert(resolvedParams["Obj"]!.deepEquals(viewModel["board"]!.selectToken("0")!.selectToken("1")));
        XCTAssertEqual(JTokenType.null, resolvedParams["NULL"]?.Type);
        XCTAssertEqual(JTokenType.null, resolvedParams["Parent"]?.Type);
        XCTAssertEqual(JTokenType.null, resolvedParams["Nonsense"]?.Type);
    }
}
