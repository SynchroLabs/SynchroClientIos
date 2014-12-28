//
//  ControlWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("ControlWrapper");

public enum ListSelectionMode : Int
{
    case None;
    case Single;
    case Multiple;
    
    var description : String
    {
        switch self
        {
            case .None:     return "None";
            case .Single:   return "Single";
            case .Multiple: return "Multiple";
        }
    }
}

public enum LocationStatus : Int
{
    case Unknown = 0;
    case DeterminingAvailabily;
    case Available;
    case NotAvailable;
    case PendingApproval;
    case NotApproved;
    case Active;
    case Failed;
    
    var description : String
    {
        switch self
        {
            case .Unknown:               return "Unknown";
            case .DeterminingAvailabily: return "DeterminingAvailability";
            case .Available:             return "Available";
            case .NotAvailable:          return "NotAvailable";
            case .PendingApproval:       return "PendingApproval";
            case .NotApproved:           return "NotApproved";
            case .Active:                return "Active";
            case .Failed:                return "Failed";
        }
    }
}

public enum FontFaceType
{
    case FONT_DEFAULT;
    case FONT_SERIF;
    case FONT_SANSERIF;
    case FONT_MONOSPACE;

    var description : String
    {
        switch self
        {
            case .FONT_DEFAULT:   return "FONT_DEFAULT";
            case .FONT_SERIF:     return "FONT_SERIF";
            case .FONT_SANSERIF:  return "FONT_SANSERIF";
            case .FONT_MONOSPACE: return "FONT_MONOSPACE";
            }
    }

}

protocol FontSetter
{
    func setFaceType(faceType: FontFaceType);
    func setSize(size: Double);
    func setBold(bold: Bool);
    func setItalic(italic: Bool);
}

