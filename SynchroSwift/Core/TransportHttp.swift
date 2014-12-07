//
//  TransportHttp.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

public class TransportHttp : TransportBase, Transport
{
    var _uri: NSURL;
    
    public init(uri: NSURL)
    {
        _uri = uri;
        super.init();
    }
    
    public func sendMessage(sessionId: String?, requestObject: JObject, responseHandler: ResponseHandler?, requestFailureHandler: RequestFailureHandler?)
    {
        let theResponseHandler = (responseHandler ?? _responseHandler);
        let theRequestFailureHandler = (requestFailureHandler ?? _requestFailureHandler);

        var request = NSMutableURLRequest(URL: _uri);
        var session = NSURLSession.sharedSession();
        request.HTTPMethod = "POST"
        request.HTTPBody = requestObject.toJson().dataUsingEncoding(NSUTF8StringEncoding);

        println("Request: \(requestObject.toJson())");
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        if sessionId != nil
        {
            request.addValue(sessionId!, forHTTPHeaderField: TransportBase.SessionIdHeader);
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            // completionHandler: (NSData!, NSUrlResponse!, NSError!)
            println("Response: \(response)")
            
            // !!! Need some error/failure handling here...
            
            if let strData = NSString(data: data, encoding: NSUTF8StringEncoding)
            {
                println("Body: \(strData)")
                var responseObject = JObject.parse(strData);
                
                if (theResponseHandler != nil)
                {
                    theResponseHandler!(response: responseObject as JObject);
                }
            }
        })
        
        task.resume()
    }
    
    public func getAppDefinition(onDefinition: (JObject?) -> Void )
    {
        return super.getAppDefinition(self, onDefinition);
    }
}
