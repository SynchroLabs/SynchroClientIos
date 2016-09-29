//
//  TransportHttp.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("TransportHttp");

private var _schemeRegex = Regex("^https?://.*");

open class TransportHttp : TransportBase, Transport
{
    var _uri: URL;
    
    public init(uri: URL)
    {
        _uri = uri;
        super.init();
    }
    
    open class func uriFromHostString(_ host: String, scheme: String = "http") -> URL?
    {
        var uri = host;
        if (!_schemeRegex.isMatch(host))
        {
            uri = scheme + "://" + host;
        }
        
        return URL(string: uri);
    }
    
    fileprivate func isSuccessStatusCode(_ response: HTTPURLResponse) -> Bool
    {
        // This is what EnsureSuccessStatusCode does on .NET (for better or worse)
        //
        return response.statusCode >= 200 && response.statusCode < 300;
    }
    
    open func sendMessage(_ sessionId: String?, requestObject: JObject, responseHandler: ResponseHandler?, requestFailureHandler: RequestFailureHandler?)
    {
        let theResponseHandler = (responseHandler ?? _responseHandler);
        let theRequestFailureHandler = (requestFailureHandler ?? _requestFailureHandler);

        let request = NSMutableURLRequest(url: _uri);
        let session = URLSession.shared;
        request.httpMethod = "POST"
        request.httpBody = requestObject.toJson().data(using: String.Encoding.utf8);

        logger.debug("Request: \(requestObject.toJson())");
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type");
        if sessionId != nil
        {
            request.addValue(sessionId!, forHTTPHeaderField: TransportBase.SessionIdHeader);
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
            // completionHandler: (NSData!, NSUrlResponse!, NSError!)
            logger.debug("Response: \(response)");
            
            if let err = error
            {
                if let failureHandler = theRequestFailureHandler
                {
                    DispatchQueue.main.async(execute: {
                        failureHandler(requestObject, err as NSError);
                    });
                }
            }
            else if !self.isSuccessStatusCode(response as! HTTPURLResponse)
            {
                // We consider non-2XX to be an error, even though from the HTTP standpoint they're really just
                // fine.  So we create our own NSError and call the failure handler (if any) in this case.
                //
                let httpResponse = response as! HTTPURLResponse;
                let nonSuccessError = NSError(domain: NSURLErrorDomain, code: httpResponse.statusCode, userInfo: httpResponse.allHeaderFields);

                if let failureHandler = theRequestFailureHandler
                {
                    DispatchQueue.main.async(execute: {
                        failureHandler(requestObject, nonSuccessError);
                    });
                }
            }
            else
            {
                var strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                if strData == nil
                {
                    // In the event that the UTF8 decode fails, we'll go ahead and let the string encoder try to find an
                    // encoding that it likes.  It has been observed in the wild that sometimes that UTF8 decode fails
                    // when it shouldn't, and the code below correctly decodes (as USASCII, which is a subset of the UF8
                    // that it failed on above - go figure).
                    //
                    let encoding = NSString.stringEncoding(for: data!, encodingOptions: nil, convertedString: &strData, usedLossyConversion: nil)
                    logger.error("Failed to decode response data as UTF-8, tried generic decode, which produced and encoding of: \(encoding)");
                }
                
                if let actualStrData = strData
                {
                    logger.debug("Body: \(actualStrData)");
                    
                    // !!! Need to handle failed JSON parsing and call failure handler with appropriate NSError
                    let responseObject = JObject.parse(actualStrData as String);
                    
                    if (theResponseHandler != nil)
                    {
                        DispatchQueue.main.async(execute: {
                            theResponseHandler!(responseObject as! JObject);
                        });
                    }
                }
            }
        })
        
        task.resume()
    }
    
    open func sendMessage(_ sessionId: String?, requestObject: JObject)
    {
        self.sendMessage(sessionId, requestObject: requestObject, responseHandler: nil, requestFailureHandler: nil);
    }
    
    open func getAppDefinition(_ onDefinition: @escaping (JObject?) -> Void )
    {
        return super.getAppDefinition(self, onDefinition: onDefinition);
    }
}
