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

    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad();
    
        // Current orientation: this.InterfaceOrientation
        
        self.view.frame = UIScreen.mainScreen().bounds;
        self.view.backgroundColor = UIColor.whiteColor();
        self.view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight];
        
        let deviceMetrics = DeviceMetrics(controller: self);
        
        // When using AFNetworkHandler via ModernHttpClient component:
        //     HttpClient httpClient = new HttpClient(new AFNetworkHandler());
        //     Transport transport = new TransportHttp(TransportHttp.UriFromHostString(_maaasApp.Endpoint), httpClient);
        //
        // When using WebSocket transport:
        // Transport transport = new iOSTransportWs(this, _maaasApp.Endpoint);
        //
        let transport = TransportHttp(uri: TransportHttp.uriFromHostString(_app.endpoint)!);
        
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
        
        _stateManager.setProcessingHandlers(_pageView.processPageView, onProcessMessageBox: _pageView.processMessageBox, onProcessLaunchUrl: _pageView.processLaunchUrl);
        _stateManager.startApplicationAsync();
        
        logger.debug("Completed viewDidLoad");
    }
        
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        logger.info("App bounds changed (new world order)");
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator);
        
        logger.info("Transition from size - \(UIScreen.mainScreen().bounds) to size - \(size)");
        
        coordinator.animateAlongsideTransition(nil, completion: {context in
            logger.info("Transition to size complete - \(UIScreen.mainScreen().bounds)");
            // !!! Need some kind of viewUpdateAsync (like above).  
            
            if (UIScreen.mainScreen().bounds.width < UIScreen.mainScreen().bounds.height)
            {
                logger.debug("Screen oriented to Portrait");
                self._stateManager.sendViewUpdateAsync(SynchroOrientation.Portrait);
            }
            else
            {
                logger.debug("Screen oriented to Landscape");
                self._stateManager.sendViewUpdateAsync(SynchroOrientation.Landscape);
            }

            // !!! Need to update view metrics somehow (locally and send to server), since container size changed (this would be when 
            //     running multiple apps and having sizable windows - such as Split View and Slide Over modes on iPad in iOS 9).
            
            self._pageView.updateLayout();
        })
        
    }
}
