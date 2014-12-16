//
//  ViewController.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("ViewController");

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onRunSynchro(sender: AnyObject) {
        
        Logger.DefaultLogLevel = LogLevel.fromString("Debug")!;

        var appManager = SynchroAppManager();
        appManager.loadState();
        
        var app = appManager.apps[0];
        
        println("Launching Synchro app at endpoint: \(app.endpoint)");
        var synchroVC = SynchroPageViewController(appManager: appManager, app: app);
        
        println("Launching Synchro view controller");
        self.presentViewController(synchroVC, animated: true, completion: nil)
    }
}

