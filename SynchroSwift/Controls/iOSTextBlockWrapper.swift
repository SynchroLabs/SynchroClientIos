//
//  iOSTextBlockWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSTextBlockWrapper");

class ResizableLabel : UILabel
{
    var _frameProperties: FrameProperties;
    var _lastComputedSize: CGSize;
    
    internal init(frameProperties: FrameProperties)
    {
        _frameProperties = frameProperties;
        _lastComputedSize = CGSize(width: 0, height: 0);
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: _lastComputedSize));
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented");
    }
    
    internal override var text: String?
        {
        get
        {
            return super.text;
        }
        set(value)
        {
            super.text = value;
            self.updateSize();
        }
    }
    
    func updateComputedSize(size: CGSize)
    {
        _lastComputedSize.width = size.width;
        _lastComputedSize.height = size.height;
        
        var frame = self.frame;
        frame.size = size;
        self.frame = frame;
    }
    
    internal override func layoutSubviews()
    {
        super.layoutSubviews();
        
        if ((self.frame.size.width != _lastComputedSize.width) || (self.frame.size.height != _lastComputedSize.height))
        {
            // Util.debug("Resizable label - layoutSubviews() - new size - h: " + this.Frame.Size.Height + ", w: " + this.Frame.Size.Width);
            //
            self.updateSize();
        }
    }
    
    internal func updateSize()
    {
        if ((_frameProperties.heightSpec == SizeSpec.WrapContent) && (_frameProperties.widthSpec == SizeSpec.WrapContent))
        {
            // If both dimensions are WrapContent, then we don't care what the current dimensions are, we just sizeToFit (note
            // that this will not do any line wrapping and will consume the width of the string as a single line).
            //
            self.numberOfLines = 1;
            var size = self.sizeThatFits(CGSize(width: 0, height: 0)); // Compute height and width
            self.updateComputedSize(size);
        }
        else if (_frameProperties.heightSpec == SizeSpec.WrapContent)
        {
            // If only the height is WrapContent, then we obey the current width and set the height based on how tall the text would
            // be when wrapped at the current width.
            //
            var size = self.sizeThatFits(CGSize(width: self.frame.size.width, height: 0)); // Compute height
            size.width = self.frame.size.width; // Maintain width
            self.updateComputedSize(size);
        }
        else if (_frameProperties.widthSpec == SizeSpec.WrapContent)
        {
            // If only the width is WrapContent then we'll get the maximum width assuming the text is on a single line and we'll
            // set the width to that and leave the height alone (kind of a non-sensical case).
            //
            var size = self.sizeThatFits(CGSize(width: 0, height: 0)); // Compute width
            size.height = self.frame.height; // Maintain height
            self.updateComputedSize(size);
        }
    }
}

class TextBlockFontSetter : iOSFontSetter
{
    var _label: ResizableLabel;
    
    internal init(label: ResizableLabel)
    {
        _label = label;
        super.init(font: label.font);
    }
    
    internal override func setFont(font: UIFont)
    {
        _label.font = font;
        _label.updateSize();
    }
}

public class iOSTextBlockWrapper : iOSControlWrapper
{
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating textblock element");
        super.init(parent: parent, bindingContext: bindingContext);

        var textBlock = ResizableLabel(frameProperties: self.frameProperties);
        textBlock.numberOfLines = 0;
        textBlock.lineBreakMode = NSLineBreakMode.ByWordWrapping;
        
        self._control = textBlock;
        
        processElementDimensions(controlSpec, defaultWidth: 0, defaultHeight: 0);
        applyFrameworkElementDefaults(textBlock);
        
        processElementProperty(controlSpec["foreground"], { (value) in
            textBlock.textColor = self.toColor(value)?;
        });
        
        processFontAttribute(controlSpec, fontSetter: TextBlockFontSetter(label: textBlock));
        
        processElementProperty(controlSpec["value"], { (value) in
            textBlock.text = self.toString(value);
        });
        
        processElementProperty(controlSpec["ellipsize"], { (value) in
            // Other trimming options:
            //
            //   UILineBreakMode.HeadTruncation;
            //   UILineBreakMode.MiddleTruncation;
            //
            var bEllipsize = self.toBoolean(value);
            if (bEllipsize)
            {
                textBlock.lineBreakMode = NSLineBreakMode.ByTruncatingTail;
            }
            else
            {
                textBlock.lineBreakMode = NSLineBreakMode.ByWordWrapping;
            }
        });
        
        processElementProperty(controlSpec["textAlignment"],{ (value) in
            var alignString = self.toString(value);
            if (alignString == "Left")
            {
                textBlock.textAlignment = NSTextAlignment.Left;
            }
            if (alignString == "Center")
            {
                textBlock.textAlignment = NSTextAlignment.Center;
            }
            else if (alignString == "Right")
            {
                textBlock.textAlignment = NSTextAlignment.Right;
            }
        });
    }
}
