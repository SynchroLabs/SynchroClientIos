//
//  AppDelegate.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import UIKit

private var logger = Logger.getLogger("AppDelegate");

class SynchroUINavigationController : UINavigationController
{
    // Without this, you won't get portrait upside down (not in the default set for some fucking reason)
    //
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all;
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var viewController: UIViewController?;
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        logger.info("Application started...");
        
        let rootNavigationController = SynchroUINavigationController();
        
        rootNavigationController.supportedInterfaceOrientations
        
        window = UIWindow(frame: UIScreen.main.bounds);
        
        let appManager = SynchroAppManager();
        appManager.loadState();
        
        if let appSeed = appManager.appSeed
        {
            viewController = SynchroPageViewController(appManager: appManager, app: appSeed);
            
            // We hide the nav controller (since we don't use it - the SynchroPageViewController has it's own nav bar).
            // If you don't do this, you get an empty nav bar that completely covers the SynchrPageViewController nav bar.
            //
            rootNavigationController.setNavigationBarHidden(true, animated: false);
        }
        else
        {
            viewController = LauncherViewController(appManager: appManager);
        }
        
        rootNavigationController.pushViewController(viewController!, animated: false);
        window!.rootViewController = rootNavigationController;
        window!.makeKeyAndVisible();
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        logger.info("Application will resign active...");
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        logger.info("Application did enter background...");
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        logger.info("Application will enter foreground...");
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        logger.info("Application did become active...");
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        logger.info("Application will terminate...");
    }
}

