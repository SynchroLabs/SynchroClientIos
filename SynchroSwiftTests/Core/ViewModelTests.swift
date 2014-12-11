//
//  ViewModelTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/11/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class ViewModelTests: XCTestCase
{
    let viewModelObj = JObject(
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

    func testViewModel()
    {
        var expectation = self.expectationWithDescription("Property value got set");

        var viewModel = ViewModel();
        
        viewModel.initializeViewModelData(viewModelObj);
        
        var propBinding = viewModel.CreateAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Title: {title}", setValue:
        {
            (valueToken) in
            
            XCTAssertEqual("Title: Colors", valueToken.asString()!);
            expectation.fulfill();
        });
        
        propBinding.updateViewFromViewModel();
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil);
    }
}