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
        "serial": JValue(1),
        "title": JValue("Colors"),
        "colors": JArray(
        [
            JObject(["name": JValue("Red"), "color": JValue("red"), "value": JValue("0xff0000")]),
            JObject(["name": JValue("Green"), "color": JValue("green"), "value": JValue("0x00ff00")]),
            JObject(["name": JValue("Blue"), "color": JValue("blue"), "value": JValue("0x0000ff")])
        ])
    ]);

    func testUpdateView()
    {
        // Create a binding of each type, initialize them from the view model, verify that their values were set properly
        //
        var viewModel = ViewModel();
        
        viewModel.initializeViewModelData(viewModelObj);
      
        var serialString = "";
        var propBinding = viewModel.createAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Serial: {serial}", setValue:
        {
            (valueToken) in
            
            serialString = valueToken!.asString()!;
        });

        var serialValue = -1;
        var valBinding = viewModel.createAndRegisterValueBinding(viewModel.rootBindingContext.select("serial"),
            getValue: { () -> JToken in
                return JValue(serialValue);
            },
            setValue: { (valueToken) in
                serialValue = valueToken!.asInt()!;
            }
        );

        propBinding.updateViewFromViewModel();
        valBinding.updateViewFromViewModel();
        
        XCTAssertEqual("Serial: 1", serialString);
        XCTAssertEqual(1, serialValue);
    }
    
    func testUpdateViewFromValueBinding()
    {
        var viewModel = ViewModel();
        
        viewModel.initializeViewModelData(viewModelObj);
        
        var bindingsInitialized = false;
        
        var serialString = "";
        var propBinding = viewModel.createAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Serial: {serial}", setValue:
        {
            (valueToken) in
            
            serialString = valueToken!.asString()!;
        });

        var titleString = "";
        var propBindingTitle = viewModel.createAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Title: {title}", setValue:
        {
            (valueToken) in
            
            titleString = valueToken!.asString()!;
            if (bindingsInitialized)
            {
                XCTAssert(false, "Property binding setter for title should not be called after initialization (since its token wasn't impacted by the value binding change)");
            }
        });

        var serialValue = -1;
        var valBinding = viewModel.createAndRegisterValueBinding(viewModel.rootBindingContext.select("serial"),
            getValue: { () -> JToken in
                return JValue(serialValue);
            },
            setValue: { (valueToken) in
                serialValue = valueToken!.asInt()!;
                if (bindingsInitialized)
                {
                    XCTAssert(false, "Value bining setter should not be called after initialization (its change shouldn't update itself)");
                }
            }
        );
        
        propBinding.updateViewFromViewModel();
        propBindingTitle.updateViewFromViewModel();
        valBinding.updateViewFromViewModel();

        bindingsInitialized = true;

        XCTAssertEqual("Serial: 1", serialString);
        XCTAssertEqual("Title: Colors", titleString);
        XCTAssertEqual(1, serialValue);
        
        // When the value binding updates the view model, the propBinding (that has a token bound to the same context/path) will automatically
        // update (its setter will be called), but the value binding that triggered the update will not have its setter called.
        //
        serialValue = 2;
        valBinding.updateViewModelFromView();

        XCTAssertEqual("Serial: 2", serialString);
        
        // Now let's go collect the changes caused by value binding updates and verify them...
        //
        var changes = viewModel.collectChangedValues();
        XCTAssertEqual(1, changes.count);
        XCTAssertEqual(2, changes["serial"]!.asInt()!);
        
        // Collecting the changes (above) should have cleared the dirty indicators, so there shouldn't be any changes now...
        //
        XCTAssertEqual(0, viewModel.collectChangedValues().count);
    }

    func testUpdateViewFromViewModelDeltas()
    {
        var viewModel = ViewModel();
        
        viewModel.initializeViewModelData(viewModelObj);
        
        var bindingsInitialized = false;
        
        var serialString = "";
        var propBinding = viewModel.createAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Serial: {serial}", setValue:
        {
            (valueToken) in
            
            serialString = valueToken!.asString()!;
        });
        
        var titleString = "";
        var propBindingTitle = viewModel.createAndRegisterPropertyBinding(viewModel.rootBindingContext, value: "Title: {title}", setValue:
        {
            (valueToken) in
            
            titleString = valueToken!.asString()!;
            if (bindingsInitialized)
            {
                XCTAssert(false, "Property binding setter for title should not be called after initialization (since its token wasn't impacted by the deltas)");
            }
        });
        
        var serialValue = -1;
        var valBinding = viewModel.createAndRegisterValueBinding(viewModel.rootBindingContext.select("serial"),
            getValue: { () -> JToken in
                return JValue(serialValue);
            },
            setValue: { (valueToken) in
                serialValue = valueToken!.asInt()!;
            }
        );
        
        propBinding.updateViewFromViewModel();
        propBindingTitle.updateViewFromViewModel();
        valBinding.updateViewFromViewModel();
        
        bindingsInitialized = true;
        
        XCTAssertEqual("Serial: 1", serialString);
        XCTAssertEqual("Title: Colors", titleString);
        XCTAssertEqual(1, serialValue);
        
        // We're going to apply some deltas to the view model and verify that the correct dependant bindings got updated,
        // and that no non-dependant bindings got updated
        //
        var deltas = JArray(
        [
            JObject(["path": JValue("serial"), "change": JValue("update"), "value": JValue(2)])
        ]);
        viewModel.updateViewModelData(deltas, updateView: true);

        XCTAssertEqual("Serial: 2", serialString);
        XCTAssertEqual(2, serialValue);
    }
}
