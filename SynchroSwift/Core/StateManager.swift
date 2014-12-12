//
//  StateManager.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("StateManager");

public typealias CommandHandler = (String) -> Void;

public typealias ProcessPageView = (pageView: JObject) -> Void;
public typealias ProcessMessageBox = (messageBox: JObject, commandHandler: CommandHandler) -> Void;

public class StateManager
{
    var _appManager: SynchroAppManager;
    var _app: SynchroApp;
    var _appDefinition: JObject?;
    var _transport: Transport;
    
    var _transactionNumber = 1;
    func getNewTransactionId() -> Int
    {
        return _transactionNumber++;
    }
    
    var _path: String?;
    var _instanceId: Int?;
    var _instanceVersion: Int?;
    var _isBackSupported = false;
    
    var _viewModel: ViewModel;
    var _onProcessPageView: ProcessPageView?;
    var _onProcessMessageBox: ProcessMessageBox?;
    
    var _deviceMetrics: DeviceMetrics;
    
    public init(appManager: SynchroAppManager, app: SynchroApp, transport: Transport, deviceMetrics: DeviceMetrics)
    {
        _viewModel = ViewModel();
    
        _appManager = appManager;
        _app = app;
        _deviceMetrics = deviceMetrics;
        _transport = transport;
        _transport.setDefaultHandlers(self.processResponseAsync, self.processRequestFailure);
    }
    
    public func isBackSupported() -> Bool
    {
        return _isBackSupported;
    }
    
    public func isOnMainPath() -> Bool
    {
        if let path = _path
        {
            if let appDefinition = _appDefinition
            {
                return (path == appDefinition["mainPage"]!.asString()!);
            }
        }
        return false;
    }
    
    public var viewModel: ViewModel { get { return _viewModel; } }
    
    public var deviceMetrics: DeviceMetrics { get { return _deviceMetrics; } }
    
    public func setProcessingHandlers(onProcessPageView: ProcessPageView, onProcessMessageBox: ProcessMessageBox)
    {
        _onProcessPageView = onProcessPageView;
        _onProcessMessageBox = onProcessMessageBox;
    }
    
    func packageDeviceMetrics() -> JObject
    {
        return JObject(
        [
            "os": JValue(self.deviceMetrics.OS),
            "osName": JValue(self.deviceMetrics.OSName),
            "deviceName": JValue(self.deviceMetrics.DeviceName),
            "deviceType": JValue(self.deviceMetrics.DeviceType.description),
            "deviceClass": JValue(self.deviceMetrics.DeviceClass.description),
            "naturalOrientation": JValue(self.deviceMetrics.NaturalOrientation.description),
            "widthInches": JValue(self.deviceMetrics.WidthInches),
            "heightInches": JValue(self.deviceMetrics.HeightInches),
            "widthDeviceUnits": JValue(self.deviceMetrics.WidthDeviceUnits),
            "heightDeviceUnits": JValue(self.deviceMetrics.HeightDeviceUnits),
            "deviceScalingFactor": JValue(self.deviceMetrics.DeviceScalingFactor),
            "widthUnits": JValue(self.deviceMetrics.WidthUnits),
            "heightUnits": JValue(self.deviceMetrics.HeightUnits),
            "scalingFactor": JValue(self.deviceMetrics.ScalingFactor)
        ]);
    }
    
    func packageViewMetrics(orientation: SynchroOrientation) -> JObject
    {
        if (orientation == self.deviceMetrics.NaturalOrientation)
        {
            return JObject(
            [
                "orientation": JValue(orientation.description),
                "widthInches": JValue(self.deviceMetrics.WidthInches),
                "heightInches": JValue(self.deviceMetrics.HeightInches),
                "widthUnits": JValue(self.deviceMetrics.WidthUnits),
                "heightUnits": JValue(self.deviceMetrics.HeightUnits)
            ]);
        }
        else
        {
            return JObject(
            [
                "orientation": JValue(orientation.description),
                "widthInches": JValue(self.deviceMetrics.HeightInches),
                "heightInches": JValue(self.deviceMetrics.WidthInches),
                "widthUnits": JValue(self.deviceMetrics.HeightUnits),
                "heightUnits": JValue(self.deviceMetrics.WidthUnits)
            ]);
        }
    }
    
    func messageBox(title: String, message: String, buttonLabel: String, buttonCommand: String, onCommand: CommandHandler)
    {
        var messageBox = JObject(
        [
            "title": JValue(title),
            "message": JValue(message),
            "options": JArray(
            [
                JObject(
                [
                    "label": JValue(buttonLabel),
                    "command": JValue(buttonCommand)
                ])
            ])
        ]);
    
        _onProcessMessageBox!(messageBox: messageBox, commandHandler:
        {
            (command) in
            
            onCommand(command);
        });
    }
    
