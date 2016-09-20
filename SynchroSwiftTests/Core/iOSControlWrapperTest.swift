//
//  iOSControlWrapperTest.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/14/15.
//  Copyright © 2015 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class iOSControlWrapperTests: XCTestCase
{
    let viewModelObj = JObject(
    [
        "num": JValue(1),
        "str": JValue("Words words words"),
        "testStyle1": JObject(
        [
            "attr1": JValue("attr1fromStyle1"),
            "thicknessAttr": JObject(
            [
                "bottom": JValue(9)
            ]),
            "font": JObject(
            [
                "face": JValue("SanSerif"),
                "bold": JValue(true),
                "italic": JValue(true)
            ]),
            "fontsize": JValue(24),
            
        ]),
        "testStyle2": JObject(
        [
            "attr1": JValue("attr1fromStyle2"),
            "attr2": JValue("attr2fromStyle2"),
            "thicknessAttr": JValue(10),
            "font": JObject(
            [
                "size": JValue(26)
            ])
        ])
    ]);
    
    class TestDeviceMetrics : DeviceMetrics
    {
        // We don't want to do any device units or font points math - to make it easier to see if the values we set are the
        // same as what gets set into various device-specific values (thicknesses and font size mostly).
        //
        internal override init (controller: UIViewController)
        {
            super.init(controller: controller);
        }
        
        internal override func SynchroUnitsToDeviceUnits(_ synchroUnits: Double) -> Double
        {
            return synchroUnits;
        }
        
        internal override func TypographicPointsToMaaasUnits(_ points: Double) -> Double
        {
            return points;
        }
    }
    
    func getTestStateManager() -> StateManager
    {
        let appManager = SynchroAppManager();
        
        let app = SynchroApp(
            endpoint: "localhost:1337/api/samples",
            appDefinition: JObject(["name": JValue("synchro-samples"), "description": JValue("Synchro API Samples")]),
            sessionId: nil
        );
        
        appManager.append(app);
        
        let transport = TransportHttp(uri: URL(string: "http://\(app.endpoint)")!);
        
        let v = UIViewController();
        
        return StateManager(appManager: appManager, app: app, transport: transport, deviceMetrics: TestDeviceMetrics(controller: v));
    }

    class TestFontSetter : FontSetter
    {
        var FaceType = FontFaceType.font_DEFAULT;
        var Size = 12.0;
        var Bold = false;
        var Italic = false;
        
        func setFaceType(_ faceType: FontFaceType)
        {
            FaceType = faceType;
        }
        
        func setSize(_ size: Double)
        {
            Size = size;
        }
        
        func setBold(_ bold: Bool)
        {
            Bold = bold;
        }
        
        func setItalic(_ italic: Bool)
        {
            Italic = italic;
        }
    }
    
    class TestThicknessSetter : ThicknessSetter
    {
        var Left = 0.0;
        var Top = 0.0;
        var Right = 0.0;
        var Bottom = 0.0;
        
        func setThicknessLeft(_ thickness: Double)
        {
            Left = thickness;
        }
        
        func setThicknessTop(_ thickness: Double)
        {
            Top = thickness;
        }
        
        func setThicknessRight(_ thickness: Double)
        {
            Right = thickness;
        }
        
        func setThicknessBottom(_ thickness: Double)
        {
            Bottom = thickness;
        }
    }
    
    func getTestRootControl() -> iOSControlWrapper
    {
        let viewModel = ViewModel();
        viewModel.initializeViewModelData(viewModelObj);
        
        let stateManager = getTestStateManager();
        let pageView = iOSPageView(stateManager: stateManager, viewModel: viewModel, viewController: UIViewController(), panel: UIView(), launchedFromMenu: false);
        
        return iOSControlWrapper(pageView: pageView, stateManager: stateManager, viewModel: viewModel, bindingContext: viewModel.rootBindingContext, control: UIView());
    }
    
    class iOSTestControlWrapper : iOSControlWrapper
    {
        var attr1: String?;
        var attr2: String?;
        let thicknessSetter = TestThicknessSetter();
        let fontSetter = TestFontSetter();

        override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
        {
            super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
            
            processElementProperty(controlSpec, attributeName: "attr1", setValue: { (value) in self.attr1 = self.toString(value) });
            processElementProperty(controlSpec, attributeName: "attr2", setValue: { (value) in self.attr2 = self.toString(value) });
            processThicknessProperty(controlSpec, attributeName: "thicknessAttr", thicknessSetter: thicknessSetter)
            processFontAttribute(controlSpec, fontSetter: fontSetter);
        }
    }
    
    func testStyleExplicitNoStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["attr1": JValue("attr1val")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);
        
        XCTAssert("attr1val" == testControl.attr1);
        XCTAssert(nil == testControl.attr2);
    }
    
    func testStyleExplicitWithStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1"), "attr1": JValue("attr1val")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert("attr1val" == testControl.attr1);
        XCTAssert(nil == testControl.attr2);
    }
    
    func testStyleFromStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);
    
        XCTAssert("attr1fromStyle1" == testControl.attr1);
        XCTAssert(nil == testControl.attr2);
    }
    
    func testStyleFromStyles()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1, testStyle2")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);
 
        XCTAssert("attr1fromStyle1" == testControl.attr1);
        XCTAssert("attr2fromStyle2" == testControl.attr2);
    }
    
    func testStyleFromStylesPriority()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle2, testStyle1")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert("attr1fromStyle2" == testControl.attr1);
        XCTAssert("attr2fromStyle2" == testControl.attr2);
    }
    
    func testStyleExplicitThicknessNoStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["thicknessAttr": JValue(5)]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(5 == testControl.thicknessSetter.Top);
        XCTAssert(5 == testControl.thicknessSetter.Left);
        XCTAssert(5 == testControl.thicknessSetter.Bottom);
        XCTAssert(5 == testControl.thicknessSetter.Right);
    }
    
    func testStyleExplicitThicknessObjNoStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["thicknessAttr": JObject(["top": JValue(5), "left": JValue(6), "bottom": JValue(7), "right": JValue(8)])]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(5 == testControl.thicknessSetter.Top);
        XCTAssert(6 == testControl.thicknessSetter.Left);
        XCTAssert(7 == testControl.thicknessSetter.Bottom);
        XCTAssert(8 == testControl.thicknessSetter.Right);
    }
    
    func testStyleExplicitThicknessObjAndStyles()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1, testStyle2"), "thicknessAttr": JObject(["top": JValue(5), "left": JValue(6)])]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(5 == testControl.thicknessSetter.Top);
        XCTAssert(6 == testControl.thicknessSetter.Left);
        XCTAssert(9 == testControl.thicknessSetter.Bottom);
        XCTAssert(10 == testControl.thicknessSetter.Right);
    }
    
    func testStyleExplicitFontSize()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["fontsize": JValue(20)]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(20 == testControl.fontSetter.Size);
    }
    
    func testStyleExplicitFontSizeFromObject()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["font": JObject(["size": JValue(22)])]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(22 == testControl.fontSetter.Size);
    }
    
    func testStyleFontFromStyle()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1, testStyle2")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(24 == testControl.fontSetter.Size);
        XCTAssert(true == testControl.fontSetter.Bold);
        XCTAssert(true == testControl.fontSetter.Italic);
        XCTAssert(FontFaceType.font_SANSERIF == testControl.fontSetter.FaceType);
    }
    
    func testStyleFontFromStylePriority()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle2, testStyle1")]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(26 == testControl.fontSetter.Size);
        XCTAssert(true == testControl.fontSetter.Bold);
        XCTAssert(true == testControl.fontSetter.Italic);
        XCTAssert(FontFaceType.font_SANSERIF == testControl.fontSetter.FaceType);
    }
    
    func testStyleFontFromStyleExplicitOverride()
    {
        let rootControl = getTestRootControl();
        
        let controlSpec = JObject(["style": JValue("testStyle1"), "font": JObject(["size": JValue(28), "italic": JValue(false)])]);
        let testControl = iOSTestControlWrapper(parent: rootControl, bindingContext: rootControl.bindingContext, controlSpec: controlSpec);

        XCTAssert(28 == testControl.fontSetter.Size);
        XCTAssert(true == testControl.fontSetter.Bold);
        XCTAssert(false == testControl.fontSetter.Italic);
        XCTAssert(FontFaceType.font_SANSERIF == testControl.fontSetter.FaceType);
    }
}
