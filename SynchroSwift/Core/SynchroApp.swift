//
//  SynchroApp.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/5/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation


// The AppDefinition is provided by the Synchro server (it is the contents of the synchro.json file in the Synchro app directory).
// This is a JSON object that is modeled more or less after the NPM package structure.  For now we store it in the
// SynchroApp as the JSON object that it is and just provide getters for some well-known members.  Once the AppDefinition
// gets nailed down, we might do more processing of it here (or we might not).
//

open class SynchroApp
{
    open var endpoint: String;
    open var appDefinition: JObject;
    open var sessionId: String?;
    
    open var name: String { get { return appDefinition["name"]!.asString()!; } }
    open var description: String { get { return appDefinition["description"]!.asString()!; } }
    
    public init(endpoint: String, appDefinition: JObject, sessionId: String? = nil)
    {
        self.endpoint = endpoint;
        self.appDefinition = appDefinition;
        self.sessionId = sessionId;
    }
}

// If AppSeed is present, client apps should launch that app directly and suppress any "launcher" interface. If not present,
// then client apps should provide launcher interface showing content of Apps.
//
// Implementation:
//
// On startup:
//   Inspect bundled seed.json to see if it contains a "seed"
//     If yes: Start Maaas app at that seed.
//     If no: determine whether any local app manager state exists (stored locally on the device)
//       If no: initialize local app manager state from seed.json
//     Show launcher interface based on local app manager state
//
// Launcher interface shows a list of apps (from the "apps" key in the app manager state)
//   Provides ability to launch an app
//   Provides ability to add (find?) and remove app
//     Add/find app:
//       User provides endpoint
//       We look up app definition at endpoint and display to user
//       User confirms and we add to AppManager.Apps (using endpoint and appDefinition to create MaaasApp)
//       We serialize AppManager via saveState()
//
open class SynchroAppManager
{
    var _appSeed: SynchroApp? = nil;
    var _apps = Array<SynchroApp>();
    
    open var appSeed: SynchroApp? { get { return _appSeed; } }
    open var apps: Array<SynchroApp> { get { return _apps; } }

    public init()
    {
    }
    
    open func getApp(_ endpoint: String) -> SynchroApp?
    {
        if ((_appSeed != nil) && (_appSeed!.endpoint == endpoint))
        {
            return _appSeed;
        }
        else
        {
            for app in _apps
            {
                if (app.endpoint == endpoint)
                {
                    return app;
                }
            }
        }
        return nil;
    }

    // When you hand back objects via property getters in Swift, the objected returned is a copy and immutable.
    // This means you can't just expose the app list via the "apps" property and let consumers add/remove apps.
    // The best practice for this scenatio seems to be adding your own collection methods to the containing object,
    // as we have done with append and remove below.
    //
    open func append(_ app: SynchroApp)
    {
        _apps.append(app);
    }
    
    open func remove(_ app: SynchroApp) -> Bool
    {
        return _apps.removeObject(app);
    }
    
    open func updateApp(_ app: SynchroApp)
    {
        if _appSeed?.endpoint == app.endpoint
        {
            _appSeed = app;
        }
        else
        {
            _apps = _apps.filter { $0.endpoint != app.endpoint };
            _apps.append(app);
        }
    }
    
    class func appFromJson(_ json: JObject) -> SynchroApp
    {
        let endpoint = json["endpoint"]!.asString()!;
        let appDefinition = json["definition"]!.deepClone() as! JObject;
        let sessionId = json["sessionId"]?.asString();
    
        return SynchroApp(endpoint: endpoint, appDefinition: appDefinition, sessionId: sessionId);
    }
    
    class func appToJson(_ app: SynchroApp) -> JObject
    {
        return JObject(
        [
            "endpoint": JValue(app.endpoint),
            "definition": app.appDefinition.deepClone(),
            "sessionId": app.sessionId != nil ? JValue(app.sessionId!) : JValue()
        ]);
    }

    open func serializeFromJson(_ json: JObject)
    {
        if let seed = json["seed"] as? JObject
        {
            _appSeed = SynchroAppManager.appFromJson(seed);
        }
    
        if let apps = json["apps"] as? JArray
        {
            for item in apps
            {
                if let app = item as? JObject
                {
                    _apps.append(SynchroAppManager.appFromJson(app));
                }
            }
        }
    }
    
    open func serializeToJson() -> JObject
    {
        let obj = JObject();
    
        if let seed = _appSeed
        {
            obj["seed"] = SynchroAppManager.appToJson(seed);
        }
    
        if (_apps.count > 0)
        {
            let array = JArray();
            for app in _apps
            {
                array.append(SynchroAppManager.appToJson(app));
            }
            obj["apps"] = array;
        }
    
        return obj;
    }

    func loadBundledState() -> String?
    {
        if let path = Bundle.main.path(forResource: "seed", ofType: "json")
        {
            return try? String(contentsOfFile: path, encoding: String.Encoding.utf8)
        }

        return nil;
    }

    func loadLocalState() -> String?
    {
        let userDefaults = UserDefaults.standard;
        return userDefaults.string(forKey: "seed.json");
    }
    
    func saveLocalState(_ contents: String) -> Bool
    {
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(contents, forKey: "seed.json")
        return userDefaults.synchronize()
    }
    
    open func loadState() -> Bool
    {
        // Load the local state
        //
        var localState = loadLocalState();
        if localState == nil
        {
            // If there is no local state, initialize the local state from the bundled state and serialize
            //
            localState = loadBundledState()!;
            saveLocalState(localState!);
        }
        
        let parsedLocalState = JToken.parse(localState!) as! JObject;
        serializeFromJson(parsedLocalState);
    
        return true;
    }
    
    open func saveState() -> Bool
    {
        let json = serializeToJson();
        return saveLocalState(json.toJson());
    }
}


