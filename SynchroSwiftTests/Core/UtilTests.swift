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
        let theFormat = "Value %1$@ - str: %2$@";
        
        var theArgs = [CVarArg]();
        theArgs.append("foo");
        theArgs.append("bar\u{20ac}");
        
        let result = NSString(format: theFormat, arguments: getVaList(theArgs)) as String;

        print(result)
    }
    
    func testRegexIsMatch()
    {
        let slope_italic = Regex("Italic");
        let slope_oblique = Regex("Oblique|Incline");
        let slope_cursive = Regex("Cursive|Kursiv");

        XCTAssertTrue(slope_italic.isMatch("CourierBoldItalic"));
        XCTAssertFalse(slope_italic.isMatch("CourierNew"));
        XCTAssertTrue(slope_oblique.isMatch("InclineGaramond"));
        XCTAssertFalse(slope_oblique.isMatch("CourierNew"));
        XCTAssertTrue(slope_cursive.isMatch("FooCursiveBar"));
        XCTAssertFalse(slope_cursive.isMatch("CourierNew"));
    }
}