// Silverlight colors
//
// http://msdn.microsoft.com/en-us/library/system.windows.media.colors(v=vs.110).aspx
//
private var colorNames: Dictionary<String, UInt32> =
[
    "AliceBlue": 0xFFF0F8FF,
    "AntiqueWhite": 0xFFFAEBD7,
    "Aqua": 0xFF00FFFF,
    "Aquamarine": 0xFF7FFFD4,
    "Azure": 0xFFF0FFFF,
    "Beige": 0xFFF5F5DC,
    "Bisque": 0xFFFFE4C4,
    "Black": 0xFF000000,
    "BlanchedAlmond": 0xFFFFEBCD,
    "Blue": 0xFF0000FF,
    "BlueViolet": 0xFF8A2BE2,
    "Brown": 0xFFA52A2A,
    "BurlyWood": 0xFFDEB887,
    "CadetBlue": 0xFF5F9EA0,
    "Chartreuse": 0xFF7FFF00,
    "Chocolate": 0xFFD2691E,
    "Coral": 0xFFFF7F50,
    "CornflowerBlue": 0xFF6495ED,
    "Cornsilk": 0xFFFFF8DC,
    "Crimson": 0xFFDC143C,
    "Cyan": 0xFF00FFFF,
    "DarkBlue": 0xFF00008B,
    "DarkCyan": 0xFF008B8B,
    "DarkGoldenrod": 0xFFB8860B,
    "DarkGray": 0xFFA9A9A9,
    "DarkGreen": 0xFF006400,
    "DarkKhaki": 0xFFBDB76B,
    "DarkMagenta": 0xFF8B008B,
    "DarkOliveGreen": 0xFF556B2F,
    "DarkOrange": 0xFFFF8C00,
    "DarkOrchid": 0xFF9932CC,
    "DarkRed": 0xFF8B0000,
    "DarkSalmon": 0xFFE9967A,
    "DarkSeaGreen": 0xFF8FBC8F,
    "DarkSlateBlue": 0xFF483D8B,
    "DarkSlateGray": 0xFF2F4F4F,
    "DarkTurquoise": 0xFF00CED1,
    "DarkViolet": 0xFF9400D3,
    "DeepPink": 0xFFFF1493,
    "DeepSkyBlue": 0xFF00BFFF,
    "DimGray": 0xFF696969,
    "DodgerBlue": 0xFF1E90FF,
    "Firebrick": 0xFFB22222,
    "FloralWhite": 0xFFFFFAF0,
    "ForestGreen": 0xFF228B22,
    "Fuchsia": 0xFFFF00FF,
    "Gainsboro": 0xFFDCDCDC,
    "GhostWhite": 0xFFF8F8FF,
    "Gold": 0xFFFFD700,
    "Goldenrod": 0xFFDAA520,
    "Gray": 0xFF808080,
    "Green": 0xFF008000,
    "GreenYellow": 0xFFADFF2F,
    "Honeydew": 0xFFF0FFF0,
    "HotPink": 0xFFFF69B4,
    "IndianRed": 0xFFCD5C5C,
    "Indigo": 0xFF4B0082,
    "Ivory": 0xFFFFFFF0,
    "Khaki": 0xFFF0E68C,
    "Lavender": 0xFFE6E6FA,
    "LavenderBlush": 0xFFFFF0F5,
    "LawnGreen": 0xFF7CFC00,
    "LemonChiffon": 0xFFFFFACD,
    "LightBlue": 0xFFADD8E6,
    "LightCoral": 0xFFF08080,
    "LightCyan": 0xFFE0FFFF,
    "LightGoldenrodYellow": 0xFFFAFAD2,
    "LightGray": 0xFFD3D3D3,
    "LightGreen": 0xFF90EE90,
    "LightPink": 0xFFFFB6C1,
    "LightSalmon": 0xFFFFA07A,
    "LightSeaGreen": 0xFF20B2AA,
    "LightSkyBlue": 0xFF87CEFA,
    "LightSlateGray": 0xFF778899,
    "LightSteelBlue": 0xFFB0C4DE,
    "LightYellow": 0xFFFFFFE0,
    "Lime": 0xFF00FF00,
    "LimeGreen": 0xFF32CD32,
    "Linen": 0xFFFAF0E6,
    "Magenta": 0xFFFF00FF,
    "Maroon": 0xFF800000,
    "MediumAquamarine": 0xFF66CDAA,
    "MediumBlue": 0xFF0000CD,
    "MediumOrchid": 0xFFBA55D3,
    "MediumPurple": 0xFF9370DB,
    "MediumSeaGreen": 0xFF3CB371,
    "MediumSlateBlue": 0xFF7B68EE,
    "MediumSpringGreen": 0xFF00FA9A,
    "MediumTurquoise": 0xFF48D1CC,
    "MediumVioletRed": 0xFFC71585,
    "MidnightBlue": 0xFF191970,
    "MintCream": 0xFFF5FFFA,
    "MistyRose": 0xFFFFE4E1,
    "Moccasin": 0xFFFFE4B5,
    "NavajoWhite": 0xFFFFDEAD,
    "Navy": 0xFF000080,
    "OldLace": 0xFFFDF5E6,
    "Olive": 0xFF808000,
    "OliveDrab": 0xFF6B8E23,
    "Orange": 0xFFFFA500,
    "OrangeRed": 0xFFFF4500,
    "Orchid": 0xFFDA70D6,
    "PaleGoldenrod": 0xFFEEE8AA,
    "PaleGreen": 0xFF98FB98,
    "PaleTurquoise": 0xFFAFEEEE,
    "PaleVioletRed": 0xFFDB7093,
    "PapayaWhip": 0xFFFFEFD5,
    "PeachPuff": 0xFFFFDAB9,
    "Peru": 0xFFCD853F,
    "Pink": 0xFFFFC0CB,
    "Plum": 0xFFDDA0DD,
    "PowderBlue": 0xFFB0E0E6,
    "Purple": 0xFF800080,
    "Red": 0xFFFF0000,
    "RosyBrown": 0xFFBC8F8F,
    "RoyalBlue": 0xFF4169E1,
    "SaddleBrown": 0xFF8B4513,
    "Salmon": 0xFFFA8072,
    "SandyBrown": 0xFFF4A460,
    "SeaGreen": 0xFF2E8B57,
    "SeaShell": 0xFFFFF5EE,
    "Sienna": 0xFFA0522D,
    "Silver": 0xFFC0C0C0,
    "SkyBlue": 0xFF87CEEB,
    "SlateBlue": 0xFF6A5ACD,
    "SlateGray": 0xFF708090,
    "Snow": 0xFFFFFAFA,
    "SpringGreen": 0xFF00FF7F,
    "SteelBlue": 0xFF4682B4,
    "Tan": 0xFFD2B48C,
    "Teal": 0xFF008080,
    "Thistle": 0xFFD8BFD8,
    "Tomato": 0xFFFF6347,
    "Transparent": 0x00FFFFFF,
    "Turquoise": 0xFF40E0D0,
    "Violet": 0xFFEE82EE,
    "Wheat": 0xFFF5DEB3,
    "White": 0xFFFFFFFF,
    "WhiteSmoke": 0xFFF5F5F5,
    "Yellow": 0xFFFFFF00,
    "YellowGreen": 0xFF9ACD32
];


