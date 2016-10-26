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
    case none;
    case single;
    case multiple;
    
    var description : String
    {
        switch self
        {
            case .none:     return "None";
            case .single:   return "Single";
            case .multiple: return "Multiple";
        }
    }
}

public enum LocationStatus : Int
{
    case unknown = 0;
    case determiningAvailabily;
    case available;
    case notAvailable;
    case pendingApproval;
    case notApproved;
    case active;
    case failed;
    
    var description : String
    {
        switch self
        {
            case .unknown:               return "Unknown";
            case .determiningAvailabily: return "DeterminingAvailability";
            case .available:             return "Available";
            case .notAvailable:          return "NotAvailable";
            case .pendingApproval:       return "PendingApproval";
            case .notApproved:           return "NotApproved";
            case .active:                return "Active";
            case .failed:                return "Failed";
        }
    }
}

public enum FontFaceType
{
    case font_DEFAULT;
    case font_SERIF;
    case font_SANSERIF;
    case font_MONOSPACE;

    var description : String
    {
        switch self
        {
            case .font_DEFAULT:   return "FONT_DEFAULT";
            case .font_SERIF:     return "FONT_SERIF";
            case .font_SANSERIF:  return "FONT_SANSERIF";
            case .font_MONOSPACE: return "FONT_MONOSPACE";
            }
    }

}

public protocol FontSetter
{
    func setFaceType(_ faceType: FontFaceType);
    func setSize(_ size: Double);
    func setBold(_ bold: Bool);
    func setItalic(_ italic: Bool);
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


open class ControlWrapper: NSObject
{
    var _stateManager: StateManager;
    var _viewModel: ViewModel;
    var _bindingContext: BindingContext;
    var _styles: [String]?;
    
    var _commands = Dictionary<String, CommandInstance>();
    var _valueBindings = Dictionary<String, ValueBinding>();
    var _propertyBindings = [PropertyBinding]();
    var _childControls = [ControlWrapper]();
    
    var _isVisualElement = true;
    open var isVisualElement: Bool { get { return _isVisualElement; } }
    
    public init(stateManager: StateManager, viewModel: ViewModel, bindingContext: BindingContext)
    {
        _stateManager = stateManager;
        _viewModel = viewModel;
        _bindingContext = bindingContext;
        super.init();
    }
    
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec: JObject)
    {
        _stateManager = parent.stateManager;
        _viewModel = parent.viewModel;
        _bindingContext = bindingContext;
        
        if let styles = controlSpec["style"]
        {
            let separators = CharacterSet(charactersIn: " ,");
            _styles = styles.asString()!.components(separatedBy: separators).filter{!$0.isEmpty};
        }
        
        super.init();
    }
    
    open var stateManager: StateManager { get { return _stateManager; } }
    open var viewModel: ViewModel { get { return _viewModel; } }
    
    open var bindingContext: BindingContext { get { return _bindingContext; } }
    open var childControls: [ControlWrapper] { get { return _childControls; } }
    open func addChildControl(_ control: ControlWrapper)
    {
        _childControls.append(control);
    }
    open func clearChildControls()
    {
        _childControls.removeAll(keepingCapacity: false);
    }
    
    func setCommand(_ attribute: String, command: CommandInstance)
    {
        _commands[attribute] = command;
    }
    
    open func getCommand(_ commandName: CommandName) -> CommandInstance?
    {
        if (_commands.keys.contains(commandName.Attribute))
        {
            return _commands[commandName.Attribute];
        }
        return nil;
    }
    
    func setValueBinding(_ attribute: String, valueBinding: ValueBinding)
    {
        _valueBindings[attribute] = valueBinding;
    }
    
