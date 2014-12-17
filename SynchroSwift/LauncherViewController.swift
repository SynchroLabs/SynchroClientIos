//
//  LauncherViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/16/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("LauncherViewController");

class LauncherViewController: UIViewController
{
    var _appManager: SynchroAppManager;
    
    internal init(appManager: SynchroAppManager)
    {
        _appManager = appManager;
        super.init(nibName: "LauncherView", bundle: nil);
        
        self.title = "Synchro";
    }

    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // We hide the navigation controller when navigating to the Synchro page view, so we need
        // so show it here (in case we're navigating back to here)...
        //
        logger.debug("viewDidLoad - showing navigation bar");
        self.navigationController?.setNavigationBarHidden(false, animated: false);
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onRunSynchro(sender: AnyObject)
    {
        Logger.DefaultLogLevel = LogLevel.fromString("Debug")!;
        
        var appManager = SynchroAppManager();
        appManager.loadState();
        
        var app = appManager.apps[0];
        
        logger.debug("Launching Synchro app at endpoint: \(app.endpoint)");
        var synchroVC = SynchroPageViewController(appManager: appManager, app: app);
        
        logger.debug("Launching Synchro page view controller");
        
        // Hide the nav controller, since the Synchro page view has its own...
        self.navigationController?.setNavigationBarHidden(true, animated: false);
        self.navigationController?.pushViewController(synchroVC, animated: true);
    }
}