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

    func testPropertyValue()
    {
        let viewModel = JObject(
        [
            "serial": JValue(0),
            "title": JValue("Colors"),
            "colors": JArray(
            [
                JObject(["name": JValue("Red"), "color": JValue("red"), "value": JValue("0xff0000")]),
                JObject(["name": JValue("Green"), "color": JValue("green"), "value": JValue("0x00ff00")]),
                JObject(["name": JValue("Blue"), "color": JValue("blue"), "value": JValue("0x0000ff")])
            ])
        ]);
        
        let bindingCtx = BindingContext(viewModel);

        var propVal = PropertyValue("The {title} are {colors[0].name}, {colors[1].name}, and {colors[2].name}", bindingContext: bindingCtx);
        
        XCTAssertEqual("The Colors are Red, Green, and Blue", propVal.expand().asString()!);
    }
    
    func testPropertyValueModelUpdate()
    {
        let viewModel = JObject(
        [
            "serial": JValue(0),
            "title": JValue("Colors"),
            "colors": JArray(
            [
                JObject(["name": JValue("Red"), "color": JValue("red"), "value": JValue("0xff0000")]),
                JObject(["name": JValue("Green"), "color": JValue("green"), "value": JValue("0x00ff00")]),
                JObject(["name": JValue("Blue"), "color": JValue("blue"), "value": JValue("0x0000ff")])
            ])
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("The {title} are {colors[0].name}, {colors[1].name}, and {colors[2].name}", bindingContext: bindingCtx);
        
        XCTAssertEqual("The Colors are Red, Green, and Blue", propVal.expand().asString()!);
        
        (viewModel["colors"] as JArray)[1] = JObject(["name": JValue("Greenish"), "color": JValue("green"), "value": JValue("0x00ff00")]);
        for bindingContext in propVal.BindingContexts
        {
            bindingContext.rebind();
        }

        XCTAssertEqual("The Colors are Red, Greenish, and Blue", propVal.expand().asString()!);
    }

    func testPropertyValueModelUpdateOneTimeToken()
    {
        let viewModel = JObject(
        [
            "serial": JValue(0),
            "title": JValue("Colors"),
            "colors": JArray(
            [
                JObject(["name": JValue("Red"), "color": JValue("red"), "value": JValue("0xff0000")]),
                JObject(["name": JValue("Green"), "color": JValue("green"), "value": JValue("0x00ff00")]),
                JObject(["name": JValue("Blue"), "color": JValue("blue"), "value": JValue("0x0000ff")])
            ])
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("The {title} are {colors[0].name}, {colors[1].name}, and {^colors[2].name}", bindingContext: bindingCtx);
        
        XCTAssertEqual("The Colors are Red, Green, and Blue", propVal.expand().asString()!);
        
        (viewModel["colors"] as JArray)[1] = JObject(["name": JValue("Greenish"), "color": JValue("green"), "value": JValue("0x00ff00")]);
        (viewModel["colors"] as JArray)[2] = JObject(["name": JValue("Blueish"), "color": JValue("blue"), "value": JValue("0x0000ff")]);
        for bindingContext in propVal.BindingContexts
        {
            bindingContext.rebind();
        }
        
        XCTAssertEqual("The Colors are Red, Greenish, and Blue", propVal.expand().asString()!);
    }

    func testPropertyValueIntToken()
    {
        let viewModel = JObject(
        [
            "serial": JValue(420)
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        XCTAssertEqual(JTokenType.Integer, expandedPropValToken.Type);
        XCTAssertEqual(420, expandedPropValToken.asInt()!);
    }

    func testPropertyValueFloatToken()
    {
        let viewModel = JObject(
        [
            "serial": JValue(13.69),
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        XCTAssertEqual(JTokenType.Float, expandedPropValToken.Type);
        XCTAssertEqual(13.69, expandedPropValToken.asDouble()!);
    }

    func testPropertyValueBoolToken()
    {
        let viewModel = JObject(
        [
            "serial": JValue(true),
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        XCTAssertEqual(JTokenType.Boolean, expandedPropValToken.Type);
        XCTAssertEqual(true, expandedPropValToken.asBool()!);
    }

    func testPropertyValueBoolTokenNegated()
    {
        let viewModel = JObject(
        [
            "serial": JValue(true),
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{!serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        XCTAssertEqual(JTokenType.Boolean, expandedPropValToken.Type);
        XCTAssertEqual(false, expandedPropValToken.asBool()!);
    }

    func testPropertyValueStringToken()
    {
        let viewModel = JObject(
        [
            "serial": JValue("foo"),
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        XCTAssertEqual(JTokenType.String, expandedPropValToken.Type);
        XCTAssertEqual("foo", expandedPropValToken.asString()!);
    }

    func testPropertyValueStringTokenNegated()
    {
        let viewModel = JObject(
        [
            "serial": JValue("foo"),
        ]);
        
        let bindingCtx = BindingContext(viewModel);
        
        var propVal = PropertyValue("{!serial}", bindingContext: bindingCtx);
        var expandedPropValToken = propVal.expand();
        
        // When we negate a string, the type is coerced (converted) to bool, the inverted...
        XCTAssertEqual(JTokenType.Boolean, expandedPropValToken.Type);
        XCTAssertEqual(false, expandedPropValToken.asBool()!);
    }

}