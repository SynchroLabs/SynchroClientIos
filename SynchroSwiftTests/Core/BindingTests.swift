//
//  BindingTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class BindingTests: XCTestCase
{
    func testBindingHelperPromoteValue()
    {
        // For an edit control with a default binding attribute of "value" a binding of:
        //
        //     binding: "username"
        //
        var controlSpec = JObject(["binding": JValue("username")]);

        // becomes
        //
        //     binding: { value: "username" }
        //
        var expectedBindingSpec = JObject(["value": JValue("username")]);

        var bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value");
        XCTAssert(bindingSpec!.deepEquals(expectedBindingSpec));
    }
    
    func testBindingHelperPromoteImplicitCommand()
    {
        // For commands:
        //
        //     binding: "doSomething"
        //
        var controlSpec = JObject(["binding": JValue("doSomething")]);

        // becomes
        //
        //     binding: { onClick: "doSomething" }
        //
        // becomes
        //
        //     binding: { onClick: { command: "doSomething" } }
        //
        var expectedBindingSpec = JObject(["onClick": JObject(["command": JValue("doSomething")])]);

        var bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "onClick", commandAttributes: ["onClick"]);
        XCTAssert(bindingSpec!.deepEquals(expectedBindingSpec));
    }
    
    func testBindingHelperPromoteExplicitCommand()
    {
        // Also (default binding atttribute is 'onClick', which is also in command attributes list):
        //
        //     binding: { command: "doSomething" value: "theValue" }
        //
        var controlSpec = JObject(["binding": JObject(["command": JValue("doSomething"), "value": JValue("theValue")])]);

        // becomes
        //
        //     binding: { onClick: { command: "doSomething", value: "theValue" } }
        //
        var expectedBindingSpec = JObject(["onClick": JObject(["command": JValue("doSomething"), "value": JValue("theValue")])]);

        var bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "onClick", commandAttributes: ["onClick"]);
        XCTAssert(bindingSpec!.deepEquals(expectedBindingSpec));
    }
    
    func testBindingHelperPromoteMultipleCommands()
    {
        // For multiple commands with implicit values...
        //
        //     binding: { onClick: "doClickCommand", onSelect: "doSelectCommand" }
        //
        var controlSpec = JObject(["binding": JObject(["onClick": JValue("doClickCommand"), "onSelect": JValue("doSelectCommand")])]);
        
        // becomes
        //
        //     binding: { onClick: { command: "doClickCommand" }, onSelect: { command: "doSelectCommand" } }
        //
        var expectedBindingSpec = JObject(["onClick": JObject(["command": JValue("doClickCommand")]), "onSelect": JObject(["command": JValue("doSelectCommand")])]);
        
        var bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "onClick", commandAttributes: ["onClick", "onSelect"]);
        XCTAssert(bindingSpec!.deepEquals(expectedBindingSpec));
    }

}
