//
//  TransportHttp.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("TransportHttp");

public class TransportHttp : TransportBase, Transport
{
    var _uri: NSURL;
    
    public init(uri: NSURL)
    {
        _uri = uri;
        super.init();
    }
    
    public class func uriFromHostString(host: String, scheme: String = "http") -> NSURL?
    {
        return NSURL(string: "\(scheme)://\(host)");
    }
    
    private func isSuccessStatusCode(response: NSHTTPURLResponse) -> Bool
    {
        // This is what EnsureSuccessStatusCode does on .NET (for better or worse)
        //
        return response.statusCode >= 200 && response.statusCode < 300;
    }
    
    public func sendMessage(sessionId: String?, requestObject: JObject, responseHandler: ResponseHandler?, requestFailureHandler: RequestFailureHandler?)
    {
        let theResponseHandler = (responseHandler ?? _responseHandler);
        let theRequestFailureHandler = (requestFailureHandler ?? _requestFailureHandler);

        var request = NSMutableURLRequest(URL: _uri);
        var session = NSURLSession.sharedSession();
        request.HTTPMethod = "POST"
        request.HTTPBody = requestObject.toJson().dataUsingEncoding(NSUTF8StringEncoding);

        logger.debug("Request: \(requestObject.toJson())");
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        if sessionId != nil
        {
            request.addValue(sessionId!, forHTTPHeaderField: TransportBase.SessionIdHeader);
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            // completionHandler: (NSData!, NSUrlResponse!, NSError!)
            logger.debug("Response: \(response)");
            
            if let err = error
            {
                if let failureHandler = theRequestFailureHandler
                {
                    dispatch_async(dispatch_get_main_queue(),
                    {
                        failureHandler(request: requestObject, exception: error);
                    });
                }
            }
            else if !self.isSuccessStatusCode(response as NSHTTPURLResponse)
            {
                // We consider non-2XX to be an error, even though from the HTTP standpoint they're really just
                // fine.  So we create our own NSError and call the failure handler (if any) in this case.
                //
                var httpResponse = response as NSHTTPURLResponse;
                var nonSuccessError = NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: httpResponse.allHeaderFields);

                if let failureHandler = theRequestFailureHandler
                {
                    dispatch_async(dispatch_get_main_queue(),
                    {
                        failureHandler(request: requestObject, exception: nonSuccessError);
                    });
                }
            }
            else
            {
                var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
                if strData == nil
                {
                    // In the event that the UTF8 decode fails, we'll go ahead and let the string encoder try to find an
                    // encoding that it likes.  It has been observed in the wild that sometimes that UTF8 decode fails
                    // when it shouldn't, and the code below correctly decodes (as USASCII, which is a subset of the UF8
                    // that it failed on above - go figure).
                    //
                    // Asserting here so we can see if this happens again...
                    //
                    assert(false, "Failed to decode response date as UTF-8, release code will try harder");
                    
                    var convertedString: NSString?
                    let encoding = NSString.stringEncodingForData(data, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)
                }
                
                if let actualStrData = strData
                {
                    logger.debug("Body: \(actualStrData)");
                    
                    // !!! Need to handle failed JSON parsing and call failure handler with appropriate NSError
                    var responseObject = JObject.parse(actualStrData);
                    
                    if (theResponseHandler != nil)
                    {
                        dispatch_async(dispatch_get_main_queue(),
                        {
                            theResponseHandler!(response: responseObject as JObject);
                        });
                    }
                }
            }
        })
        
        task.resume()
    }
    
    public func sendMessage(sessionId: String?, requestObject: JObject)
    {
        self.sendMessage(sessionId, requestObject: requestObject, nil, nil);
    }
    
    public func getAppDefinition(onDefinition: (JObject?) -> Void )
    {
        return super.getAppDefinition(self, onDefinition);
    }
}
