//
//  Transport.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

public typealias ResponseHandler = (response: JObject) -> Void;
public typealias RequestFailureHandler = (request: JObject, exception: NSError) -> Void;

public protocol Transport
{
    func setDefaultHandlers(responseHandler: ResponseHandler, requestFailureHandler: RequestFailureHandler)
    
    func sendMessage(sessionId: String?, requestObject: JObject, responseHandler: ResponseHandler?, requestFailureHandler: RequestFailureHandler?)
    
    func getAppDefinition(onDefinition: (JObject?) -> Void)
}

public class TransportBase
{
    var _responseHandler: ResponseHandler?;
    var _requestFailureHandler: RequestFailureHandler?;
    
    init()
    {
    }
    
    public class var SessionIdHeader: String { get { return "synchro-api-session-id"; } }
    
    public func setDefaultHandlers(responseHandler: ResponseHandler, requestFailureHandler: RequestFailureHandler)
    {
        _responseHandler = responseHandler;
        _requestFailureHandler = requestFailureHandler;
    }

    func getAppDefinition(transport: Transport, onDefinition: (JObject?) -> Void)
    {
        var requestObject = JObject(
        [
            "Mode": JValue("AppDefinition"),
            "TransactionId": JValue(0)
        ]);
            
        transport.sendMessage(
            nil,
            requestObject: requestObject,
            responseHandler:
            { (responseAsJSON) in
                onDefinition(responseAsJSON["App"] as? JObject);
            },
            requestFailureHandler:
            { (request, error) in
                // !!! Fail
                onDefinition(nil);
            }
        );
    }
}
