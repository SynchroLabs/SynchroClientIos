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
    func testSelectChild()
    {
        let viewModel = JObject(
        [
            "serial": JValue(0),
            "title": JValue("Colors"),
            "colors": JArray(
            [
                JValue("red"),
                JValue("green"),
                JValue("blue")
            ])
        ]);
        
        var bindingCtx = BindingContext(viewModel);
        
        var titleCtx = bindingCtx.select("title");
        XCTAssert(titleCtx.getValue()!.deepEquals(viewModel["title"]));
    }
    
    func testSelectChildren()
    {
        let viewModel = JObject(
        [
            "serial": JValue(0),
            "title": JValue("Colors"),
            "colors": JArray(
            [
                JValue("red"),
                JValue("green"),
                JValue("blue")
            ])
        ]);
        
        var bindingCtx = BindingContext(viewModel);
        
        var colorsCtx = bindingCtx.select("colors");
        var colors = colorsCtx.selectEach("");
        XCTAssertEqual(3, colors.count);
    }
}