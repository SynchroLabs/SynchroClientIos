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
        
        self.title = "Synchro";
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }

    // Without this, you won't get portrait upside down (not in the default set for some fucking reason)
    //
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        logger.info("All of the orientations");
        return UIInterfaceOrientationMask.all;
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        _appManager = SynchroAppManager();
        _appManager.loadState();

        logger.info("viewDidLoad - number of apps: \(_appManager.apps.count)");

        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addClicked))
        self.navigationItem.rightBarButtonItem = addButton;
    }
    
    override func viewWillAppear(_ animated: Bool)
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return _appManager.apps.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "appCell")
        if (cell == nil)
        {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "appCell");
        }
        
        cell!.textLabel?.text =  _appManager.apps[(indexPath as NSIndexPath).row].name + " - " + _appManager.apps[(indexPath as NSIndexPath).row].description;
        cell!.detailTextLabel?.text = _appManager.apps[(indexPath as NSIndexPath).row].endpoint;
        cell!.accessoryType = UITableViewCellAccessoryType.detailDisclosureButton;
        
        logger.info("Rendering cell at position: \((indexPath as NSIndexPath).row) with value: \(_appManager.apps[(indexPath as NSIndexPath).row].name)");
        
        return cell!
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }

    func addClicked(_ sender: UIBarButtonItem)
    {
        logger.info("Add clicked...");
        let appDetailVC = AppDetailViewController(appManager: _appManager);
        self.navigationController?.pushViewController(appDetailVC, animated: true);
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        logger.info("Items selected at row #\((indexPath as NSIndexPath).row)!");
        
        tableView.deselectRow(at: indexPath, animated: true); // Normal iOS behavior is to remove the blue highlight
        
        let app = _appManager.apps[(indexPath as NSIndexPath).row];
        
        logger.debug("Launching Synchro app at endpoint: \(app.endpoint)");
        let synchroVC = SynchroPageViewController(appManager: _appManager, app: app);
        
        logger.debug("Launching Synchro page view controller");
        
        // Hide the nav controller, since the Synchro page view has its own...
        self.navigationController?.setNavigationBarHidden(true, animated: false); // !!! This is kind of crappy looking on screen...
        self.navigationController?.pushViewController(synchroVC, animated: true);
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
    {
        logger.info("Disclosure tapped for row #\((indexPath as NSIndexPath).row)!");
        
        let app = _appManager.apps[(indexPath as NSIndexPath).row];
        let appDetailVC = AppDetailViewController(appManager: _appManager, app: app);

        self.navigationController?.pushViewController(appDetailVC, animated: true);
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if (editingStyle == UITableViewCellEditingStyle.delete)
        {
            logger.info("Items deleted at row #\((indexPath as NSIndexPath).row)!");
            let app = _appManager.apps[(indexPath as NSIndexPath).row];
            _appManager.remove(app);
            _appManager.saveState();
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
