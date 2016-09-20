//
//  Logger.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

// There are appropriate static public interfaces provided below to do logging configuration (default, and per class).
//
// To set the default log level given a "defaultLevel" from a configuration, you would do:
//
//     Logger.DefaultLogLevel = LogLevel.FromString(defaultLevel);
//
// To set a specific level for a class using a "className" and "classLevel" from a configuration, you would do:
//
//     Logger.GetLogger(className).Level = LogLevel.FromString(classLevel);
//

// We can't have static (class) vars in Swift, but we can apparently have private global statics and public static
// (class) getters, so we'll make do with that.
//
private var staticLogLevels =
[
    "Trace": LogLevel(name: "Trace", ordinal: 0),
    "Debug": LogLevel(name: "Debug", ordinal: 1),
    "Info":  LogLevel(name: "Info", ordinal: 2),
    "Warn":  LogLevel(name: "Warn", ordinal: 3),
    "Error": LogLevel(name: "Error", ordinal: 4),
    "Fatal": LogLevel(name: "Fatal", ordinal: 5),
    "Off":   LogLevel(name: "Off", ordinal: 6)
]

open class LogLevel
{
    fileprivate var _ordinal: Int;
    fileprivate var _name: String;
    
    fileprivate init(name: String, ordinal: Int)
    {
        self._name = name;
        self._ordinal = ordinal;
    }
    
    open var name: String
    {
        get { return _name; }
    }
    
    open var ordinal: Int
    {
        get { return _ordinal; }
    }
    
    open class var Trace: LogLevel { get { return staticLogLevels["Trace"]!; } }
    open class var Debug: LogLevel { get { return staticLogLevels["Debug"]!; } }
    open class var Info:  LogLevel { get { return staticLogLevels["Info"]!;  } }
    open class var Warn:  LogLevel { get { return staticLogLevels["Warn"]!;  } }
    open class var Error: LogLevel { get { return staticLogLevels["Error"]!; } }
    open class var Fatal: LogLevel { get { return staticLogLevels["Fatal"]!; } }
    open class var Off:   LogLevel { get { return staticLogLevels["Off"]!;   } }
    
    open class func fromString(_ levelName: String) -> LogLevel?
    {
        return staticLogLevels[levelName];
    }
}

// Again, no static/class vars...
//
private var _loggers = Dictionary<String, Logger>();
private var _defaultLogLevel = LogLevel.Info;

open class Logger
{
    // This is our static Logger "factory"
    //
    open class func getLogger(_ className: String) -> Logger
    {
        if let existingLogger = _loggers[className]
        {
            return existingLogger;
        }
        else
        {
            let logger = Logger(className: className);
            _loggers[className] = logger;
            return logger;
        }
    }
    
    open class var DefaultLogLevel: LogLevel { get { return _defaultLogLevel; } set(value) { _defaultLogLevel = value; } }
    
    // This is our Logger instance implementation
    //
    fileprivate var _className: String;
    fileprivate var _level: LogLevel? = nil;
    
    fileprivate init(className: String)
    {
        self._className = className;
    }
    
    open var level: LogLevel
    {
        get
        {
            if (self._level == nil)
            {
                return _defaultLogLevel;
            }
            return self._level!;
        }
        set(value)
        {
            self._level = value;
        }
    }
    
    open func log(_ level: LogLevel, format: String)
    {
        if (level.ordinal >= self.level.ordinal)
        {    
            let dateFormatter = DateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS";
            let dateStr = dateFormatter.string(from: Date())
            
            print("\(dateStr) [\(level.name)] \(_className) - \(format)");
        }
    }
    
    open func trace(_ format: String)
    {
        log(LogLevel.Trace, format: format);
    }
    
    open func debug(_ format: String)
    {
        log(LogLevel.Debug, format: format);
    }
    
    open func info(_ format: String)
    {
        log(LogLevel.Info, format: format);
    }
    
    open func warn(_ format: String)
    {
        log(LogLevel.Warn, format: format);
    }
    
    open func error(_ format: String)
    {
        log(LogLevel.Error, format: format);
    }
    
    open func fatal(_ format: String)
    {
        log(LogLevel.Fatal, format: format);
    }
}
