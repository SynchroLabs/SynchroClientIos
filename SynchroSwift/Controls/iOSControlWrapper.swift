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
    case center;
    case left;
    case right
    case stretch;
    
    var description : String
    {
        switch self
        {
            case .center:  return "Center";
            case .left:    return "Left";
            case .right:   return "Right";
            case .stretch: return "Stretch";
        }
    }
}

public enum VerticalAlignment
{
    case center;
    case top;
    case bottom;
    case stretch;
    
    var description : String
    {
        switch self
        {
            case .center:  return "Center";
            case .top:     return "Top";
            case .bottom:  return "Bottom";
            case .stretch: return "Stretch";
        }
    }
}

public enum Orientation
{
    case horizontal;
    case vertical;
    
    var description : String
    {
        switch self
        {
            case .horizontal: return "Horizontal";
            case .vertical:   return "Vertical";
        }
    }
}

public enum SizeSpec
{
    case wrapContent;
    case explicit;
    case fillParent;
    
    
    var description : String
    {
        switch self
        {
            case .wrapContent: return "WrapContent";
            case .explicit:    return "Explicit";
            case .fillParent:  return "FillParent";
        }
    }
}

open class FrameProperties
{
    open var widthSpec: SizeSpec = SizeSpec.wrapContent;
    open var heightSpec: SizeSpec = SizeSpec.wrapContent;
    
    open var starWidth: Int = 0;
    open var starHeight: Int = 0;
}

//
// Font stuff...
//

public enum FontSlope
{
    case roman;    // Also Regular, Plain - standard upright font
    case italic;   // Italic font
    case oblique;  // Also Incline, Inclined - Slanted version of Roman glyphs
    case cursive;  // Also Kursiv - Italic with cursive glyph connections
    
    var description : String
    {
        switch self
        {
            case .roman:   return "Roman";
            case .italic:  return "Italic";
            case .oblique: return "Oblique";
            case .cursive: return "Cursive";
        }
    }
}

public enum FontWidth
{
    case normal;
    case narrow;   // Compressed, Condensed, Narrow
    case wide;     // Wide, Extended, Expanded
    
    var description : String
    {
        switch self
        {
            case .normal: return "Normal";
            case .narrow: return "Narrow";
            case .wide:   return "Wide";
        }
    }
}

public enum FontWeight: UInt
{
    case extraLight = 100; // ExtraLight or UltraLight
    case light      = 200; // Light or Thin
    case book       = 300; // Book or Demi
    case normal     = 400; // Normal or Regular
    case medium     = 500; // Medium
    case semibold   = 600; // Semibold, Demibold
    case bold       = 700; // Bold
    case black      = 800; // Black, ExtraBold or Heavy
    case extraBlack = 900; // ExtraBlack, Fat, Poster or UltraBlack
    
