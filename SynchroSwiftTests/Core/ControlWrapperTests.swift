//
//  ControlWrapperTests.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

import UIKit
import XCTest

import SynchroSwift

class ControlWrapperTests: XCTestCase
{
    func testGetColorByName()
    {
        let color = ControlWrapper.getColor("NavajoWhite")!;
        XCTAssert(0xFF == color.a);
        XCTAssert(0xFF == color.r);
        XCTAssert(0xDE == color.g);
        XCTAssert(0xAD == color.b);
    }
    
    func testGetColorByRRGGBB()
    {
        let color = ControlWrapper.getColor("#FFDEAD")!;
        XCTAssert(0xFF == color.a);
        XCTAssert(0xFF == color.r);
        XCTAssert(0xDE == color.g);
        XCTAssert(0xAD == color.b);
    }

    func testGetColorByAARRGGBB()
    {
        let color = ControlWrapper.getColor("#80FFDEAD")!;
        XCTAssert(0x80 == color.a);
        XCTAssert(0xFF == color.r);
        XCTAssert(0xDE == color.g);
        XCTAssert(0xAD == color.b);
    }

    func testStarWithStarOnly()
    {
        var stars = ControlWrapper.getStarCount("*");
        XCTAssertEqual(1, stars);
    }

    func testStarWithNumStar()
    {
        var stars = ControlWrapper.getStarCount("69*");
        XCTAssertEqual(69, stars);
    }

    func testStarWithNum()
    {
        var stars = ControlWrapper.getStarCount("69");
        XCTAssertEqual(0, stars);
    }

    func testStarWithEmpty()
    {
        var stars = ControlWrapper.getStarCount("");
        XCTAssertEqual(0, stars);
    }
    
    func testStarWithNil()
    {
        var stars = ControlWrapper.getStarCount(nil);
        XCTAssertEqual(0, stars);
    }    
}
