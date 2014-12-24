//
//  iOSControlWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSControlWrapper");

public enum HorizontalAlignment
{
    case Center;
    case Left;
    case Right
    case Stretch;
    
    var description : String
    {
        switch self
        {
            case .Center:  return "Center";
            case .Left:    return "Left";
            case .Right:   return "Right";
            case .Stretch: return "Stretch";
        }
    }
}

public enum VerticalAlignment
{
    case Center;
    case Top;
    case Bottom;
    case Stretch;
    
    var description : String
    {
        switch self
        {
            case .Center:  return "Center";
            case .Top:     return "Top";
            case .Bottom:  return "Bottom";
            case .Stretch: return "Stretch";
        }
    }
}

public enum Orientation
{
    case Horizontal;
    case Vertical;
    
    var description : String
    {
        switch self
        {
            case .Horizontal: return "Horizontal";
            case .Vertical:   return "Vertical";
        }
    }
}

public enum SizeSpec
{
    case WrapContent;
    case Explicit;
    case FillParent;
    
    
    var description : String
    {
        switch self
        {
            case .WrapContent: return "WrapContent";
            case .Explicit:    return "Explicit";
            case .FillParent:  return "FillParent";
        }
    }
}

public class FrameProperties
{
    public var widthSpec: SizeSpec = SizeSpec.WrapContent;
    public var heightSpec: SizeSpec = SizeSpec.WrapContent;
    
    public var starWidth: Int = 0;
    public var starHeight: Int = 0;
}

//
// Font stuff...
//

public enum FontSlope
{
    case Roman;    // Also Regular, Plain - standard upright font
    case Italic;   // Italic font
    case Oblique;  // Also Incline, Inclined - Slanted version of Roman glyphs
    case Cursive;  // Also Kursiv - Italic with cursive glyph connections
    
    var description : String
    {
        switch self
        {
            case .Roman:   return "Roman";
            case .Italic:  return "Italic";
            case .Oblique: return "Oblique";
            case .Cursive: return "Cursive";
        }
    }
}

public enum FontWidth
{
    case Normal;
    case Narrow;   // Compressed, Condensed, Narrow
    case Wide;     // Wide, Extended, Expanded
    
    var description : String
    {
        switch self
        {
            case .Normal: return "Normal";
            case .Narrow: return "Narrow";
            case .Wide:   return "Wide";
        }
    }
}

public enum FontWeight: UInt
{
    case ExtraLight = 100; // ExtraLight or UltraLight
    case Light      = 200; // Light or Thin
    case Book       = 300; // Book or Demi
    case Normal     = 400; // Normal or Regular
    case Medium     = 500; // Medium
    case Semibold   = 600; // Semibold, Demibold
    case Bold       = 700; // Bold
    case Black      = 800; // Black, ExtraBold or Heavy
    case ExtraBlack = 900; // ExtraBlack, Fat, Poster or UltraBlack
    
    var description : String
    {
        switch self
        {
            case .ExtraLight: return "ExtraLight";
            case .Light:      return "Light";
            case .Book:       return "Bool";
            case .Normal:     return "Normal";
            case .Medium:     return "Medium";
            case .Semibold:   return "Semibold";
            case .Bold:       return "Bold";
            case .Black:      return "Black";
            case .ExtraBlack: return "ExtraBlack";
        }
    }
}

private var _slope_italic = Regex("Italic");
private var _slope_oblique = Regex("Oblique|Incline");
private var _slope_cursive = Regex("Cursive|Kursiv");

private var _width_narrow = Regex("Compressed|Condensed|Narrow");
private var _width_wide = Regex("Wide|Extended|Expanded");