    var description : String
    {
        switch self
        {
            case .extraLight: return "ExtraLight";
            case .light:      return "Light";
            case .book:       return "Bool";
            case .normal:     return "Normal";
            case .medium:     return "Medium";
            case .semibold:   return "Semibold";
            case .bold:       return "Bold";
            case .black:      return "Black";
            case .extraBlack: return "ExtraBlack";
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

open class FontMetrics
{
    var _faceName: String;
    
    var _slope = FontSlope.roman;
    var _width = FontWidth.normal;
    var _weight = FontWeight.normal;
    
    // The function of this class is to parse the font properties (slope/weight/width) from the font names, as
    // that's really the only indication that iOS gives us about the font metrics.
    //
    public init(faceName: String)
    {
        _faceName = faceName;
    
        if (_slope_italic.isMatch(_faceName))
        {
            _slope = FontSlope.italic;
        }
        else if (_slope_oblique.isMatch(_faceName))
        {
            _slope = FontSlope.oblique;
        }
        else if (_slope_cursive.isMatch(_faceName))
        {
            _slope = FontSlope.cursive;
        }
        
        if (_width_narrow.isMatch(_faceName))
        {
            _width = FontWidth.narrow;
        }
        else if (_width_wide.isMatch(_faceName))
        {
            _width = FontWidth.wide;
        }
        
        // The ordering below might look a little strange, but it is important.  We have to be careful not to match Light, Bold, Black,
        // or Demi in other stlyes (UltraLight, SemiBold, UltraBlack, etc), so we have to search for the longer terms first.
        //
        if (_weight_100.isMatch(_faceName))
        {
            _weight = FontWeight.extraLight;
        }
        else if (_weight_400.isMatch(_faceName))
        {
            _weight = FontWeight.normal;
        }
        else if (_weight_500.isMatch(_faceName))
        {
            _weight = FontWeight.medium;
        }
        else if (_weight_900.isMatch(_faceName))
        {
            _weight = FontWeight.extraBlack;
        }
        else if (_weight_800.isMatch(_faceName))
        {
            _weight = FontWeight.black;
        }
        else if (_weight_600.isMatch(_faceName))
        {
            _weight = FontWeight.semibold;
        }
        else if (_weight_700.isMatch(_faceName))
        {
            _weight = FontWeight.bold;
        }
        else if (_weight_200.isMatch(_faceName))
        {
            _weight = FontWeight.light;
        }
        else if (_weight_300.isMatch(_faceName))
        {
            _weight = FontWeight.book;
        }
    }
    
    open var name: String { get { return _faceName; } }
    open var slope: FontSlope { get { return _slope; } }
    open var width: FontWidth { get { return _width; } }
    open var weight: FontWeight { get { return _weight; } }
    
    // The math here works more or less as follows.  For each of the three criteria, a value of 1.0 is
    // given for a perfect match, a value of 0.8 is given for a "close" match, and a value of 0.5 is given
    // for a poor (typically opposite) match.  For font weight a sliding scale is used, but it more or less
    // matches up to the fixed scale values in the other metrics.  The overall match quality returned is the
    // product of these values.  A perfect match is 1.0, and the worst possible match is 0.125.  Importantly,
    // a font that matches perfectly on two criteria, but opposite on the third, will score a 0.5, whereas a
    // font that is a close match (but not perfect) on all three criteria will score a 0.512 (it is considered
    // a better match).
    //
    open func matchQuality(_ slope: FontSlope, weight: FontWeight, width: FontWidth) -> Float
    {
        var matchQuality: Float = 1;
        
        if (slope != _slope)
        {
            if ((slope != FontSlope.roman) && (_slope != FontSlope.roman))
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
            if ((width == FontWidth.normal) || (_width == FontWidth.normal))
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
            let weightDifference = Float(abs(Int(weight.rawValue) - Int(_weight.rawValue)));
            // Max weight difference is 800 - We want to scale match from 1.0 (exact match) to 0.5 (opposite, or 800 difference)
            matchQuality *= (1.0 - (weightDifference / 1600));
        }

        return matchQuality;
    }

    open func description() -> String
    {
        return "FontMetrics - Face: \(_faceName), Weight: \(_weight), Slope: \(_slope), Width: \(_width)";
    }
}

protocol FontFamily
{
    func createFont(_ bold: Bool, italic: Bool, size: CGFloat) -> UIFont?;
}

open class FontFamilyFromName : FontFamily
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
        let fontNames: Array = UIFont.fontNames(forFamilyName: _familyName);
        for (_, value) in fontNames.enumerated()
        {
            fonts.append(FontMetrics(faceName: value));
        }
        
        _plainFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.roman, weight: FontWeight.normal, width: FontWidth.normal)!;
        _boldFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.roman, weight: FontWeight.bold, width: FontWidth.normal)!;
        _italicFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.italic, weight: FontWeight.normal, width: FontWidth.normal)!;
        _boldItalicFont = FontFamilyFromName.getBestMatch(fonts, slope: FontSlope.italic, weight: FontWeight.bold, width: FontWidth.normal)!;
    }
    
    class func getBestMatch(_ fonts: [FontMetrics], slope: FontSlope, weight: FontWeight, width: FontWidth) -> FontMetrics?
    {
        var bestMatch: FontMetrics? = nil;
        var bestMatchScore: Float = -1;
        
        for fontMetrics in fonts
        {
            let matchScore = fontMetrics.matchQuality(slope, weight: weight, width: width);
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
    
    open func createFont(_ bold: Bool, italic: Bool, size: CGFloat) -> UIFont?
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

open class SystemFontFamily : FontFamily
{
    public init()
    {
    }
    
    open class func isSystemFont(_ font: UIFont) -> Bool
    {
        let currSize = font.pointSize;
        
        let systemFont = UIFont.systemFont(ofSize: currSize);
        let systemBoldFont = UIFont.boldSystemFont(ofSize: currSize);
        let systemItalicFont = UIFont.italicSystemFont(ofSize: currSize);
        
        return ((font == systemFont) || (font == systemBoldFont) || (font == systemItalicFont));
    }
    
    open func createFont(_ bold: Bool, italic: Bool, size: CGFloat) -> UIFont?
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
            let boldFont = UIFont.boldSystemFont(ofSize: size);
            let boldItalicFont = UIFont(name: boldFont.fontName + "Italic", size: size);
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
            return UIFont.boldSystemFont(ofSize: size);
        }
        else if (italic)
        {
            return UIFont.italicSystemFont(ofSize: size);
        }
        else
        {
            return UIFont.systemFont(ofSize: size);
        }
    }
}