    func processRequestFailure(request: JObject, err: NSError)
    {
        logger.warn("Got request failure for request: \(request)");
    
        messageBox("Connection Error", message: "Error connecting to application server", buttonLabel: "Retry", buttonCommand: "retry", onCommand:
        {
            (command) in
            
            logger.debug("Retrying request after user confirmation (\(command))...");
            self._transport.sendMessage(self._app.sessionId, requestObject: request);
        });
    }
    
    func processResponseAsync(responseAsJSON: JObject)
    {
        // logger.Info("Got response: {0}", (string)responseAsJSON);
        
        if (responseAsJSON["NewSessionId"] != nil)
        {
            var newSessionId = responseAsJSON["NewSessionId"]!.asString()!;
            if (_app.sessionId != nil)
            {
                // Existing client SessionId was replaced by server.  Do we care?  Should we do something (maybe clear any
                // other client session state, if there was any).
                //
                logger.debug("Client session ID of: \(_app.sessionId) was replaced with new session ID: \(newSessionId)");
            }
            else
            {
                logger.debug("Client was assigned initial session ID of: \(newSessionId)");
            }
    
            // SessionId was created/updated by server.  Record it and save state.
            //
            _app.sessionId = newSessionId;
            _appManager.saveState();
        }
    
        if (responseAsJSON["Error"] != nil)
        {
            var jsonError = responseAsJSON["Error"] as JObject;
            var errorMessage = jsonError["message"]!.asString()!;
            logger.warn("Response contained error: \(errorMessage)");
            if (errorMessage == "SyncError")
            {
                if (responseAsJSON["InstanceId"] == nil)
                {
                    // self is a sync error indicating that the server has no instance (do to a corrupt or
                    // re-initialized session).  All we can really do here is re-initialize the app (clear
                    // our local state and do a Page request for the app entry point).
                    //
                    logger.error("ERROR - corrupt server state - need app restart");
                    messageBox("Synchronization Error", message: "Server state was lost, restarting application", buttonLabel: "Restart", buttonCommand: "restart", onCommand:
                    {
                        (command) in
                    
                        logger.warn("Corrupt server state, restarting application...");
                        self.sendAppStartPageRequestAsync();
                    });
                }
                else if (self._instanceId == responseAsJSON["InstanceId"]!.asInt())
                {
                    // The instance that we're on now matches the server instance, so we can safely ignore
                    // the sync error (the request that caused it was sent against a previous instance).
                }
                else
                {
                    // We got a sync error, and the current instance on the server is different that our
                    // instance.  It's possible that the response with the new (correct) instance is still
                    // coming, but unlikey (it would mean it had async/wait user code after page navigation,
                    // which it should not, or that it somehow got sent out of order with respect to self
                    // error response, perhaps over a separate connection that was somehow delayed, but
                    // will eventually complete).
                    //
                    // The best option in self situation is to request a Resync with the server...
                    //
                    logger.warn("ERROR - client state out of sync - need resync");
                    self.sendResyncRequestAsync();
                }
            }
            else
            {
                // Some other kind of error (ClientError or UserCodeError).
                //
                // !!! Maybe we should allow them to choose an option to get more details?  Configurable on the server?
                //
                messageBox("Application Error", message: "The application experienced an error.  Please contact your administrator.", buttonLabel: "Close", buttonCommand: "close", onCommand:
                {
                    (command) in ()
                });
            }
            
            return;
        }
    
        var updateRequired = false;
    
        if (responseAsJSON["App"] != nil) // self means we have a new app
        {
            // Note that we already have an app definition from the MaaasApp that was passed in.  The App in self
            // response was triggered by a request at app startup for the current version of the app metadata
            // fresh from the endpoint (which may have updates relative to whatever we stored when we first found
            // the app at self endpoint and recorded its metadata).
            //
            // !!! Do we want to update our stored app defintion (in MaaasApp, via the AppManager)?  Maybe only if changed?
            //
            _appDefinition = responseAsJSON["App"] as? JObject;
            var appName = _appDefinition!["name"]!.asString()!;
            var appDefinition = _appDefinition!["description"]!.asString()!;
            logger.info("Got app definition for: \(appName) - \(appDefinition)");
            self.sendAppStartPageRequestAsync();
            return;
        }
        else if (responseAsJSON["ViewModel"] != nil) // self means we have a new page/screen
        {
            self._instanceId = responseAsJSON["InstanceId"]!.asInt()!;
            self._instanceVersion = responseAsJSON["InstanceVersion"]!.asInt()!;
            
            var jsonViewModel = responseAsJSON["ViewModel"] as JObject;
            
            self._viewModel.initializeViewModelData(jsonViewModel);
            
            // In certain situations, like a resync where the instance matched but the version
            // was out of date, you might get only the ViewModel (and not the View).
            //
            if (responseAsJSON["View"] != nil)
            {
                self._path = responseAsJSON["Path"]!.asString()!;
                logger.info("Got ViewModel for new view - path: '\(self._path!)', instanceId: \(self._instanceId!), instanceVersion: \(self._instanceVersion!)");

                self._isBackSupported = responseAsJSON["Back"]?.asBool() ?? false;
                
                var jsonPageView = responseAsJSON["View"] as JObject;
                _onProcessPageView!(pageView: jsonPageView);
                
                // If the view model is dirty after rendering the page, then the changes are going to have been
                // written by new view controls that produced initial output (such as location or sensor controls).
                // We need to signal than a viewModel "Update" is required to get these changes to the server.
                //
                updateRequired = self._viewModel.isDirty();
            }
            else
            {
                logger.info("Got ViewModel for existing view - path: '\(self._path!)', instanceId: \(self._instanceId!), instanceVersion: \(self._instanceVersion!)");
                self._viewModel.updateViewFromViewModel();
            }
        }
        else // Updating existing page/screen
        {
            var responseInstanceId = responseAsJSON["InstanceId"]?.asInt();
            if (responseInstanceId == self._instanceId)
            {
                var responseInstanceVersion = responseAsJSON["InstanceVersion"]?.asInt();
                
                // You can get a new view on a view model update if the view is dynamic and was updated
                // based on the previous command/update.
                //
                var viewUpdatePresent = (responseAsJSON["View"] != nil);
            
                if (responseAsJSON["ViewModelDeltas"] != nil)
                {
                    logger.info("Got ViewModelDeltas for path: '\(self._path)' with instanceId: \(responseInstanceId) and instanceVersion: \(responseInstanceVersion)");
                    
                    if ((self._instanceVersion! + 1) == responseInstanceVersion)
                    {
                        self._instanceVersion!++;
                        
                        var jsonViewModelDeltas = responseAsJSON["ViewModelDeltas"]!;
                        // logger.Debug("ViewModel deltas: {0}", jsonViewModelDeltas);
                        
                        // If we don't have a new View, we'll update the current view as part of applying
                        // the deltas.  If we do have a new View, we'll skip that, since we have to
                        // render the new View and do a full update anyway (below).
                        //
                        self._viewModel.updateViewModelData(jsonViewModelDeltas, updateView: !viewUpdatePresent);
                    }
                    else
                    {
                        // Instance version was not one more than current version on view model update
                        //
                        logger.warn("ERROR - instance version mismatch, updates not applied - need resync");
                        self.sendResyncRequestAsync();
                        return;
                    }
                }
    
                if (viewUpdatePresent)
                {
                    if (self._instanceVersion == responseInstanceVersion)
                    {
                        // Render the new page and bind/update it
                        //
                        self._path = responseAsJSON["Path"]!.asString()!;
                        var jsonPageView = responseAsJSON["View"] as JObject;
                        _onProcessPageView!(pageView: jsonPageView);
                        updateRequired = self._viewModel.isDirty();
                    }
                    else
                    {
                        // Instance version was not correct on view update
                        //
                        logger.warn("ERROR - instance version mismatch on view update - need resync");
                        self.sendResyncRequestAsync();
                        return;
                    }
                }
            }
            else if (responseInstanceId < self._instanceId)
            {
                // Response was for a previous instance, so we can safely ignore it (we've moved on).
            }
            else
            {
                // Incorrect instance id
                //
                logger.warn("ERROR - instance id mismatch (response instance id > local instance id), updates not applied - need resync");
                self.sendResyncRequestAsync();
                return;
            }
        }
    
        if (responseAsJSON["MessageBox"] != nil)
        {
            logger.info("Launching message box...");
            var jsonMessageBox = responseAsJSON["MessageBox"] as JObject;
            _onProcessMessageBox!(messageBox: jsonMessageBox, commandHandler:
            {
                (command) in
                
                logger.info("Message box completed with command: '\(command)'");
                self.sendCommandRequestAsync(command);
            });
        }
    
        if (responseAsJSON["NextRequest"] != nil)
        {
            logger.debug("Got NextRequest, composing and sending it now...");
            var requestObject = responseAsJSON["NextRequest"]!.deepClone() as JObject;
            
            if (updateRequired)
            {
                logger.debug("Adding pending viewModel updates to next request (after request processing)");
                addDeltasToRequestObject(requestObject);
            }
            
            _transport.sendMessage(_app.sessionId, requestObject: requestObject);
        }
        else if (updateRequired)
        {
            logger.debug("Sending pending viewModel updates (after request processing)");
            self.sendUpdateRequestAsync();
        }
    }
    
