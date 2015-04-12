//
//  BindingContextTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/9/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class BindingContextTests: XCTestCase
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
    

    func testSelectChild()
    {
        let bindingCtx = BindingContext(viewModel);

        var titleCtx = bindingCtx.select("title");
        XCTAssert(titleCtx.getValue()!.deepEquals(viewModel["title"]));
    }
    
    func testSelectChildren()
    {
        let bindingCtx = BindingContext(viewModel);
        
        var colorsCtx = bindingCtx.select("colors");
        var colors = colorsCtx.selectEach("");
        XCTAssertEqual(3, colors.count);
    }
    
    func testSelectChildWithPath()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual("Green", bindingCtx.select("colors[1].name").getValue()!.asString()!);
    }

    func testDataElement()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual("Green", bindingCtx.select("colors[1].name").select("$data").getValue()!.asString()!);
    }

    func testParentElement()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual("Colors", bindingCtx.select("colors[1].name").select("$parent.$parent.title").getValue()!.asString()!);
    }

    func testRootElement()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual("Colors", bindingCtx.select("colors[1].name").select("$root.title").getValue()!.asString()!);
    }

    func testIndexElementOnArrayItem()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual(1, bindingCtx.select("colors[1]").select("$index").getValue()!.asInt()!);
    }

    func testIndexElementInsideArrayItem()
    {
        let bindingCtx = BindingContext(viewModel);
        
        XCTAssertEqual(1, bindingCtx.select("colors[1].name").select("$index").getValue()!.asInt()!);
    }
    
    func testSetValue()
    {
        var testViewModel: JObject = self.viewModel.deepClone() as! JObject;
        (testViewModel["colors"] as! JArray)[1] = JObject(["name": JValue("Greenish"), "color": JValue("green"), "value": JValue("0x00ff00")]);
        XCTAssertFalse(testViewModel.deepEquals(self.viewModel));
        
        let bindingCtx = BindingContext(testViewModel);
        let colorNameCtx = bindingCtx.select("colors[1].name");

        colorNameCtx.setValue(JValue("Green"));
        XCTAssert(testViewModel.deepEquals(self.viewModel));
    }
    
    func testRebind()
    {
        var testViewModel: JObject = self.viewModel.deepClone() as! JObject;

        let bindingCtx = BindingContext(testViewModel);
        let colorNameCtx = bindingCtx.select("colors[1].name");
        
        (testViewModel["colors"] as! JArray)[1] = JObject(["name": JValue("Purple"), "color": JValue("purp"), "value": JValue("0x696969")]);

        XCTAssertEqual("Green", colorNameCtx.getValue()!.asString()!);
        colorNameCtx.rebind();
        XCTAssertEqual("Purple", colorNameCtx.getValue()!.asString()!);
    }
}
