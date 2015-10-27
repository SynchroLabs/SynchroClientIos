//
//  StateManagerTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/11/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class StateManagerTests: XCTestCase
{
    // This could probably be more thourough.  We create a StateManager and use it to connect to the local server, starting
    // the samples app (which consists of getting the app definition from the server, then getting the "main" page), then on
    // receipt of that page (the Menu page), issue a command which navigates to the Hello page.
    //
    func testStateManager()
    {
        // Force fresh load of AppManager from the bundled seed...
        //
        var userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("seed.json");
        userDefaults.synchronize()

        var appManager = SynchroAppManager();
        
        var app = SynchroApp(
            endpoint: "localhost:1337/api/samples",
            appDefinition: JObject(["name": JValue("synchro-samples"), "description": JValue("Synchro API Samples")]),
            sessionId: nil
        );
        
        appManager.append(app);
        
        var transport = TransportHttp(uri: NSURL(string: "http://\(app.endpoint)")!);
        
        let v = UIViewController();
        
        var stateManager = StateManager(appManager: appManager, app: app, transport: transport, deviceMetrics: DeviceMetrics(controller: v));
        
        var expectationMenu = self.expectationWithDescription("got menu page response")
        var expectationHello = self.expectationWithDescription("got hello page response")

        var responseNumber = 0;
        
        func processPageView(pageView: JObject) -> Void
        {
            responseNumber++;
            print("processPageView response: \(responseNumber)");
            
            if responseNumber == 1
            {
                XCTAssertEqual("Synchro Samples", pageView["title"]!.asString()!);
                expectationMenu.fulfill();
                stateManager.sendCommandRequestAsync("goToView", parameters: JObject(["view": JValue("hello")]));
            }
            else if responseNumber == 2
            {
                XCTAssertEqual("Hello World", pageView["title"]!.asString()!);
                expectationHello.fulfill();
            }
        }
        
        func processMessageBox(messageBox: JObject, commandHandler: CommandHandler) -> Void
        {
            XCTAssert(false, "Unexpected message box call in test");
        }
        
        func processLaunchUrl(primaryUrl: String, secondaryUrl: String?) -> Void
        {
            XCTAssert(false, "Unexpected launch url call in test");
        }
        
        func processChoosePhoto(request: JObject, onComplete: (JObject) -> Void) -> Void
        {
            XCTAssert(false, "Unexpected choose photo call in test");
        }
        
        stateManager.setProcessingHandlers(processPageView, onProcessMessageBox: processMessageBox, onProcessLaunchUrl: processLaunchUrl, onProcessChoosePhoto: processChoosePhoto)
        stateManager.startApplicationAsync();
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
