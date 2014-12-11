//
//  UtilTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/10/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class UtilTests: XCTestCase
{
    func testUtil()
    {
        var theFormat = "Value %1$@ - str: %2$@";
        
        var theArgs = [CVarArgType]();
        theArgs.append("foo");
        theArgs.append("bar\u{20ac}");
        
        var result = NSString(format: theFormat, arguments: getVaList(theArgs)) as String;

        println(result)
    }
}