private var _weight_100 = Regex("ExtraLight|UltraLight");
private var _weight_200 = Regex("Light|Thin");
private var _weight_300 = Regex("Book|Demi");
private var _weight_400 = Regex("Normal|Regular");
private var _weight_500 = Regex("Medium");
private var _weight_600 = Regex("Semibold|Demibold");
private var _weight_700 = Regex("Bold");
private var _weight_800 = Regex("Black|ExtraBold|Heavy");
private var _weight_900 = Regex("ExtraBlack|Fat|Poster|UltraBlack");

public class FontMetrics
{
    var _faceName: String;
    
    var _slope = FontSlope.Roman;
    var _width = FontWidth.Normal;
    var _weight = FontWeight.Normal;
    
    // The function of this class is to parse the font properties (slope/weight/width) from the font names, as
    // that's really the only indication that iOS gives us about the font metrics.
    //
    public init(faceName: String)
    {
        _faceName = faceName;
    
        if (_slope_italic.isMatch(_faceName))
        {
            _slope = FontSlope.Italic;
        }
        else if (_slope_oblique.isMatch(_faceName))
        {
            _slope = FontSlope.Oblique;
        }
        else if (_slope_cursive.isMatch(_faceName))
        {
            _slope = FontSlope.Cursive;
        }
        
        if (_width_narrow.isMatch(_faceName))
        {
            _width = FontWidth.Narrow;
        }
        else if (_width_wide.isMatch(_faceName))
        {
            _width = FontWidth.Wide;
        }
        
        // The ordering below might look a little strange, but it is important.  We have to be careful not to match Light, Bold, Black,
        // or Demi in other stlyes (UltraLight, SemiBold, UltraBlack, etc), so we have to search for the longer terms first.
        //
        if (_weight_100.isMatch(_faceName))
        {
            _weight = FontWeight.ExtraLight;
        }
        else if (_weight_400.isMatch(_faceName))
        {
            _weight = FontWeight.Normal;
        }
        else if (_weight_500.isMatch(_faceName))
        {
            _weight = FontWeight.Medium;
        }
        else if (_weight_900.isMatch(_faceName))
        {
            _weight = FontWeight.ExtraBlack;
        }
        else if (_weight_800.isMatch(_faceName))
        {
            _weight = FontWeight.Black;
        }
        else if (_weight_600.isMatch(_faceName))
        {
            _weight = FontWeight.Semibold;
        }
        else if (_weight_700.isMatch(_faceName))
        {
            _weight = FontWeight.Bold;
        }
        else if (_weight_200.isMatch(_faceName))
        {
            _weight = FontWeight.Light;
        }
        else if (_weight_300.isMatch(_faceName))
        {
            _weight = FontWeight.Book;
        }
    }
    
    public var name: String { get { return _faceName; } }
    public var slope: FontSlope { get { return _slope; } }
    public var width: FontWidth { get { return _width; } }
    public var weight: FontWeight { get { return _weight; } }
    
    // The math here works more or less as follows.  For each of the three criteria, a value of 1.0 is
    // given for a perfect match, a value of 0.8 is given for a "close" match, and a value of 0.5 is given
    // for a poor (typically opposite) match.  For font weight a sliding scale is used, but it more or less
    // matches up to the fixed scale values in the other metrics.  The overall match quality returned is the
    // product of these values.  A perfect match is 1.0, and the worst possible match is 0.125.  Importantly,
    // a font that matches perfectly on two criteria, but opposite on the third, will score a 0.5, whereas a
    // font that is a close match (but not perfect) on all three criteria will score a 0.512 (it is considered
    // a better match).
    //
    public func matchQuality(slope: FontSlope, weight: FontWeight, width: FontWidth) -> Float
    {
        var matchQuality: Float = 1;
        
        if (slope != _slope)
        {
            if ((slope != FontSlope.Roman) && (_slope != FontSlope.Roman))
            {
                // Slopes aren't equal, but are both non-Roman, which is kind of close...
                matchQuality *= 0.8;
            }
            else
            {
                // Slopes differ (one is Roman, one is some kind of non-Roman)...
                matchQuality *= 0.5;
            }
        }
        
        if (width != _width)
        {
            if ((width == FontWidth.Normal) || (_width == FontWidth.Normal))
            {
                // Font widths are within one (either, but not both, are normal), which is kind of close...
                matchQuality *= 0.8;
            }
            else
            {
                // The widths are opposite...
                matchQuality *= 0.5;
            }
        }
        
        if (weight != _weight)
        {
            var weightDifference = Float(abs(weight.rawValue - _weight.rawValue));
            // Max weight difference is 800 - We want to scale match from 1.0 (exact match) to 0.5 (opposite, or 800 difference)
            matchQuality *= (1.0 - (weightDifference / 1600));
        }

        return matchQuality;
    }