    open func getValueBinding(_ attribute: String) -> ValueBinding?
    {
        if (_valueBindings.keys.contains(attribute))
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
    open class func getRangeLimitedValue(_ value: Double, min: Double?, max: Double?) -> Double
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
    
    open class func getStarCount(_ starString: String?) -> Int
    {
        var starCnt = 0;
        if ((starString != nil) && (starString!.hasSuffix("*")))
        {
            starCnt = 1;
            let valueString = starString!.replacingOccurrences(of: "*", with: "", options: [], range: nil);
            if (valueString.length > 0)
            {
                starCnt = Int(valueString) ?? starCnt;
            }
        }
        
        return starCnt;
    }
    
    // Basic token conversions
    //
    
    open func toString(_ token: JToken?, defaultValue: String = "") -> String
    {
        return TokenConverter.toString(token, defaultValue: defaultValue);
    }
    
    open func toBoolean(_ token: JToken?, defaultValue: Bool = false) -> Bool
    {
        return TokenConverter.toBoolean(token, defaultValue: defaultValue);
    }
    
    // !!! TokenConverter returns an optional (which will be nil in the case that the value could not be
    //     coerced to a double.  This method should probably also return an optional, and everyone who calls
    //     it should be checking to make sure it was a number (unless they passed in a default value).
    //
    open func toDouble(_ value: JToken?, defaultValue: Double = 0) -> Double
    {
        return TokenConverter.toDouble(value, defaultValue: defaultValue) ?? defaultValue;
    }
    
    // Conversion functions to go from Maaas units or typographic points to device units
    //
    
    open func toDeviceUnits(_ value: Double) -> Double
    {
        return self.stateManager.deviceMetrics.SynchroUnitsToDeviceUnits(value);
    }
    
    open func toDeviceUnits(_ value: JToken) -> Double
    {
        return toDeviceUnits(toDouble(value));
    }
    
    open func toDeviceUnitsFromTypographicPoints(_ value: JToken) -> Double
    {
        return toDeviceUnits(self.stateManager.deviceMetrics.TypographicPointsToMaaasUnits(toDouble(value)));
    }
    
    open func toListSelectionMode(_ value: JToken?, defaultSelectionMode: ListSelectionMode = ListSelectionMode.single) -> ListSelectionMode
    {
        var selectionMode = defaultSelectionMode;
        let selectionModeValue = value?.asString();
        if (selectionModeValue == "None")
        {
            selectionMode = ListSelectionMode.none;
        }
        else if (selectionModeValue == "Single")
        {
            selectionMode = ListSelectionMode.single;
        }
        else if (selectionModeValue == "Multiple")
        {
            selectionMode = ListSelectionMode.multiple;
        }
        return selectionMode;
    }
    
    open class ColorARGB
    {
        var _a: UInt8;
        var _r: UInt8;
        var _g: UInt8;
        var _b: UInt8;
        
        public init(a: UInt8, r: UInt8, g: UInt8, b: UInt8)
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
        
        open var a: UInt8 { get { return _a; } }
        open var r: UInt8 { get { return _r; } }
        open var g: UInt8 { get { return _g; } }
        open var b: UInt8 { get { return _b; } }
    }
    
    open class func getColor(_ colorValue: String) -> ColorARGB?
    {
        var len = colorValue.characters.count;
        
        if (colorValue.hasPrefix("#"))
        {
            len -= 1;
            let hexColor = colorValue.substring(from: colorValue.characters.index(colorValue.startIndex, offsetBy: 1));
            var rgbValue:UInt32 = 0
            Scanner(string: hexColor).scanHexInt32(&rgbValue)
            
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
            if (colorNames.keys.contains(colorValue))
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
    
    open func processFontAttribute(_ controlSpec: JObject, fontSetter: FontSetter)
    {
        processElementProperty(controlSpec, attributeName: "font.face",
        setValue: { (value) in
            var faceType = FontFaceType.font_DEFAULT;
            let faceTypeString = value?.asString();
            if faceTypeString == "Serif"
            {
                faceType = FontFaceType.font_SERIF;
            }
            else if faceTypeString == "SanSerif"
            {
                faceType = FontFaceType.font_SANSERIF;
            }
            else if faceTypeString == "Monospace"
            {
                faceType = FontFaceType.font_MONOSPACE;
            }
            fontSetter.setFaceType(faceType);
        });
        
        // This will handle the simple style "fontsize" attribute (this is the most common font attribute and is
        // very often used by itself, so we'll support this alternate syntax).
        //
        processElementProperty(controlSpec, attributeName: "font.size", altAttributeName: "fontsize",
        setValue: { (value) in
            if let theValue = value
            {
                fontSetter.setSize(self.toDeviceUnitsFromTypographicPoints(theValue));
            }
        });
        
        processElementProperty(controlSpec, attributeName: "font.bold",
        setValue: { (value) in
            fontSetter.setBold(self.toBoolean(value));
        });
        
        processElementProperty(controlSpec, attributeName: "font.italic",
        setValue: { (value) in
            fontSetter.setItalic(self.toBoolean(value));
        });
    }
    
    // Process a value binding on an element.  If a value is supplied, a value binding to that binding context will be created.
    //
    @discardableResult
    func processElementBoundValue(_ attributeName: String, attributeValue: JToken?, getValue: @escaping GetViewValue, setValue: SetViewValue? = nil) -> Bool
    {
        if let value = attributeValue?.asString()
        {
            let valueBindingContext = self.bindingContext.select(value);
            let binding = viewModel.createAndRegisterValueBinding(valueBindingContext, getValue: getValue, setValue: setValue);
            setValueBinding(attributeName, valueBinding: binding);
            
            // Immediate content update during configuration.
            binding.updateViewFromViewModel();
            
            return true;
        }
        
        return false;
    }
    
    fileprivate func attemptStyleBinding(_ style: String, attributeName: String, setValue: SetViewValue?) -> JToken?
    {
        // See if [style].[attributeName] is defined, and if so, bind to it
        //
        let styleBinding = style + "." + attributeName;
        let styleBindingContext = _viewModel.rootBindingContext.select(styleBinding);
        let value = styleBindingContext.getValue();
        if ((value != nil) && (value?.TokenType != JTokenType.object))
        {
            let binding = viewModel.createAndRegisterPropertyBinding(_bindingContext, value: "{$root." + styleBinding + "}", setValue: setValue);
            if (setValue == nil)
            {
                viewModel.unregisterPropertyBinding(binding);
            }
            else
            {
                _propertyBindings.append(binding);
            }
            
            // Immediate content update during configuration
            return binding.updateViewFromViewModel();
        }
        
        return nil;
    }
    
    // Process an element property, which can contain a plain value, a property binding token string, or no value at all,
    // in which case one or more "style" attribute values will be used to attempt to find a binding of the attributeName
    // to a style value.  This call *may* result in a property binding to the element property, or it may not.
    //
    // This is "public" because there are cases when a parent element needs to process properties on its children after creation.
    //
    // The returned JToken (if any) represents the bound value as determined at the time of processing the element.  It may return 
    // nil in the case that there was no binding, or where there was a binding to an element in the view model that does not currently
    // exist.  
    //
    // This function can be used for cases where the element binding is required to be present at processing time (for config elements
    // that are required upon control creation, and that do not support value update during the control lifecycle).  In that case, a
    // nil value may be passed for setValue, which will avoid creating and managing bindings (which should not be necessary since there
    // is no setter), but will still return a resolved value if once can be determined.
    //
    @discardableResult
    open func processElementProperty(_ controlSpec: JObject, attributeName: String, altAttributeName: String?, setValue: SetViewValue?) -> JToken?
    {
        var value = controlSpec.selectToken(attributeName);
        if ((value == nil) && (altAttributeName != nil))
        {
            value = controlSpec.selectToken(altAttributeName!);
            if ((value != nil) && (value?.TokenType == JTokenType.object))
            {
                value = nil;
            }
        }
        
        if (value == nil)
        {
            if let styles = _styles
            {
                for style in styles
                {
                    var resolvedValue = attemptStyleBinding(style, attributeName: attributeName, setValue: setValue);
                    if (resolvedValue != nil)
                    {
                        return resolvedValue;
                    }
                    else if (altAttributeName != nil)
                    {
                        resolvedValue = attemptStyleBinding(style, attributeName: altAttributeName!, setValue: setValue);
                        if (resolvedValue != nil)
                        {
                            return resolvedValue;
                        }
                    }
                }
            }
        }
        else if ((value!.TokenType == JTokenType.string) && PropertyValue.containsBindingTokens(value!.asString()!))
        {
            // If value contains a binding, create a Binding and add it to metadata
            let binding = viewModel.createAndRegisterPropertyBinding(self.bindingContext, value: value!.asString()!, setValue: setValue);
            if (setValue == nil)
            {
                viewModel.unregisterPropertyBinding(binding);
            }
            else
            {
                _propertyBindings.append(binding);
            }
            
            // Immediate content update during configuration.
            return binding.updateViewFromViewModel();
        }
        else
        {
            // Otherwise, just set the property value
            if (setValue != nil)
            {
                setValue!(value!);
            }
            return value;
        }
        
        return nil;
    }
    
    @discardableResult
    open func processElementProperty(_ controlSpec: JObject, attributeName: String, setValue: SetViewValue?) -> JToken?
    {
        return processElementProperty(controlSpec, attributeName: attributeName, altAttributeName: nil, setValue: setValue);
    }
    
    // This helper is used by control update handlers.
    //
    func updateValueBindingForAttribute(_ attributeName: String)
    {
        let binding = getValueBinding(attributeName);
        if (binding != nil)
        {
            // Update the local ViewModel from the element/control
            binding!.updateViewModelFromView();
        }
    }
    
    // Process and record any commands in a binding spec
    //
    func processCommands(_ bindingSpec: JObject, commands: [String])
    {
        for command in commands
        {
            if let commandSpec = bindingSpec[command] as? JObject
            {
                // A command spec contains an attribute called "command".  All other attributes are considered parameters.
                //
                let commandInstance = CommandInstance(command: commandSpec["command"]!.asString()!);
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
    open func unregister()
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
    open func createControls(_ bindingContext: BindingContext, controlList: JArray, onCreateControl: (BindingContext, JObject) -> (Void))
    {
        for control in controlList
        {
            if let element = control as? JObject
            {
                var controlBindingContext = bindingContext;
                var controlCreated = false;
                
                if ((element["binding"] != nil) && (element["binding"]!.TokenType == JTokenType.object))
                {
                    logger.debug("Found binding object");
                    let bindingSpec = element["binding"] as! JObject;
                    if (bindingSpec["foreach"] != nil)
                    {
                        // First we create a BindingContext for the "foreach" path (a context to the elements to be iterated)
                        let bindingPath = bindingSpec["foreach"]!.asString()!;
                        logger.debug("Found 'foreach' binding with path: \(bindingPath)");
                        let forEachBindingContext = bindingContext.select(bindingPath);
                        
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
                        let bindingContexts = forEachBindingContext.selectEach(withPath);
                        for elementBindingContext in bindingContexts
                        {
                            logger.debug("foreach - creating control with binding context: \(elementBindingContext.BindingPath)");
                            onCreateControl(elementBindingContext, element);
                        }
                        controlCreated = true;
                    }
                    else if (bindingSpec["with"] != nil)
                    {
                        let withBindingPath = bindingSpec["with"]!.asString()!;
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