open class iOSFontSetter : FontSetter
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
    
    open func setFont(_ font: UIFont)
    {
        // abstract
        fatalError("Must override");
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
    
    open func setFaceType(_ faceType: FontFaceType)
    {
        // See this for list of iOS fonts by version: http://iosfonts.com/
        //
        // If the face type is set, then we will create a font family to use.  Otherwise, we'll fall back to
        // the family created in the constructor (based on the initial/existing font).
        //
        switch (faceType)
        {
            case FontFaceType.font_DEFAULT:
                _family = SystemFontFamily();
            case FontFaceType.font_SANSERIF:
                _family = FontFamilyFromName(familyName: "Helvetica Neue");
            case FontFaceType.font_SERIF:
                _family = FontFamilyFromName(familyName: "Times New Roman");
            case FontFaceType.font_MONOSPACE:
                _family = FontFamilyFromName(familyName: "Courier New");
        }
        
        self.createAndSetFont();
    }
    
    open func setSize(_ size: Double)
    {
        _size = CGFloat(size);
        self.createAndSetFont();
    }
    
    open func setBold(_ bold: Bool)
    {
        _bold = bold;
        self.createAndSetFont();
    }
    
    open func setItalic(_ italic: Bool)
    {
        _italic = italic;
        self.createAndSetFont();
    }
}

public protocol ThicknessSetter
{
    func setThicknessLeft(_ thickness: Double);
    func setThicknessTop(_ thickness: Double);
    func setThicknessRight(_ thickness: Double);
    func setThicknessBottom(_ thickness: Double);
}

open class MarginThicknessSetter : ThicknessSetter
{
    var _controlWrapper: iOSControlWrapper;

    public init(controlWrapper: iOSControlWrapper)
    {
        _controlWrapper = controlWrapper;
    }

    open func setThicknessLeft(_ thickness: Double)
    {
        _controlWrapper.marginLeft = thickness;
    }
    
    open func setThicknessTop(_ thickness: Double)
    {
        _controlWrapper.marginTop = thickness;
    }
    
    open func setThicknessRight(_ thickness: Double)
    {
        _controlWrapper.marginRight = thickness;
    }
    