public class ControlWrapper: NSObject
{
    var _stateManager: StateManager;
    var _viewModel: ViewModel;
    var _bindingContext: BindingContext;
    
    var _commands = Dictionary<String, CommandInstance>();
    var _valueBindings = Dictionary<String, ValueBinding>();
    var _propertyBindings = [PropertyBinding]();
    var _childControls = [ControlWrapper]();
    
    var _isVisualElement = true;
    public var isVisualElement: Bool { get { return _isVisualElement; } }
    
    public init(stateManager: StateManager, viewModel: ViewModel, bindingContext: BindingContext)
    {
        _stateManager = stateManager;
        _viewModel = viewModel;
        _bindingContext = bindingContext;
        super.init();
    }
    
    public init(parent: ControlWrapper, bindingContext: BindingContext)
    {
        _stateManager = parent.stateManager;
        _viewModel = parent.viewModel;
        _bindingContext = bindingContext;
        super.init();
    }
    
    public var stateManager: StateManager { get { return _stateManager; } }
    public var viewModel: ViewModel { get { return _viewModel; } }
    
    public var bindingContext: BindingContext { get { return _bindingContext; } }
    public var childControls: [ControlWrapper] { get { return _childControls; } }
    public func addChildControl(control: ControlWrapper)
    {
        _childControls.append(control);
    }
    public func clearChildControls()
    {
        _childControls.removeAll(keepCapacity: false);
    }
    
    func setCommand(attribute: String, command: CommandInstance)
    {
        _commands[attribute] = command;
    }
    
    public func getCommand(commandName: CommandName) -> CommandInstance?
    {
        if (contains(_commands.keys, commandName.Attribute))
        {
            return _commands[commandName.Attribute];
        }
        return nil;
    }
    
    func setValueBinding(attribute: String, valueBinding: ValueBinding)
    {
        _valueBindings[attribute] = valueBinding;
    }
    
    public func getValueBinding(attribute: String) -> ValueBinding?
    {
        if (contains(_valueBindings.keys, attribute))
        {
            return _valueBindings[attribute];
        }
        return nil;
    }
    
    // Given min and max range limiters, either of which may be undefined (double.NaN), and a target value,
    // determine the range-limited value.
    //
    // !!! Use this for min/max height/width, as needed...
    //
    public class func getRangeLimitedValue(value: Double, min: Double?, max: Double?) -> Double
    {
        var result = value;
    
        if let suppliedMin = min
        {
            if (suppliedMin > result)
            {
                // There is a min value and it's greater than the current value...
                result = suppliedMin;
            }
        }
    
    
        if let suppliedMax = max
        {
            if (suppliedMax < result)
            {
                // There is a max value, and it's less than the current value...
                result = suppliedMax;
            }
        }
    
