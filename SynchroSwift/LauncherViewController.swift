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

class LauncherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet
    var tableView: UITableView!
    
    var _appManager: SynchroAppManager;
    
    internal init(appManager: SynchroAppManager)
    {
        _appManager = appManager;
        super.init(nibName: "LauncherView", bundle: nil);
        
        self.title = "Synchro Explorer";
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }

    // Without this, you won't get portrait upside down (not in the default set for some fucking reason)
    //
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        logger.info("All of the orientations");
        return UIInterfaceOrientationMask.All;
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        _appManager = SynchroAppManager();
        _appManager.loadState();

        logger.info("viewDidLoad - number of apps: \(_appManager.apps.count)");

        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addClicked:")
        self.navigationItem.rightBarButtonItem = addButton;
    }
    
    override func viewWillAppear(animated: Bool)
    {
        // We hide the navigation controller when navigating to the Synchro page view, so we need
        // so show it here (in case we're navigating back to here)...
        //
        logger.info("viewWillAppear - showing navigation bar");
        self.navigationController?.setNavigationBarHidden(false, animated: false);
        
        self.tableView.reloadData();
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _appManager.apps.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("appCell")
        if (cell == nil)
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "appCell");
        }
        
        cell!.textLabel?.text =  _appManager.apps[indexPath.row].name + " - " + _appManager.apps[indexPath.row].description;
        cell!.detailTextLabel?.text = _appManager.apps[indexPath.row].endpoint;
        cell!.accessoryType = UITableViewCellAccessoryType.DetailDisclosureButton;
        
        logger.info("Rendering cell at position: \(indexPath.row) with value: \(_appManager.apps[indexPath.row].name)");
        
        return cell!
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }

    func addClicked(sender: UIBarButtonItem)
    {
        logger.info("Add clicked...");
        let appDetailVC = AppDetailViewController(appManager: _appManager);
        self.navigationController?.pushViewController(appDetailVC, animated: true);
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        logger.info("Items selected at row #\(indexPath.row)!");
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true); // Normal iOS behavior is to remove the blue highlight
        
        let app = _appManager.apps[indexPath.row];
        
        logger.debug("Launching Synchro app at endpoint: \(app.endpoint)");
        let synchroVC = SynchroPageViewController(appManager: _appManager, app: app);
        
        logger.debug("Launching Synchro page view controller");
        
        // Hide the nav controller, since the Synchro page view has its own...
        self.navigationController?.setNavigationBarHidden(true, animated: false); // !!! This is kind of crappy looking on screen...
        self.navigationController?.pushViewController(synchroVC, animated: true);
    }

    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
    {
        logger.info("Disclosure tapped for row #\(indexPath.row)!");
        
        let app = _appManager.apps[indexPath.row];
        let appDetailVC = AppDetailViewController(appManager: _appManager, app: app);

        self.navigationController?.pushViewController(appDetailVC, animated: true);
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if (editingStyle == UITableViewCellEditingStyle.Delete)
        {
            logger.info("Items deleted at row #\(indexPath.row)!");
            let app = _appManager.apps[indexPath.row];
            _appManager.remove(app);
            _appManager.saveState();
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}