    open func setThicknessBottom(_ thickness: Double)
    {
        _controlWrapper.marginBottom = thickness;
    }
}

open class iOSControlWrapper : ControlWrapper
{
    var _control: UIView?;
    open var control: UIView? { get { return _control; } }
    
    open var DEFAULT_MARGIN: Double { get { return 5; } }
    
    var _pageView: iOSPageView;
    open var pageView: iOSPageView { get { return _pageView; } }

    var _margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0);

    open var frameProperties = FrameProperties();

    // !!! Allow black/white and/or size to be specified
    //
    open class func getResourceNameFromIcon(_ icon: String) -> String
    {
        // Backward compat for Civics - convert the old ic_ icons to the new names...
        if (icon == "star-mini")
        {
            return "ic_star";
        }
        else if (icon == "star-empty-mini")
        {
            return "ic_star_border";
        }
        else if (icon.hasPrefix("ic_"))
        {
            // The user knows *exactly* what they want, so give it to them...
            return icon;
        }
        return "ic_" + icon; // <-- Allow black/white and/or size to be specified, if prefixed with "ic_", leave alone.
    }

    open class func loadImageFromIcon(_ icon: String) -> UIImage
    {
        let iconResourceName = iOSControlWrapper.getResourceNameFromIcon(icon);
        var img = UIImage(named: iOSControlWrapper.getResourceNameFromIcon(iconResourceName));
        if (img == nil)
        {
            // If specified icon not found, default icon is do_not_disturb
            logger.warn("Button icon not found: \(iconResourceName), using default");
            img = UIImage(named: iOSControlWrapper.getResourceNameFromIcon("do_not_disturb"));
        }
        
        return img!;
    }
    
    var _horizontalAlignment = HorizontalAlignment.left;
    open var horizontalAlignment: HorizontalAlignment
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
    
    var _verticalAlignment = VerticalAlignment.top;
    open var verticalAlignment: VerticalAlignment
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
    
    open var margin: UIEdgeInsets
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
    
    open var marginLeft: Double
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
    
    open var marginTop: Double
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
    
    open var marginRight: Double
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
    
    open var marginBottom: Double
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
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec: JObject)
    {
        _pageView = (parent as! iOSControlWrapper).pageView;
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
    }
    
    open func toOrientation(_ value: JToken?, defaultOrientation: Orientation = Orientation.horizontal) -> Orientation
    {
        var orientation = defaultOrientation;
        let orientationValue = value?.asString();
        if (orientationValue == "Horizontal")
        {
            orientation = Orientation.horizontal;
        }
        else if (orientationValue == "Vertical")
        {
            orientation = Orientation.vertical;
        }
        return orientation;
    }
    
    open func toHorizontalAlignment(_ value: JToken?, defaultAlignment: HorizontalAlignment = HorizontalAlignment.left) -> HorizontalAlignment
    {
        var alignment = defaultAlignment;
        let alignmentValue = value?.asString();
        if (alignmentValue == "Left")
        {
            alignment = HorizontalAlignment.left;
        }
        if (alignmentValue == "Right")
        {
            alignment = HorizontalAlignment.right;
        }
        else if (alignmentValue == "Center")
        {
            alignment = HorizontalAlignment.center;
        }
        return alignment;
    }
    
    open func toVerticalAlignment(_ value: JToken?, defaultAlignment: VerticalAlignment = VerticalAlignment.top) -> VerticalAlignment
    {
        var alignment = defaultAlignment;
        let alignmentValue = value?.asString();
        if (alignmentValue == "Top")
        {
            alignment = VerticalAlignment.top;
        }
        if (alignmentValue == "Bottom")
        {
            alignment = VerticalAlignment.bottom;
        }
        else if (alignmentValue == "Center")
        {
            alignment = VerticalAlignment.center;
        }
        return alignment;
    }
    
    func toColor(_ value: JToken?) -> UIColor?
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
        
    open func processThicknessProperty(_ controlSpec: JObject, attributeName: String, thicknessSetter: ThicknessSetter)
    {
        processElementProperty(controlSpec, attributeName: attributeName + ".left", altAttributeName: attributeName,
        setValue: { (value) in
            if let theValue = value
            {
                thicknessSetter.setThicknessLeft(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: attributeName + ".top", altAttributeName: attributeName,
        setValue: { (value) in
            if let theValue = value
            {
                thicknessSetter.setThicknessTop(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: attributeName + ".right", altAttributeName: attributeName,
        setValue: { (value) in
            if let theValue = value
            {
                thicknessSetter.setThicknessRight(self.toDeviceUnits(theValue));
            }
        });
        processElementProperty(controlSpec, attributeName: attributeName + ".bottom", altAttributeName: attributeName,
        setValue: { (value) in
            if let theValue = value
            {
                thicknessSetter.setThicknessBottom(self.toDeviceUnits(theValue));
            }
        });
    }
    
    func applyFrameworkElementDefaults(_ element: UIView, applyMargins: Bool = true)
    {
        if (applyMargins)
        {
            self.marginLeft = toDeviceUnits(self.DEFAULT_MARGIN);
            self.marginTop = toDeviceUnits(self.DEFAULT_MARGIN);
            self.marginRight = toDeviceUnits(self.DEFAULT_MARGIN);
            self.marginBottom = toDeviceUnits(self.DEFAULT_MARGIN);
        }
    }
    
    func sizeThatFits(_ size: CGSize) -> CGSize
    {
        var sizeThatFits = CGSize(width: size.width, height: size.height); // Default to size given ("fill parent")

        if let control = _control
        {
            if ((self.frameProperties.heightSpec == SizeSpec.wrapContent) && (self.frameProperties.widthSpec == SizeSpec.wrapContent))
            {
                // If both dimensions are WrapContent, then we want to make the control as small as possible in both dimensions, without
                // respect to how big the client would like to make it.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: 0, height: 0)); // Compute height and width
            }
            else if (self.frameProperties.heightSpec == SizeSpec.wrapContent)
            {
                // If only the height is WrapContent, then we obey the current width and attempt to compute the height.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: control.frame.size.width, height: 0)); // Compute height
                sizeThatFits.width = control.frame.size.width; // Maintain width
            }
            else if (self.frameProperties.widthSpec == SizeSpec.wrapContent)
            {
                // If only the width is WrapContent, then we obey the current hiights and attempt to compute the width.
                //
                sizeThatFits = control.sizeThatFits(CGSize(width: 0, height: control.frame.size.height)); // Compute width
                sizeThatFits.height = control.frame.height; // Maintain height
            }
            else // No content wrapping in either dimension...
            {
                if (self.frameProperties.heightSpec != SizeSpec.fillParent)
                {
                    sizeThatFits.height = control.frame.height;
                }
                if (self.frameProperties.widthSpec != SizeSpec.fillParent)
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
            let size = self.sizeThatFits(CGSize(width: 0, height: 0));
            var frame = control.frame;
            frame.size = size;
            control.frame = frame;
        }
    }
    
    func processElementDimensions(_ controlSpec: JObject, defaultWidth: Double = 0, defaultHeight: Double = 0) -> FrameProperties
    {
        var defaultWidth = CGFloat(defaultWidth);
        var defaultHeight = CGFloat(defaultHeight);
        
        if let control = self.control
        {
            if (defaultWidth == 0)
            {
                defaultWidth = control.intrinsicContentSize.width;
                if (defaultWidth == -1)
                {
                    defaultWidth = 0;
                }
            }
            if (defaultHeight == 0)
            {
                defaultHeight = control.intrinsicContentSize.height;
                if (defaultHeight == -1)
                {
                    defaultHeight = 0;
                }
            }
        
            control.frame = CGRect(x: 0, y: 0, width: defaultWidth, height: defaultHeight);
            
            processElementProperty(controlSpec, attributeName: "height",
            setValue: { (value) in
                if let theValue = value
                {
                    let heightStarCount = ControlWrapper.getStarCount(theValue.asString());
                    if (heightStarCount > 0)
                    {
                        self.frameProperties.heightSpec = SizeSpec.fillParent;
                        self.frameProperties.starHeight = heightStarCount;
                    }
                    else
                    {
                        self.frameProperties.heightSpec = SizeSpec.explicit;

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
                }
            });

            processElementProperty(controlSpec, attributeName: "width",
            setValue: { (value) in
                if let theValue = value
                {
                    let widthStarCount = ControlWrapper.getStarCount(theValue.asString());
                    if (widthStarCount > 0)
                    {
                        self.frameProperties.widthSpec = SizeSpec.fillParent;
                        self.frameProperties.starWidth = widthStarCount;
                    }
                    else
                    {
                        self.frameProperties.widthSpec = SizeSpec.explicit;
                        
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
                }
            });
        }
        
        return self.frameProperties;
    }
    
    func processCommonFrameworkElementProperies(_ controlSpec: JObject)
    {
        logger.debug("Processing framework element properties");
    
        // !!! This could be a little more thourough ;)
        //
        // name, minHeight, minWidth, maxHeight, maxWidth -- when/if supported
        //
        
        processElementProperty(controlSpec, attributeName: "horizontalAlignment", setValue: { (value) in self.horizontalAlignment = self.toHorizontalAlignment(value) });
        processElementProperty(controlSpec, attributeName: "verticalAlignment", setValue: { (value) in self.verticalAlignment = self.toVerticalAlignment(value) });
        
        processElementProperty(controlSpec, attributeName: "opacity", setValue: { (value) in self.control!.layer.opacity = Float(self.toDouble(value)) });
        
        processElementProperty(controlSpec, attributeName: "background", setValue: { (value) in self.control!.backgroundColor = self.toColor(value) });
        processElementProperty(controlSpec, attributeName: "visibility",
        setValue: { (value) in
            self.control!.isHidden = !self.toBoolean(value);
            if (self.control?.superview != nil)
            {
                self.control!.superview!.setNeedsLayout();
            }
        });
        
        if let uiControl = self.control as? UIControl
        {
            processElementProperty(controlSpec, attributeName: "enabled", setValue: { (value) in uiControl.isEnabled = self.toBoolean(value) });
        }
        else
        {
            processElementProperty(controlSpec, attributeName: "enabled", setValue: { (value) in self.control!.isUserInteractionEnabled = self.toBoolean(value) });
        }
        
        processThicknessProperty(controlSpec, attributeName: "margin", thicknessSetter: MarginThicknessSetter(controlWrapper: self));
    }
    
    open func getChildControlWrapper(_ control: UIView) -> iOSControlWrapper?
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
    
    open class func wrapControl(_ pageView: iOSPageView, stateManager: StateManager, viewModel: ViewModel, bindingContext: BindingContext, control: UIView) -> iOSControlWrapper
    {
        return iOSControlWrapper(pageView: pageView, stateManager: stateManager, viewModel: viewModel, bindingContext: bindingContext, control: control);
    }
    
    open class func createControl(_ parent: ControlWrapper, bindingContext: BindingContext, controlSpec: JObject) -> iOSControlWrapper?
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
                case "togglebutton":
                    controlWrapper = iOSToggleButtonWrapper(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
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
    
    open func createControls(controlList: JArray, onCreateControl: ((JObject, iOSControlWrapper) -> (Void))? = nil)
    {
        super.createControls(self.bindingContext, controlList: controlList,
        onCreateControl: { (controlContext, controlSpec) in
            let controlWrapper = iOSControlWrapper.createControl(self, bindingContext: controlContext, controlSpec: controlSpec);
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


