//
//  AppDetailViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 1/11/15.
//  Copyright (c) 2015 Robert Dickinson. All rights reserved.
//

import UIKit

private var logger = Logger.getLogger("AppDetailViewController");

enum DisplayMode
{
    case Find
    case Add
    case View
};

public class AppDetailViewController: UIViewController
{
    @IBOutlet weak var appEndpointLabel: UILabel!
    @IBOutlet weak var appEndpointEdit: UITextField!

    @IBOutlet weak var appFindButton: UIButton!

    @IBOutlet weak var appNameCaption: UILabel!
    @IBOutlet weak var appNameLabel: UILabel!
    
    @IBOutlet weak var appDescriptionCaption: UILabel!
    @IBOutlet weak var appDescriptionLabel: UILabel!
    
    @IBOutlet weak var appSaveButton: UIButton!

    var _appManager: SynchroAppManager;
    var _app: SynchroApp?;

    public init(appManager: SynchroAppManager, app: SynchroApp? = nil)
    {
        _appManager = appManager;
        _app = app;
        
        super.init(nibName: "AppDetailView", bundle: nil);
        
        self.title = "App Detail";
    }

    func populate()
    {
        if let app = _app
        {
            logger.info("Displaying app name: \(app.name)");
            appEndpointLabel.text = app.endpoint;
            appNameLabel.text = app.name;
            appDescriptionLabel.text = app.description;
        }
    }
    
    func updateVisibility(mode: DisplayMode)
    {
        appEndpointEdit.hidden = mode != DisplayMode.Find;
        appFindButton.hidden = mode != DisplayMode.Find;
        
        appEndpointLabel.hidden = mode == DisplayMode.Find;
        appNameCaption.hidden = mode == DisplayMode.Find;
        appNameLabel.hidden = mode == DisplayMode.Find;
        appDescriptionCaption.hidden = mode == DisplayMode.Find;
        appDescriptionLabel.hidden = mode == DisplayMode.Find;
        
        appSaveButton.hidden = mode != DisplayMode.Add;
    }
    
    required public init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad()
    {
        super.viewDidLoad()

        if (_app != nil)
        {
            populate();
            updateVisibility(DisplayMode.View);
        }
        else
        {
            updateVisibility(DisplayMode.Find);
        }
    }
    
    func alert(title: String, message: String)
    {
        if let gotModernAlert: AnyClass = NSClassFromString("UIAlertController")
        {
            // Use UIAlertController (new hotness as of 8.0)
            //
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: nil));
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
            // Use UIAlertView (deprecated as of 8.0, but only thing that works pre-8.0)
            //
            var alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "Close");
            alert.show();
        }
    }
    
    @IBAction func onFind(sender: AnyObject)
    {
        logger.info("Find pushed");
        
        if let endpoint = appEndpointEdit.text
        {
            if (endpoint.length > 0)
            {
                logger.info("Finding enpoint: \(endpoint)");
                var managedApp = _appManager.getApp(endpoint);
                if (managedApp != nil)
                {
                    alert("Synchro Application Search", message: "You already have a Synchro application with the supplied endpoint in your list");
                    return;
                }
                
                if let endpointUri = TransportHttp.uriFromHostString(endpoint)
                {
                    var transport = TransportHttp(uri: endpointUri);
                    
                    transport.getAppDefinition(
                        { (appDefinition) in
                            if (appDefinition == nil)
                            {
                                self.alert("Synchro Application Search", message: "No Synchro application found at the supplied endpoint");
                            }
                            else
                            {
                                self._app = SynchroApp(endpoint: endpoint, appDefinition: appDefinition!);
                                self.populate();
                                self.updateVisibility(DisplayMode.Add);
                            }
                    });        
                }
                else
                {
                    alert("Synchro Application Search", message: "Endpoint not formatted correctly");
                    
                }
            }
        }
    }

    @IBAction func onSave(sender: AnyObject)
    {
        logger.info("Save pushed");
        _appManager.append(_app!);
        _appManager.saveState();
        self.navigationController!.popViewControllerAnimated(true);
    }
    
    override public func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}
