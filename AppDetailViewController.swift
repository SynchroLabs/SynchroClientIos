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
    case find
    case add
    case view
};

open class AppDetailViewController: UIViewController
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
    
    var scanButton: UIBarButtonItem?;
    var scannedUrl: String?

    public init(appManager: SynchroAppManager, app: SynchroApp? = nil)
    {
        _appManager = appManager;
        _app = app;
        
        super.init(nibName: "AppDetailView", bundle: nil);

        self.title = "App";
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
    
    func updateVisibility(_ mode: DisplayMode)
    {
        appEndpointEdit.isHidden = mode != DisplayMode.find;
        appFindButton.isHidden = mode != DisplayMode.find;
        
        // Show/hide toolbar button
        scanButton?.isEnabled = mode == DisplayMode.find;
        scanButton?.tintColor = mode == DisplayMode.find ? nil : UIColor.clear;
        
        appEndpointLabel.isHidden = mode == DisplayMode.find;
        appNameCaption.isHidden = mode == DisplayMode.find;
        appNameLabel.isHidden = mode == DisplayMode.find;
        appDescriptionCaption.isHidden = mode == DisplayMode.find;
        appDescriptionLabel.isHidden = mode == DisplayMode.find;
        
        appSaveButton.isHidden = mode != DisplayMode.add;
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad()
    {
        super.viewDidLoad()
        
        scanButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.camera, target: self, action: #selector(scanClicked))
        self.navigationItem.rightBarButtonItem = scanButton;

        if (_app != nil)
        {
            populate();
            updateVisibility(DisplayMode.view);
        }
        else
        {
            updateVisibility(DisplayMode.find);
        }
    }
    
    func scanClicked(_ sender: UIBarButtonItem)
    {
        logger.info("Scan pushed");
        self.scannedUrl = nil;
        let qrVC = QRCodeViewController(appDetailVC: self);
        self.navigationController?.pushViewController(qrVC, animated: true);
    }
    
    override open func viewDidAppear(_ animated: Bool)
    {
        if (scannedUrl != nil)
        {
            appEndpointEdit.text = scannedUrl;
            doFind();
        }
    }
    
    func alert(_ title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil));
        self.present(alert, animated: true, completion: nil)
    }

    func doFind()
    {
        if let endpoint = appEndpointEdit.text
        {
            if (endpoint.length > 0)
            {
                logger.info("Finding enpoint: \(endpoint)");
                let managedApp = _appManager.getApp(endpoint);
                if (managedApp != nil)
                {
                    alert("Synchro Application Search", message: "You already have a Synchro application with the supplied endpoint in your list");
                    return;
                }
                
                if let endpointUri = TransportHttp.uriFromHostString(endpoint)
                {
                    let transport = TransportHttp(uri: endpointUri);
                    
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
                                self.updateVisibility(DisplayMode.add);
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
    
    @IBAction func onFind(_ sender: AnyObject)
    {
        logger.info("Find pushed");
        doFind();
    }

    @IBAction func onSave(_ sender: AnyObject)
    {
        logger.info("Save pushed");
        _appManager.append(_app!);
        _appManager.saveState();
        self.navigationController!.popViewController(animated: true);
    }
    
    override open func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}