    public func description() -> String
    {
        return "FontMetrics - Face: \(_faceName), Weight: \(_weight), Slope: \(_slope), Width: \(_width)";
    }
}

protocol FontFamily
{
    func createFont(bold: Bool, italic: Bool, size: CGFloat) -> UIFont?;
}

public class FontFamilyFromName : FontFamily
{
    var _familyName: String;
    
    var _plainFont: FontMetrics;
    var _boldFont: FontMetrics;
    var _italicFont: FontMetrics;
    var _boldItalicFont: FontMetrics;
    
    public init(familyName: String)
    {
        _familyName = familyName;
        var fonts = [FontMetrics]();
        var fontNames: Array = UIFont.fontNamesForFamilyName(_familyName);
        for (index, value : AnyObject) in enumerate(fontNames)
        {
            if let fontName = value as? String
            {
                fonts.append(FontMetrics(faceName: fontName));
            }
        }
        
        _plainFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.Roman, weight: FontWeight.Normal, width: FontWidth.Normal)!;
        _boldFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.Roman, weight: FontWeight.Bold, width: FontWidth.Normal)!;
        _italicFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.Italic, weight: FontWeight.Normal, width: FontWidth.Normal)!;
        _boldItalicFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.Italic, weight: FontWeight.Bold, width: FontWidth.Normal)!;
    }
    
    class func getBestMatch(fonts: [FontMetrics], slope: FontSlope, weight: FontWeight, width: FontWidth) -> FontMetrics?
    {
        var bestMatch: FontMetrics? = nil;
        var bestMatchScore: Float = -1;
        
        for fontMetrics in fonts
        {
            var matchScore = fontMetrics.matchQuality(slope, weight: weight, width: width);
            if (matchScore > bestMatchScore)
            {
                bestMatch = fontMetrics;
                bestMatchScore = matchScore;
            }
            
            if (matchScore == 1)
            {
                break;
            }
        }
        
        return bestMatch;
    }
    
    public func createFont(bold: Bool, italic: Bool, size: CGFloat) -> UIFont?
    {
        if (bold && italic)
        {
            return UIFont(name: _boldItalicFont.name, size: size);
        }
        else if (bold)
        {
            return UIFont(name: _boldFont.name, size: size);
        }
        else if (italic)
        {
            return UIFont(name: _italicFont.name, size: size);
        }
        else
        {
            return UIFont(name: _plainFont.name, size: size);
        }
    }
}

public class SystemFontFamily : FontFamily
{
    public init()
    {
    }
    
    public class func isSystemFont(font: UIFont) -> Bool
    {
        var currSize = font.pointSize;
        
        var systemFont = UIFont.systemFontOfSize(currSize);
        var systemBoldFont = UIFont.boldSystemFontOfSize(currSize);
        var systemItalicFont = UIFont.italicSystemFontOfSize(currSize);
        
        return ((font == systemFont) || (font == systemBoldFont) || (font == systemItalicFont));
    }
    
