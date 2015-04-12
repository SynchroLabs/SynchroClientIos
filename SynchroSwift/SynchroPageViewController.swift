//
//  SynchroPageViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/15/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("SynchroPageViewController");

public class SynchroPageViewController : UIViewController
{
    var _appManager: SynchroAppManager;
    var _app: SynchroApp;
    
    var _stateManager: StateManager!;
    var _pageView: iOSPageView!;
    
    public init(appManager: SynchroAppManager, app: SynchroApp)
    {
        _appManager = appManager;
        _app = app;
        super.init(nibName: nil, bundle: nil);
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad();
    
        // Current orientation: this.InterfaceOrientation
        
        self.view.frame = UIScreen.mainScreen().bounds;
        self.view.backgroundColor = UIColor.whiteColor();
        self.view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight;
        
        var deviceMetrics = DeviceMetrics(controller: self);
        
        // When using AFNetworkHandler via ModernHttpClient component:
        //     HttpClient httpClient = new HttpClient(new AFNetworkHandler());
        //     Transport transport = new TransportHttp(TransportHttp.UriFromHostString(_maaasApp.Endpoint), httpClient);
        //
        // When using WebSocket transport:
        // Transport transport = new iOSTransportWs(this, _maaasApp.Endpoint);
        //
        var transport = TransportHttp(uri: TransportHttp.uriFromHostString(_app.endpoint)!);
        
        var backToMenu:(() -> Void)? = nil;
        if ((_appManager.appSeed == nil) && (self.navigationController != nil))
        {
            // If we are't nailed to a predefined app, then we'll allow the app to navigate back to
            // this page from its top level page.
            //
            backToMenu = { () -> Void in
                // If we are't nailed to a predefined app, then we'll allow the app to navigate back to
                // this page from its top level page.
                //
                logger.debug("Going back...");
                self.navigationController!.popViewControllerAnimated(true);
            };
        }

        _stateManager = StateManager(appManager: _appManager, app: _app, transport: transport, deviceMetrics: deviceMetrics);
        _pageView = iOSPageView(stateManager: _stateManager, viewModel: _stateManager.viewModel, viewController: self, panel: self.view, doBackToMenu: backToMenu);
        
        _stateManager.setProcessingHandlers(_pageView.processPageView, onProcessMessageBox: _pageView.processMessageBox);
        _stateManager.startApplicationAsync();
        
        logger.debug("Completed viewDidLoad");
    }
    
    private func normalizeOrientation(orientation: UIInterfaceOrientation) -> UIInterfaceOrientation
    {
        if (orientation == UIInterfaceOrientation.LandscapeRight)
        {
            return UIInterfaceOrientation.LandscapeLeft;
        }
        else if (orientation == UIInterfaceOrientation.PortraitUpsideDown)
        {
            return UIInterfaceOrientation.Portrait;
        }
        
        return orientation;
    }
    
    // When the device rotates, the OS calls this method to determine if it should try and rotate the
    // application and then call WillAnimateRotation
    //
    // The method that this method overrides is obsolete, which was causing a compiler warning.  Since
    // we allow rotation in all cases (at least for now), we don't need this anyway.
    /*
    public override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool
    {
        // We're passed to orientation that it will rotate to. We could just return true, but this
        // switch illustrates how you can test for the different cases.
        //
        switch (toInterfaceOrientation)
        {
            case UIInterfaceOrientation.LandscapeLeft:
            case UIInterfaceOrientation.LandscapeRight:
            case UIInterfaceOrientation.Portrait:
            case UIInterfaceOrientation.PortraitUpsideDown:
            default:
                return true;
        }
    }
    */
    
    // Is called when the OS is going to rotate the application. It handles rotating the status bar
    // if it's present, as well as it's controls like the navigation controller and tab bar, but you
    // must handle the rotation of your view and associated subviews. This call is wrapped in an
    // animation block in the underlying implementation, so it will automatically animate your control
    // repositioning.
    //
    public override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval)
    {
        // this.InterfaceOrientation == UIInterfaceOrientation.
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration);
        
        // Do our own rotation handling here
        if (normalizeOrientation(toInterfaceOrientation) == UIInterfaceOrientation.Portrait)
        {
            logger.debug("Screen oriented to Portrait");
            _stateManager.sendViewUpdateAsync(SynchroOrientation.Portrait);
        }
        else
        {
            logger.debug("Screen oriented to Landscape");
            _stateManager.sendViewUpdateAsync(SynchroOrientation.Landscape);
        }
        
        _pageView.updateLayout();
    }
}