    public func startApplicationAsync()
    {
        logger.info("Loading Synchro application definition for app at: \(_app.endpoint)");
        var requestObject = JObject(
        [
            "Mode": JValue("AppDefinition"),
            "TransactionId": JValue(0)
        ]);
        _transport.sendMessage(nil, requestObject: requestObject);
    }
    
    private func sendAppStartPageRequestAsync()
    {
        self._path = _appDefinition!["mainPage"]!.asString()!;
        
        logger.info("Request app start page at path: '\(self._path!)'");
        
        var requestObject = JObject(
        [
            "Mode": JValue("Page"),
            "Path": JValue(self._path!),
            "TransactionId": JValue(getNewTransactionId()),
            "DeviceMetrics": self.packageDeviceMetrics(), // Send over device metrics (these won't ever change, per session)
            "ViewMetrics": self.packageViewMetrics(_deviceMetrics.CurrentOrientation) // Send over view metrics
        ]);
        
        _transport.sendMessage(_app.sessionId, requestObject: requestObject);
    }
    
    private func sendResyncRequestAsync()
    {
        logger.info("Sending resync for path: '\(self._path)'");
        
        var requestObject = JObject(
        [
            "Mode": JValue("Resync"),
            "Path": JValue(self._path!),
            "TransactionId": JValue(getNewTransactionId()),
            "InstanceId": JValue(self._instanceId!),
            "InstanceVersion": JValue(self._instanceVersion!)
        ]);
        
        _transport.sendMessage(_app.sessionId, requestObject: requestObject);
    }
    