        return result;
    }
    
    //
    // Value conversion helpers
    //
    
    public class func getStarCount(starString: String?) -> Int
    {
        var starCnt = 0;
        if ((starString != nil) && (starString!.hasSuffix("*")))
        {
            starCnt = 1;
            let valueString = starString!.stringByReplacingOccurrencesOfString("*", withString: "", options: nil, range: nil);
            if (valueString.length > 0)
            {
                starCnt = valueString.toInt() ?? starCnt;
            }
        }
        
        return starCnt;
    }
    
    // Basic token conversions
    //
    
    public func toString(token: JToken?, defaultValue: String = "") -> String
    {
        return TokenConverter.toString(token, defaultValue: defaultValue);
    }
    
    public func toBoolean(token: JToken?, defaultValue: Bool = false) -> Bool
    {
        return TokenConverter.toBoolean(token, defaultValue: defaultValue);
    }
    
    // !!! TokenConverter returns an optional (which will be nil in the case that the value could not be
    //     coerced to a double.  This method should probably also return an optional, and everyone who calls
    //     it should be checking to make sure it was a number (unless they passed in a default value).
    //
    public func toDouble(value: JToken?, defaultValue: Double = 0) -> Double
    {
        return TokenConverter.toDouble(value, defaultValue: defaultValue) ?? defaultValue;
    }
    
    // Conversion functions to go from Maaas units or typographic points to device units
    //
    
    public func toDeviceUnits(value: Double) -> Double
    {
        return self.stateManager.deviceMetrics.SynchroUnitsToDeviceUnits(value);
    }
    
    public func toDeviceUnits(value: JToken) -> Double
    {
        return toDeviceUnits(toDouble(value));
    }
    
    public func toDeviceUnitsFromTypographicPoints(value: JToken) -> Double
    {
        return toDeviceUnits(self.stateManager.deviceMetrics.TypographicPointsToMaaasUnits(toDouble(value)));
    }
    
    public func toListSelectionMode(value: JToken?, defaultSelectionMode: ListSelectionMode = ListSelectionMode.Single) -> ListSelectionMode
    {
        var selectionMode = defaultSelectionMode;
        var selectionModeValue = value?.asString();
        if (selectionModeValue == "None")
        {
            selectionMode = ListSelectionMode.None;
        }
        else if (selectionModeValue == "Single")
        {
            selectionMode = ListSelectionMode.Single;
        }
        else if (selectionModeValue == "Multiple")
        {
            selectionMode = ListSelectionMode.Multiple;
        }
        return selectionMode;
    }
    
    public class ColorARGB
    {
        var _a: Byte;
        var _r: Byte;
        var _g: Byte;
        var _b: Byte;
        
        public init(a: Byte, r: Byte, g: Byte, b: Byte)
        {
            _a = a;
            _r = r;
            _g = g;
            _b = b;
        }
        
        public init(color: UInt32)
        {
            var bytes = color.getBytes();
            _a = bytes[0];
            _r = bytes[1];
            _g = bytes[2];
            _b = bytes[3];
        }
        
        public var a: Byte { get { return _a; } }
        public var r: Byte { get { return _r; } }
        public var g: Byte { get { return _g; } }
        public var b: Byte { get { return _b; } }
    }
    
    public class func getColor(colorValue: String) -> ColorARGB?
    {
        var len = countElements(colorValue);
        
