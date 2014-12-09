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
}