    private func addDeltasToRequestObject(requestObject: JObject) -> Bool
    {
        var vmDeltas = self._viewModel.collectChangedValues();
        if (vmDeltas.count > 0)
        {
            var deltas = JArray();
            for (deltaKey, deltaValue) in vmDeltas
            {
                deltas.append(JObject(
                [
                    "path": JValue(deltaKey),
                    "value": deltaValue.deepClone()
                ]));
            }
        
            requestObject["ViewModelDeltas"] = deltas;
            return true;
        }
        
        return false;
    }
    
    public func sendUpdateRequestAsync()
    {
        logger.debug("Process update for path: '\(self._path)'");
        
        // We check dirty here, even though addDeltas is a noop if there aren't any deltas, in order
        // to avoid generating a new transaction id when we're not going to do a new transaction.
        //
        if (self._viewModel.isDirty())
        {
            var requestObject = JObject(
            [
                "Mode": JValue("Update"),
                "Path": JValue(self._path!),
                "TransactionId": JValue(getNewTransactionId()),
                "InstanceId": JValue(self._instanceId!),
                "InstanceVersion": JValue(self._instanceVersion!)
            ]);
            
            if (addDeltasToRequestObject(requestObject))
            {
                // Only going to send the updates if there were any changes...
                _transport.sendMessage(_app.sessionId, requestObject: requestObject);
            }
        }
    }
    
    public func sendCommandRequestAsync(command: String, parameters: JObject? = nil)
    {
        logger.info("Sending command: '\(command)' for path: '\(self._path!)'");
        
        var requestObject = JObject(
        [
            "Mode": JValue("Command"),
            "Path": JValue(self._path!),
            "TransactionId": JValue(getNewTransactionId()),
            "InstanceId": JValue(self._instanceId!),
            "InstanceVersion": JValue(self._instanceVersion!),
            "Command": JValue(command)
        ]);
        
        if (parameters != nil)
        {
            requestObject["Parameters"] = parameters;
        }
        
        addDeltasToRequestObject(requestObject);
        
        _transport.sendMessage(_app.sessionId, requestObject: requestObject);
    }
    
    public func sendBackRequestAsync()
    {
        logger.info("Sending 'back' for path: '\(self._path)'");
        
        var requestObject = JObject(
        [
            "Mode": JValue("Back"),
            "Path": JValue(self._path!),
            "TransactionId": JValue(getNewTransactionId()),
            "InstanceId": JValue(self._instanceId!),
            "InstanceVersion": JValue(self._instanceVersion!)
        ]);
        
        _transport.sendMessage(_app.sessionId, requestObject: requestObject);
    }
    
    public func sendViewUpdateAsync(orientation: SynchroOrientation)
    {
        logger.info("Sending ViewUpdate for path: '\(self._path)'");
        
        // Send the updated view metrics
        var requestObject = JObject(
        [
            "Mode": JValue("ViewUpdate"),
            "Path": JValue(self._path!),
            "TransactionId": JValue(getNewTransactionId()),
            "InstanceId": JValue(self._instanceId!),
            "InstanceVersion": JValue(self._instanceVersion!),
            "ViewMetrics": self.packageViewMetrics(orientation)
        ]);
        
        _transport.sendMessage(_app.sessionId, requestObject: requestObject);
    }
}
