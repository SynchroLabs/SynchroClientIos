//
//  Transport.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

public typealias ResponseHandler = (_ response: JObject) -> Void;
public typealias RequestFailureHandler = (_ request: JObject, _ exception: NSError) -> Void;

public protocol Transport
{
    func setDefaultHandlers(_ responseHandler: @escaping ResponseHandler, requestFailureHandler: @escaping RequestFailureHandler)
    
    func sendMessage(_ sessionId: String?, requestObject: JObject)
    func sendMessage(_ sessionId: String?, requestObject: JObject, responseHandler: ResponseHandler?, requestFailureHandler: RequestFailureHandler?)
    
    func getAppDefinition(_ onDefinition: @escaping (JObject?) -> Void)
}

open class TransportBase
{
    var _responseHandler: ResponseHandler?;
    var _requestFailureHandler: RequestFailureHandler?;
    
    init()
    {
    }
    
    open class var SessionIdHeader: String { get { return "synchro-api-session-id"; } }
    
    open func setDefaultHandlers(_ responseHandler: @escaping ResponseHandler, requestFailureHandler: @escaping RequestFailureHandler)
    {
        _responseHandler = responseHandler;
        _requestFailureHandler = requestFailureHandler;
    }

    func getAppDefinition(_ transport: Transport, onDefinition: @escaping (JObject?) -> Void)
    {
        let requestObject = JObject(
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
