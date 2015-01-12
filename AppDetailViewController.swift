//
//  AppDetailViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 1/11/15.
//  Copyright (c) 2015 Robert Dickinson. All rights reserved.
//

import UIKit

private var logger = Logger.getLogger("AppDetailViewController");

public class AppDetailViewController: UIViewController
{
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var appDescriptionLabel: UILabel!
    @IBOutlet weak var appEndpointLabel: UILabel!
    
    var _appManager: SynchroAppManager;
    var _app: SynchroApp;

    public init(appManager: SynchroAppManager, app: SynchroApp)
    {
        _appManager = appManager;
        _app = app;
        
        super.init(nibName: "AppDetailView", bundle: nil);
        
        self.title = "App Detail";
    }

    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad()
    {
        super.viewDidLoad()

        logger.info("App name: \(_app.name)");
        appNameLabel.text = _app.name;
        appDescriptionLabel.text = _app.description;
        appEndpointLabel.text = _app.endpoint;
    }

    override public func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