    public func createFont(bold: Bool, italic: Bool, size: CGFloat) -> UIFont?
    {
        if (bold && italic)
        {
            // Family for system fonts: ".Helvetica NeueUI"
            //
            //   SystemFont        ".HelveticaNeueUI"
            //   BoldSystemFont    ".HelveticaNeueUI-Bold"
            //   ItalicSystemFont  ".HelveticaNeueUI-Italic"
            //
            // There is no built-in way to get the system bold+italic font, and it cannot be enumerated from the system font family,
            // but it happens that you can create it explicitly if you know the name (which should generally be the same as the bold
            // name plus "Italic", but could be different if there was a different system font).
            //
            //   ".HelveticaNeueUI-BoldItalic" - Works
            //
            var boldFont = UIFont.boldSystemFontOfSize(size);
            var boldItalicFont = UIFont(name: boldFont.fontName + "Italic", size: size);
            if (boldItalicFont != nil)
            {
                return boldItalicFont;
            }
            else
            {
                // If we can't create the bold+italic, we'll just return the bold (best we can do)
                return boldFont;
            }
        }
        else if (bold)
        {
            return UIFont.boldSystemFontOfSize(size);
        }
        else if (italic)
        {
            return UIFont.italicSystemFontOfSize(size);
        }
        else
        {
            return UIFont.systemFontOfSize(size);
        }
    }
}

public class iOSFontSetter : FontSetter
{
    var _family: FontFamily? = nil;
    var _bold = false;
    var  _italic = false;
    var _size = CGFloat(17.0);
    
    public init(font: UIFont)
    {
        if (SystemFontFamily.isSystemFont(font))
        {
            _family = SystemFontFamily();
        }
        else
        {
            _family = FontFamilyFromName(familyName: font.familyName);
        }
        
        _size = font.pointSize;
    }
    
    public func setFont(font: UIFont)
    {
        // abstract
        assert(false, "Must override");
    }
    
    func createAndSetFont()
    {
        if (_family != nil)
        {
            if let font = _family!.createFont(_bold, italic: _italic, size: _size)
            {
                self.setFont(font);
            }
        }
    }
    
    public func setFaceType(faceType: FontFaceType)
    {
        // See this for list of iOS fonts by version: http://iosfonts.com/
        //
        // If the face type is set, then we will create a font family to use.  Otherwise, we'll fall back to
        // the family created in the constructor (based on the initial/existing font).
        //
        switch (faceType)
        {
            case FontFaceType.FONT_DEFAULT:
                _family = SystemFontFamily();
            case FontFaceType.FONT_SANSERIF:
                _family = FontFamilyFromName(familyName: "Helvetica Neue");
            case FontFaceType.FONT_SERIF:
                _family = FontFamilyFromName(familyName: "Times New Roman");
            case FontFaceType.FONT_MONOSPACE:
                _family = FontFamilyFromName(familyName: "Courier New");
        }
        
        self.createAndSetFont();
    }
    
    public func setSize(size: Double)
    {
        _size = CGFloat(size);
        self.createAndSetFont();
    }
    
    public func setBold(bold: Bool)
    {
        _bold = bold;
        self.createAndSetFont();
    }
    
    public func setItalic(italic: Bool)
    {
        _italic = italic;
        self.createAndSetFont();
    }
}

protocol ThicknessSetter
{
    func setThickness(thickness: Double);
    func setThicknessLeft(thickness: Double);
    func setThicknessTop(thickness: Double);
    func setThicknessRight(thickness: Double);
    func setThicknessBottom(thickness: Double);
}

public class MarginThicknessSetter : ThicknessSetter
{
    var _controlWrapper: iOSControlWrapper;

    public init(controlWrapper: iOSControlWrapper)
    {
        _controlWrapper = controlWrapper;
    }

    public func setThickness(thickness: Double)
    {
        self.setThicknessTop(thickness);
        self.setThicknessLeft(thickness);
        self.setThicknessBottom(thickness);
        self.setThicknessRight(thickness);
    }

    public func setThicknessLeft(thickness: Double)
    {
        _controlWrapper.marginLeft = thickness;
    }
    