        if (colorValue.hasPrefix("#"))
        {
            len--;
            var hexColor = colorValue.substringFromIndex(advance(colorValue.startIndex, 1));
            var rgbValue:UInt32 = 0
            NSScanner(string: hexColor).scanHexInt(&rgbValue)
            
            var bytes = rgbValue.getBytes();
            let alpha = bytes[0];
            let red = bytes[1];
            let green = bytes[2];
            let blue = bytes[3];

            if len == 6
            {
                return ColorARGB(a: 255, r: red, g: green, b: blue);
            }
            else if len == 8
            {
                return ColorARGB(a: alpha, r: red, g: green, b: blue);
            }
            else
            {
                logger.debug("Incorrect length for hex color specification - must be 6 (RRGGBB) or 8 (AARRGGBB) hex digits, was \(len) digits");
            }
        }
        else if (len > 0)
        {
            if (contains(colorNames.keys, colorValue))
            {
                return ColorARGB(color: colorNames[colorValue]!);
            }
            else
            {
                logger.debug("Color name '\(colorValue)' was not found, please choose a color name from the Microsoft SilverLight color set");
            }
        }
        
        // !!! Should we do something other than return null for an empty/bad color name/spec?
        return nil;
    }
    
    func processFontAttribute(controlSpec: JObject, fontSetter: FontSetter)
    {
        var fontAttributeValue = controlSpec["font"];
        if (fontAttributeValue is JObject)
        {
            if let fontObject = fontAttributeValue as? JObject
            {
                processElementProperty(fontObject["face"],
                { (value) in
                    var faceType = FontFaceType.FONT_DEFAULT;
                    var faceTypeString = value?.asString();
                    if faceTypeString == "Serif"
                    {
                        faceType = FontFaceType.FONT_SERIF;
                    }
                    else if faceTypeString == "SanSerif"
                    {
                        faceType = FontFaceType.FONT_SANSERIF;
                    }
                    else if faceTypeString == "Monospace"
                    {
                        faceType = FontFaceType.FONT_MONOSPACE;
                    }
                    fontSetter.setFaceType(faceType);
                });
                
                processElementProperty(fontObject["size"],
                { (value) in
                    if let theValue = value
                    {
                        fontSetter.setSize(self.toDeviceUnitsFromTypographicPoints(theValue));
                    }
                });
                
                processElementProperty(fontObject["bold"],
                { (value) in
                    fontSetter.setBold(self.toBoolean(value));
                });
                
                processElementProperty(fontObject["italic"],
                { (value) in
                    fontSetter.setItalic(self.toBoolean(value));
                });
            }
        }
        
        // This will handle the simple style "fontsize" attribute (this is the most common font attribute and is
        // very often used by itself, so we'll support this alternate syntax).
        //
        processElementProperty(controlSpec["fontsize"],
        { (value) in
            if let theValue = value
            {
                fontSetter.setSize(self.toDeviceUnitsFromTypographicPoints(theValue));
            }
        });
    }
    
    // Process a value binding on an element.  If a value is supplied, a value binding to that binding context will be created.
    //
    func processElementBoundValue(attributeName: String, attributeValue: JToken?, getValue: GetViewValue, setValue: SetViewValue? = nil) -> Bool
    {
        if let value = attributeValue?.asString()
        {
            var valueBindingContext = self.bindingContext.select(value);
            var binding = viewModel.createAndRegisterValueBinding(valueBindingContext, getValue, setValue);
            setValueBinding(attributeName, valueBinding: binding);
            
            // Immediate content update during configuration.
            binding.updateViewFromViewModel();
            
            return true;
        }
        
        return false;
    }
    
    // Process an element property, which can contain a plain value, a property binding token string, or no value at all,
    // in which case any optionally supplied defaultValue will be used.  This call *may* result in a property binding to
    // the element property, or it may not.
    //
    // This is "public" because there are cases when a parent element needs to process properties on its children after creation.
    //
    public func processElementProperty(value: JToken?, setValue: SetViewValue)
    {
        if let token = value
        {
            if ((token.Type == JTokenType.String) && PropertyValue.containsBindingTokens(token.asString()!))
            {
                // If value contains a binding, create a Binding and add it to metadata
                var binding = viewModel.createAndRegisterPropertyBinding(self.bindingContext, value: token.asString()!, setValue);
                _propertyBindings.append(binding);
                
                // Immediate content update during configuration.
                binding.updateViewFromViewModel();
            }
            else
            {
                // Otherwise, just set the property value
                setValue(token);
            }
        }
    }
    
