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

public class LogLevel
{
    private var _ordinal: Int;
    private var _name: String;
    
    private init(name: String, ordinal: Int)
    {
        self._name = name;
        self._ordinal = ordinal;
    }
    
    public var name: String
    {
        get { return _name; }
    }
    
    public var ordinal: Int
    {
        get { return _ordinal; }
    }
    
    public class var Trace: LogLevel { get { return staticLogLevels["Trace"]!; } }
    public class var Debug: LogLevel { get { return staticLogLevels["Debug"]!; } }
    public class var Info:  LogLevel { get { return staticLogLevels["Info"]!;  } }
    public class var Warn:  LogLevel { get { return staticLogLevels["Warn"]!;  } }
    public class var Error: LogLevel { get { return staticLogLevels["Error"]!; } }
    public class var Fatal: LogLevel { get { return staticLogLevels["Fatal"]!; } }
    public class var Off:   LogLevel { get { return staticLogLevels["Off"]!;   } }
    
    public class func fromString(levelName: String) -> LogLevel?
    {
        return staticLogLevels[levelName];
    }
}

// Again, no static/class vars...
//
private var _loggers = Dictionary<String, Logger>();
private var _defaultLogLevel = LogLevel.Info;

public class Logger
{
    // This is our static Logger "factory"
    //
    public class func getLogger(className: String) -> Logger
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
    
    public class var DefaultLogLevel: LogLevel { get { return _defaultLogLevel; } set(value) { _defaultLogLevel = value; } }
    
    // This is our Logger instance implementation
    //
    private var _className: String;
    private var _level: LogLevel? = nil;
    
    private init(className: String)
    {
        self._className = className;
    }
    
    public var level: LogLevel
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
    
    public func log(level: LogLevel, format: String)
    {
        if (level.ordinal >= self.level.ordinal)
        {    
            let dateFormatter = NSDateFormatter();
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS";
            let dateStr = dateFormatter.stringFromDate(NSDate())
            
            print("\(dateStr) [\(level.name)] \(_className) - \(format)");
        }
    }
    
    public func trace(format: String)
    {
        log(LogLevel.Trace, format: format);
    }
    
    public func debug(format: String)
    {
        log(LogLevel.Debug, format: format);
    }
    
    public func info(format: String)
    {
        log(LogLevel.Info, format: format);
    }
    
    public func warn(format: String)
    {
        log(LogLevel.Warn, format: format);
    }
    
    public func error(format: String)
    {
        log(LogLevel.Error, format: format);
    }
    
    public func fatal(format: String)
    {
        log(LogLevel.Fatal, format: format);
    }
}