    public func setThicknessTop(thickness: Double)
    {
        _controlWrapper.marginTop = thickness;
    }
    
    public func setThicknessRight(thickness: Double)
    {
        _controlWrapper.marginRight = thickness;
    }
    
    public func setThicknessBottom(thickness: Double)
    {
        _controlWrapper.marginBottom = thickness;
    }
}

public class iOSControlWrapper : ControlWrapper
{
    var _control: UIView?;
    public var control: UIView? { get { return _control; } }
    
    var _pageView: iOSPageView;
    public var pageView: iOSPageView { get { return _pageView; } }

    var _margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);

    public var frameProperties = FrameProperties();

    var _horizontalAlignment = HorizontalAlignment.Left;
    public var horizontalAlignment: HorizontalAlignment
    {
        get { return _horizontalAlignment; }
        set(value)
        {
            _horizontalAlignment = value;
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    var _verticalAlignment = VerticalAlignment.Top;
    public var verticalAlignment: VerticalAlignment
    {
        get { return _verticalAlignment; }
        set(value)
        {
            _verticalAlignment = value;
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    public var margin: UIEdgeInsets
    {
        get { return _margin; }
        set(value)
        {
            _margin = value;
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    public var marginLeft: Double
    {
        get { return Double(_margin.left); }
        set(value)
        {
            _margin.left = CGFloat(value);
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    public var marginTop: Double
    {
        get { return Double(_margin.top); }
        set(value)
        {
            _margin.top = CGFloat(value);
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    public var marginRight: Double
    {
        get { return Double(_margin.right); }
        set(value)
        {
            _margin.right = CGFloat(value);
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }
    
    public var marginBottom: Double
    {
        get { return Double(_margin.bottom); }
        set(value)
        {
            _margin.bottom = CGFloat(value);
            if (_control?.superview != nil)
            {
                _control!.superview!.setNeedsLayout();
            }
        }
    }

    public init(pageView: iOSPageView, stateManager: StateManager, viewModel: ViewModel, bindingContext: BindingContext, control: UIView)
    {
        _pageView = pageView;
        _control = control;
        super.init(stateManager: stateManager, viewModel: viewModel, bindingContext: bindingContext);
    }
    
    public init(parent: ControlWrapper, bindingContext: BindingContext, control: UIView? = nil)
    {
        _pageView = (parent as iOSControlWrapper).pageView;
        _control = control;
        super.init(parent: parent, bindingContext: bindingContext);
    }
    
    public func toOrientation(value: JToken?, defaultOrientation: Orientation = Orientation.Horizontal) -> Orientation
    {
        var orientation = defaultOrientation;
        var orientationValue = value?.asString();
        if (orientationValue == "Horizontal")
        {
            orientation = Orientation.Horizontal;
        }
        else if (orientationValue == "Vertical")
        {
            orientation = Orientation.Vertical;
        }
        return orientation;
    }
    
    public func toHorizontalAlignment(value: JToken?, defaultAlignment: HorizontalAlignment = HorizontalAlignment.Left) -> HorizontalAlignment
    {
        var alignment = defaultAlignment;
        var alignmentValue = value?.asString();
        if (alignmentValue == "Left")
        {
            alignment = HorizontalAlignment.Left;
        }
        if (alignmentValue == "Right")
        {
            alignment = HorizontalAlignment.Right;
        }
        else if (alignmentValue == "Center")
        {
            alignment = HorizontalAlignment.Center;
        }
        return alignment;
    }
    
    public func toVerticalAlignment(value: JToken?, defaultAlignment: VerticalAlignment = VerticalAlignment.Top) -> VerticalAlignment
    {
        var alignment = defaultAlignment;
        var alignmentValue = value?.asString();
        if (alignmentValue == "Top")
        {
            alignment = VerticalAlignment.Top;
        }
        if (alignmentValue == "Bottom")
        {
            alignment = VerticalAlignment.Bottom;
        }
        else if (alignmentValue == "Center")
        {
            alignment = VerticalAlignment.Center;
        }
        return alignment;
    }
    
    func toColor(value: JToken?) -> UIColor?
    {
        if let colorString = value?.asString()
        {
            if let color = ControlWrapper.getColor(colorString)
            {
                return UIColor(red: CGFloat(color.r)/255.0, green: CGFloat(color.g)/255.0, blue: CGFloat(color.b)/255.0, alpha: CGFloat(color.a)/255.0);
            }
        }
        return nil;
    }
        
    func processThicknessProperty(thicknessAttributeValue: JToken?, thicknessSetter: ThicknessSetter)
    {
        if let token = thicknessAttributeValue
        {
            if (token is JValue)
            {
                processElementProperty(token,
                { (value) in
                    if let theValue = value
                    {
                        thicknessSetter.setThickness(self.toDeviceUnits(theValue));
                    }
                });
            }
            else if (token is JObject)
            {
                var marginObject = token as JObject;
                
                processElementProperty(marginObject["left"],
                { (value) in
                    if let theValue = value
                    {
                        thicknessSetter.setThicknessLeft(self.toDeviceUnits(theValue));
                    }
                });
                processElementProperty(marginObject["top"],
                { (value) in
                    if let theValue = value
                    {
                        thicknessSetter.setThicknessTop(self.toDeviceUnits(theValue));
                    }
                });
                processElementProperty(marginObject["right"],
                { (value) in
                    if let theValue = value
                    {
                        thicknessSetter.setThicknessRight(self.toDeviceUnits(theValue));
                    }
                });
                processElementProperty(marginObject["bottom"],
                { (value) in
                    if let theValue = value
                    {
                        thicknessSetter.setThicknessBottom(self.toDeviceUnits(theValue));
                    }
                });
            }
        }
    }
    
    func applyFrameworkElementDefaults(element: UIView, applyMargins: Bool = true)
    {
        // !!! This could be a little more thourough ;)
        
        if (applyMargins)
        {
            self.marginLeft = toDeviceUnits(10);
            self.marginTop = toDeviceUnits(10);
            self.marginRight = toDeviceUnits(10);
            self.marginBottom = toDeviceUnits(10);
        }
    }
    
    func sizeThatFits(size: CGSize) -> CGSize
    {
        var sizeThatFits = CGSize(width: size.width, height: size.height); // Default to size given ("fill parent")

        if let control = _control
        {
            if ((self.frameProperties.heightSpec == SizeSpec.WrapContent) && (self.frameProperties.widthSpec == SizeSpec.WrapContent))
            {
                // If both dimensions are WrapContent, then we want to make the control as small as possible in both dimensions, without
                // respect to how big the client would like to make it.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: 0, height: 0)); // Compute height and width
            }
            else if (self.frameProperties.heightSpec == SizeSpec.WrapContent)
            {
                // If only the height is WrapContent, then we obey the current width and attempt to compute the height.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: control.frame.size.width, height: 0)); // Compute height
                sizeThatFits.width = control.frame.size.width; // Maintain width
            }
            else if (self.frameProperties.widthSpec == SizeSpec.WrapContent)
            {
                // If only the width is WrapContent, then we obey the current hiights and attempt to compute the width.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: 0, height: control.frame.size.height)); // Compute width
                sizeThatFits.height = control.frame.height; // Maintain height
            }
            else // No content wrapping in either dimension...
            {
                if (self.frameProperties.heightSpec != SizeSpec.FillParent)
                {
                    sizeThatFits.height = control.frame.height;
                }
                if (self.frameProperties.widthSpec != SizeSpec.FillParent)
                {
                    sizeThatFits.width = control.frame.width;
                }
            }
        }
        
        return sizeThatFits;
    }
    
    func sizeToFit()
    {
        if let control = _control
        {
            var size = self.sizeThatFits(CGSize(width: 0, height: 0));
            var frame = control.frame;
            frame.size = size;
            control.frame = frame;
        }
    }
    
    func processElementDimensions(controlSpec: JObject, defaultWidth: Double = 0, defaultHeight: Double = 0) -> FrameProperties
    {
        var defaultWidth = CGFloat(defaultWidth);
        var defaultHeight = CGFloat(defaultHeight);
        
        if let control = self.control
        {
            if (defaultWidth == 0)
            {
                defaultWidth = control.intrinsicContentSize().width;
                if (defaultWidth == -1)
                {
                    defaultWidth = 0;
                }
            }
            if (defaultHeight == 0)
            {
                defaultHeight = control.intrinsicContentSize().height;
                if (defaultHeight == -1)
                {
                    defaultHeight = 0;
                }
            }
        
            control.frame = CGRect(x: 0, y: 0, width: defaultWidth, height: defaultHeight);
            
            // Process star sizing...
            //
            var heightStarCount = ControlWrapper.getStarCount(controlSpec["height"]?.asString());
            if (heightStarCount > 0)
            {
                self.frameProperties.heightSpec = SizeSpec.FillParent;
                self.frameProperties.starHeight = heightStarCount;
            }
            else
            {
                if (controlSpec["height"] != nil)
                {
                    self.frameProperties.heightSpec = SizeSpec.Explicit;
                }
                processElementProperty(controlSpec["height"],
                { (value) in
                    if let theValue = value
                    {
                        var frame = control.frame;
                        var size = frame.size;
                        size.height = CGFloat(self.toDeviceUnits(theValue));
                        frame.size = size;
                        control.frame = frame;
                        if (control.superview != nil)
                        {
                            control.superview!.setNeedsLayout();
                        }
                        //this.SizeToFit();
                    }
                });
            }
            
            var widthStarCount = ControlWrapper.getStarCount(controlSpec["width"]?.asString());
            if (widthStarCount > 0)
            {
                self.frameProperties.widthSpec = SizeSpec.FillParent;
                self.frameProperties.starWidth = widthStarCount;
            }
            else
            {
                if (controlSpec["width"] != nil)
                {
                    self.frameProperties.widthSpec = SizeSpec.Explicit;
                }
                processElementProperty(controlSpec["width"],
                { (value) in
                    if let theValue = value
                    {
                        var frame = control.frame;
                        var size = frame.size;
                        size.width = CGFloat(self.toDeviceUnits(theValue));
                        frame.size = size;
                        control.frame = frame;
                        if (control.superview != nil)
                        {
                            control.superview!.setNeedsLayout();
                        }
                        //this.SizeToFit();
                    }
                });
            }
        }
        
        return self.frameProperties;
    }
    
    func processCommonFrameworkElementProperies(controlSpec: JObject)
    {
        logger.debug("Processing framework element properties");
    
        // !!! This could be a little more thourough ;)
        //
        // name, minHeight, minWidth, maxHeight, maxWidth -- when/if supported
        //
        
        processElementProperty(controlSpec["horizontalAlignment"], { (value) in self.horizontalAlignment = self.toHorizontalAlignment(value) });
        processElementProperty(controlSpec["verticalAlignment"], { (value) in self.verticalAlignment = self.toVerticalAlignment(value) });
        
        processElementProperty(controlSpec["opacity"], { (value) in self.control!.layer.opacity = Float(self.toDouble(value)) });
        
        processElementProperty(controlSpec["background"], { (value) in self.control!.backgroundColor = self.toColor(value) });
        processElementProperty(controlSpec["visibility"],
        { (value) in
            self.control!.hidden = !self.toBoolean(value);
            if (self.control?.superview != nil)
            {
                self.control!.superview!.setNeedsLayout();
            }
        });
        
        if let uiControl = self.control as? UIControl
        {
            processElementProperty(controlSpec["enabled"], { (value) in uiControl.enabled = self.toBoolean(value) });
        }
        else
        {
            processElementProperty(controlSpec["enabled"], { (value) in self.control!.userInteractionEnabled = self.toBoolean(value) });
        }
        
        processThicknessProperty(controlSpec["margin"], thicknessSetter: MarginThicknessSetter(controlWrapper: self));
    }
    
    public func getChildControlWrapper(control: UIView) -> iOSControlWrapper?
    {
        // Find the child control wrapper whose control matches the supplied value...
        for child in self.childControls
        {
            if let child = child as? iOSControlWrapper
            {
                if (child.control == control)
                {
                    return child;
                }
            }
        }
        
        return nil;
    }
    
    public class func wrapControl(pageView: iOSPageView, stateManager: StateManager, viewModel: ViewModel, bindingContext: BindingContext, control: UIView) -> iOSControlWrapper
    {
        return iOSControlWrapper(pageView: pageView, stateManager: stateManager, viewModel: viewModel, bindingContext: bindingContext, control: control);
    }
    
    public class func createControl(parent: ControlWrapper, bindingContext: BindingContext, controlSpec: JObject) -> iOSControlWrapper?
    {
        var controlWrapper: iOSControlWrapper?;
        
        if let controlName = controlSpec["control"]?.asString()
        {
            switch (controlName)
            {
                case "border":
                    controlWrapper = iOSBorderWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "button":
                    controlWrapper = iOSButtonWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "canvas":
                    controlWrapper = iOSCanvasWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "edit":
                    controlWrapper = iOSTextBoxWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "gridview":
                    controlWrapper = iOSGridViewWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "image":
                    controlWrapper = iOSImageWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "listbox":
                    controlWrapper = iOSListBoxWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "listview":
                    controlWrapper = iOSListViewWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "location":
                    controlWrapper = iOSLocationWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "navBar.button":
                    controlWrapper = iOSToolBarWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "navBar.toggle":
                    controlWrapper = iOSToolBarToggleWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "password":
                    controlWrapper = iOSTextBoxWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "picker":
                    controlWrapper = iOSPickerWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "progressbar":
                    controlWrapper = iOSProgressBarWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "progressring":
                    controlWrapper = iOSProgressRingWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "rectangle":
                    controlWrapper = iOSRectangleWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "scrollview":
                    controlWrapper = iOSScrollWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "slider":
                    controlWrapper = iOSSliderWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "stackpanel":
                    controlWrapper = iOSStackPanelWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "text":
                    controlWrapper = iOSTextBlockWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "toggle":
                    controlWrapper = iOSToggleSwitchWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "toolBar.button":
                    controlWrapper = iOSToolBarWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "toolBar.toggle":
                    controlWrapper = iOSToolBarToggleWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "webview":
                    controlWrapper = iOSWebViewWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                case "wrappanel":
                    controlWrapper = iOSWrapPanelWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
                default: ()
            }
        }
        
        if (controlWrapper != nil)
        {
            if (controlWrapper!.control != nil)
            {
                controlWrapper!.processCommonFrameworkElementProperies(controlSpec);
            }
            parent.addChildControl(controlWrapper!);
        }
        
        return controlWrapper;
    }
    
    public func createControls(#controlList: JArray, onCreateControl: ((JObject, iOSControlWrapper) -> (Void))? = nil)
    {
        super.createControls(self.bindingContext, controlList: controlList,
        { (controlContext, controlSpec) in
            var controlWrapper = iOSControlWrapper.createControl(self, bindingContext: controlContext, controlSpec: controlSpec);
            if (controlWrapper == nil)
            {
                let controlType = controlSpec["control"];
                logger.warn("WARNING: Unable to create control of type: \(controlType)");
            }
            else if (onCreateControl != nil)
            {
                if (controlWrapper!.isVisualElement)
                {
                    onCreateControl!(controlSpec, controlWrapper!);
                }
            }
        });
    }
}