    // This helper is used by control update handlers.
    //
    func updateValueBindingForAttribute(attributeName: String)
    {
        var binding = getValueBinding(attributeName);
        if (binding != nil)
        {
            // Update the local ViewModel from the element/control
            binding!.updateViewModelFromView();
        }
    }
    
    // Process and record any commands in a binding spec
    //
    func processCommands(bindingSpec: JObject, commands: [String])
    {
        for command in commands
        {
            if let commandSpec = bindingSpec[command] as? JObject
            {
                // A command spec contains an attribute called "command".  All other attributes are considered parameters.
                //
                var commandInstance = CommandInstance(command: commandSpec["command"]!.asString()!);
                for propertyKey in commandSpec
                {
                    if (propertyKey != "command")
                    {
                        commandInstance.setParameter(propertyKey, parameterValue: commandSpec[propertyKey]!);
                    }
                }
                setCommand(command, command: commandInstance);
            }
        }
    }
    
    // When we remove a control, we need to unbind it and its descendants (by unregistering all bindings
    // from the view model).  This is important as often times a control is removed when the underlying
    // bound values go away, such as when an array element is removed, causing a cooresponding (bound) list
    // or list view item to be removed.
    //
    public func unregister()
    {
        for valueBinding in _valueBindings.values
        {
            _viewModel.unregisterValueBinding(valueBinding);
        }
        
        for propertyBinding in _propertyBindings
        {
            _viewModel.unregisterPropertyBinding(propertyBinding);
        }
        
        for childControl in _childControls
        {
            childControl.unregister();
        }
    }
    
    // This will create controls from a list of control specifications.  It will apply any "foreach" and "with" bindings
    // as part of the process.  It will call the supplied callback to actually create the individual controls.
    //
    public func createControls(bindingContext: BindingContext, controlList: JArray, onCreateControl: (BindingContext, JObject) -> (Void))
    {
        for control in controlList
        {
            if let element = control as? JObject
            {
                var controlBindingContext = bindingContext;
                var controlCreated = false;
                
                if ((element["binding"] != nil) && (element["binding"]!.Type == JTokenType.Object))
                {
                    logger.debug("Found binding object");
                    var bindingSpec = element["binding"] as JObject;
                    if (bindingSpec["foreach"] != nil)
                    {
                        // First we create a BindingContext for the "foreach" path (a context to the elements to be iterated)
                        var bindingPath = bindingSpec["foreach"]!.asString()!;
                        logger.debug("Found 'foreach' binding with path: \(bindingPath)");
                        var forEachBindingContext = bindingContext.select(bindingPath);
                        
                        // Then we determine the bindingPath to use on each element
                        var withPath = "$data";
                        if (bindingSpec["with"] != nil)
                        {
                            // It is possible to use "foreach" and "with" together - in which case "foreach" is applied first
                            // and "with" is applied to each element in the foreach array.  This allows for path navigation
                            // both up to, and then after, the context to be iterated.
                            //
                            withPath = bindingSpec["with"]!.asString()!;
                        }
                        
                        // Then we get each element at the foreach binding, apply the element path, and create the controls
                        var bindingContexts = forEachBindingContext.selectEach(withPath);
                        for elementBindingContext in bindingContexts
                        {
                            logger.debug("foreach - creating control with binding context: \(elementBindingContext.BindingPath)");
                            onCreateControl(elementBindingContext, element);
                        }
                        controlCreated = true;
                    }
                    else if (bindingSpec["with"] != nil)
                    {
                        var withBindingPath = bindingSpec["with"]!.asString()!;
                        logger.debug("Found 'with' binding with path: \(withBindingPath)");
                        controlBindingContext = bindingContext.select(withBindingPath);
                    }
                }
                
                if (!controlCreated)
                {
                    onCreateControl(controlBindingContext, element);
                }
            }
        }
    }
}

